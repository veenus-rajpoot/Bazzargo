# BazzarGo — Website Recreation

A React + Vite + Tailwind CSS recreation of the BazzarGo marketing site
(https://bazzargo.netlify.app), plus a secure, Supabase-authenticated
account deletion page at `/delete-account`.

## Stack

- React 19 + Vite
- Tailwind CSS v4
- react-router-dom
- lucide-react (icons)
- @supabase/supabase-js

## Project structure

```
src/
  components/       shared UI (Header, Footer, Button, Container, ...)
  components/home/  homepage sections (Hero, Features, HowItWorks, ...)
  pages/            route-level pages (Home, About, Contact, FAQ, ...,
                     DeleteAccount)
  lib/
    supabase.js       Supabase client (publishable key only)
    deleteAccount.js  calls the delete-account Edge Function securely
    faqData.js         shared FAQ content
```

## Setup

```bash
npm install
cp .env.example .env
```

Edit `.env` and set your Supabase **publishable (anon) key**:

```
VITE_SUPABASE_URL=https://cavjvejlywrvbkqiuugi.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=<your publishable/anon key>
```

> **Note on env var names:** Vite only exposes environment variables to the
> browser when they're prefixed with `VITE_`. Plain `SUPABASE_URL` /
> `SUPABASE_PUBLISHABLE_KEY` (as originally specified) will **not** reach
> client-side code in a Vite build, so this project uses
> `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` instead.

Then run:

```bash
npm run dev       # local dev server
npm run build     # production build -> dist/
npm run preview   # preview the production build
```

## Account deletion flow (`/delete-account`)

1. **Auth gate (Google Sign-In)** — the page checks for a live Supabase
   session (`supabase.auth.getSession()`). If the visitor isn't signed in,
   they see a single **"Sign in with Google"** button, which calls
   `supabase.auth.signInWithOAuth({ provider: 'google' })` and redirects
   back to `/delete-account` once Google sign-in completes. Nothing about
   deletion happens until a real Supabase session exists.

   > **Supabase setup required:** enable the **Google** provider under
   > Authentication → Providers in your Supabase project, and add
   > `https://<your-domain>/delete-account` (and your local dev URL, e.g.
   > `http://localhost:5173/delete-account`) to the allowed Redirect URLs.
2. **Deletion form** — once signed in, the visitor sees Full Name,
   Registered Phone Number, a read-only Registered Email (pulled from their
   authenticated session, not typed in), and Reason for Deletion — matching
   the reference site's fields. These fields are for support record-keeping
   only; they are **not** used to determine which account gets deleted.
3. **Confirmation dialog** — clicking "Request Account Deletion" opens a
   confirmation modal before anything irreversible happens.
4. **Edge Function call** — on confirmation, the app reads the current
   session's `access_token` and calls:

   ```
   POST https://cavjvejlywrvbkqiuugi.supabase.co/functions/v1/delete-account
   Authorization: Bearer <the signed-in user's access token>
   apikey: <VITE_SUPABASE_PUBLISHABLE_KEY>
   ```

   The Edge Function (already deployed on your Supabase project) resolves
   the authenticated user from that Bearer token and deletes **only that
   user's** account — the frontend never sends a user id, email, or phone
   number as a deletion target.
5. **On success** — the app signs the user out locally and shows a success
   message.
6. **On failure** — the account is left intact, a clear error is shown, and
   the visitor can retry.

### What this app deliberately does NOT do

- It never deletes an account just because a name/email/phone was typed
  into the form.
- It never puts a Supabase **service-role** or secret key in frontend code
  — only the publishable/anon key (`VITE_SUPABASE_PUBLISHABLE_KEY`) is used
  client-side, and only in the `apikey` header (never as the `Authorization`
  bearer value).
- It never lets the frontend supply a user id for the Edge Function to
  trust — deletion is scoped entirely by the caller's access token.

## Design notes

The reference site's HTML/content was inspected directly (page structure,
copy, section order, footer links, and the existing public `/delete-account`
form fields). Exact pixel measurements, colors, and fonts weren't
recoverable from a text-only fetch, so the visual system (color palette,
type pairing — Plus Jakarta Sans for display, Inter for body — spacing
scale, card/button styling) was reconstructed to match the same structure,
section order, and content, using a cohesive "community logistics" visual
language (warm orange brand color, deep navy, teal trust accent). Share
screenshots or the site's CSS to tighten colors, spacing, and type sizes to
match pixel-for-pixel.
# Bazzargo
