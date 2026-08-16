import { createClient } from '@supabase/supabase-js'

// IMPORTANT: only the publishable (anon) key is ever used here.
// The service-role / secret key must NEVER be referenced in frontend code.
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabasePublishableKey) {
  // eslint-disable-next-line no-console
  console.warn(
    'Supabase env vars are missing. Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in your .env file.'
  )
}

export const supabase = createClient(supabaseUrl, supabasePublishableKey)

export const EDGE_FUNCTIONS_URL = `${supabaseUrl}/functions/v1`
