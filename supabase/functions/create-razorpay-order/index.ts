import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { amount, receipt } = await req.json();

    let keyId = Deno.env.get('RAZORPAY_KEY_ID') || '';
    let keySecret = Deno.env.get('RAZORPAY_SECRET') || Deno.env.get('RAZORPAY_KEY_SECRET') || '';

    // Strip any accidental whitespace or quotes that might have been copied
    keyId = keyId.trim().replace(/^["']|["']$/g, '');
    keySecret = keySecret.trim().replace(/^["']|["']$/g, '');

    console.log(`Starting Order Creation. Key ID starting with: ${keyId.substring(0, 8)}...`);

    if (!keyId || !keySecret) {
      console.error("Missing Razorpay credentials!");
      throw new Error("Razorpay credentials are not configured in edge function environment.");
    }

    const auth = btoa(`${keyId}:${keySecret}`);
    console.log(`Authorization header generated successfully.`);

    const requestBody = {
      amount: amount, 
      currency: "INR",
      receipt: receipt || `rcptid_${Date.now()}`
    };

    console.log(`Sending request to Razorpay:`, requestBody);

    const response = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${auth}`
      },
      body: JSON.stringify(requestBody)
    });

    const data = await response.json();
    console.log(`Razorpay Response Status: ${response.status}`);
    console.log(`Razorpay Response Data:`, data);

    if (!response.ok) {
      console.error("Razorpay Error Details:", data.error);
      throw new Error(data.error?.description || "Failed to create order");
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
})
