import { supabase } from './supabase'

/**
 * Calls the `delete-account` Supabase Edge Function on behalf of the
 * CURRENTLY AUTHENTICATED user only.
 *
 * Uses supabase-js's functions.invoke(), which automatically attaches the
 * signed-in user's access token and the project's publishable key in the
 * exact format the Edge Function's withSupabase({ auth: 'user' }) wrapper
 * expects — avoiding any mismatch from hand-built fetch headers.
 */
export async function requestAccountDeletion() {
  const { data: sessionData, error: sessionError } = await supabase.auth.getSession()

  if (sessionError) {
    throw new Error('We could not verify your session. Please sign in again and retry.')
  }

  if (!sessionData?.session) {
    throw new Error('You need to be signed in to request account deletion.')
  }

  const { data, error } = await supabase.functions.invoke('delete-account', {
    method: 'POST',
  })

  if (error) {
    // FunctionsHttpError has a `.context` (the Response) with the JSON body
    // our Edge Function returned — surface its message if present.
    let message = error.message
    try {
      const body = await error.context?.json?.()
      if (body?.error) message = body.error
    } catch {
      // ignore parse failures, fall back to error.message
    }
    throw new Error(message || 'Account deletion failed. Please try again or contact support.')
  }

  if (data?.success === false) {
    throw new Error(data.error || 'Account deletion failed. Please try again or contact support.')
  }

  return data
}