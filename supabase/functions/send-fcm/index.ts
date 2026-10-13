import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { JWT } from "npm:google-auth-library@9";
serve(async (req) => {
  try {
    const payload = await req.json();
    console.log("Webhook payload received:", payload);

    // Ensure we are processing an INSERT event (or handle testing pings)
    if (payload.type !== "INSERT" || !payload.record) {
      return new Response("Not an INSERT event or missing record. Skipping.", { status: 200 });
    }

    const notification = payload.record;
    const receiverId = notification.user_id; // the foreign key to profiles
    const title = notification.title;
    const message = notification.message;

    if (!receiverId) {
      console.log("No receiver user_id found in notification record.");
      return new Response("No receiver user_id", { status: 400 });
    }

    // Connect to Supabase
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch the receiver's FCM token
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", receiverId)
      .maybeSingle();

    if (profileError || !profile?.fcm_token) {
      console.log(`Failed to get fcm_token for user ${receiverId}:`, profileError?.message || "Token is null");
      // Return 200 so the webhook doesn't retry infinitely just because a user has no token
      return new Response("User does not have an FCM token", { status: 200 });
    }

    const fcmToken = profile.fcm_token;
    console.log(`Found FCM token for user ${receiverId}`);

    // Read Firebase service account from environment
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      console.error("FIREBASE_SERVICE_ACCOUNT is not set in Supabase secrets.");
      return new Response("Firebase configuration missing", { status: 500 });
    }

    const serviceAccount = JSON.parse(serviceAccountJson);

    // Generate Google OAuth access token
    console.log("Generating Google OAuth token...");
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const tokens = await jwtClient.authorize();
    const accessToken = tokens.access_token;

    if (!accessToken) {
      console.error("Failed to generate Google OAuth access token.");
      return new Response("Authentication failed", { status: 500 });
    }

    // Send the push notification via Firebase HTTP v1 API
    const projectId = "bazzargo-2416c";
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: title || "New Notification",
          body: message || "",
        },
        android: {
          priority: "high",
        },
      },
    };

    console.log("Sending FCM request to:", fcmUrl);
    const fcmResponse = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(fcmPayload),
    });

    const responseData = await fcmResponse.json();

    if (!fcmResponse.ok) {
      console.error("FCM API error:", responseData);
      return new Response(JSON.stringify({ error: "FCM send failed", details: responseData }), { status: 500 });
    }

    console.log("Successfully sent push notification:", responseData);
    return new Response(JSON.stringify({ success: true, messageId: responseData.name }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(JSON.stringify({ error: error.message || String(error) }), { status: 500 });
  }
});
