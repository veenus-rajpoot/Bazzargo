import { useEffect, useState } from 'react'
import Layout from '../components/Layout'
import Container from '../components/Container'
import PageHero from '../components/PageHero'
import ConfirmDialog from '../components/ConfirmDialog'
import { supabase } from '../lib/supabase'
import { requestAccountDeletion } from '../lib/deleteAccount'
import {
  Loader2,
  LogOut,
  ShieldAlert,
  CheckCircle2,
  AlertCircle,
} from 'lucide-react'

// Simple inline Google "G" mark so we don't need an extra icon dependency.
function GoogleIcon(props) {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" {...props}>
      <path
        fill="#4285F4"
        d="M23.5 12.3c0-.85-.08-1.66-.22-2.45H12v4.64h6.47c-.28 1.5-1.13 2.77-2.4 3.62v3h3.88c2.27-2.09 3.55-5.17 3.55-8.81Z"
      />
      <path
        fill="#34A853"
        d="M12 24c3.24 0 5.96-1.07 7.95-2.9l-3.88-3c-1.08.72-2.46 1.15-4.07 1.15-3.13 0-5.78-2.11-6.73-4.95H1.26v3.1A12 12 0 0 0 12 24Z"
      />
      <path
        fill="#FBBC05"
        d="M5.27 14.3a7.2 7.2 0 0 1 0-4.6v-3.1H1.26a12 12 0 0 0 0 10.8l4.01-3.1Z"
      />
      <path
        fill="#EA4335"
        d="M12 4.75c1.76 0 3.34.6 4.59 1.79l3.44-3.44C17.95 1.19 15.24 0 12 0A12 12 0 0 0 1.26 6.6l4.01 3.1C6.22 6.86 8.87 4.75 12 4.75Z"
      />
    </svg>
  )
}

export default function DeleteAccount() {
  const [session, setSession] = useState(undefined) // undefined = loading, null = signed out
  const [authLoading, setAuthLoading] = useState(false)
  const [authError, setAuthError] = useState('')

  const [confirmOpen, setConfirmOpen] = useState(false)
  const [deleteLoading, setDeleteLoading] = useState(false)
  const [deleteError, setDeleteError] = useState('')
  const [deleted, setDeleted] = useState(false)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session))
    const { data: listener } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s)
    })
    return () => listener?.subscription?.unsubscribe()
  }, [])

  async function handleGoogleSignIn() {
    setAuthError('')
    setAuthLoading(true)
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/delete-account`,
        },
      })
      if (error) throw error
    } catch (err) {
      setAuthError(err.message || 'Google sign-in failed. Please try again.')
      setAuthLoading(false)
    }
  }

  async function handleSignOut() {
    await supabase.auth.signOut()
  }

  function handleDeleteClick() {
    setDeleteError('')
    setConfirmOpen(true)
  }

  async function confirmDelete() {
    setDeleteLoading(true)
    setDeleteError('')
    try {
      await requestAccountDeletion()
      setConfirmOpen(false)
      setDeleted(true)
      await supabase.auth.signOut()
    } catch (err) {
      setDeleteError(
        err.message || 'We could not delete your account. Please try again.'
      )
      setConfirmOpen(false)
    } finally {
      setDeleteLoading(false)
    }
  }

  return (
    <Layout>
      <PageHero
        eyebrow="Account Deletion"
        title="Delete Your BazzarGo Account"
        subtitle="Submitting this request will permanently delete your BazzarGo account and all associated data, including your delivery history, saved addresses, and KYC records. This action is irreversible."
      />

      <section className="py-16 md:py-20">
        <Container className="max-w-xl">
          {session === undefined && (
            <div className="flex items-center justify-center gap-2 rounded-2xl border border-navy-100 p-10 text-navy-400">
              <Loader2 size={18} className="animate-spin" /> Checking your
              session…
            </div>
          )}

          {deleted && (
            <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-8 text-center">
              <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-emerald-100 text-emerald-600">
                <CheckCircle2 size={24} />
              </div>
              <h3 className="mt-5 text-[18px] font-bold text-navy-900">
                Deletion request submitted
              </h3>
              <p className="mt-2 text-[14.5px] leading-relaxed text-navy-500">
                You've been signed out and your account has been queued for
                permanent deletion.
              </p>
            </div>
          )}

          {session === null && !deleted && (
            <div className="rounded-2xl border border-navy-100 p-7 text-center shadow-card sm:p-9">
              <div className="mx-auto grid h-12 w-12 place-items-center rounded-xl bg-brand-50 text-brand-600">
                <GoogleIcon />
              </div>
              <h2 className="mt-5 text-[17px] font-bold text-navy-900">
                Sign in to continue
              </h2>
              <p className="mt-1.5 text-[14px] text-navy-400">
                For your security, sign in with the same Google account you
                use for BazzarGo before requesting deletion.
              </p>

              <button
                type="button"
                onClick={handleGoogleSignIn}
                disabled={authLoading}
                className="mt-6 flex w-full items-center justify-center gap-3 rounded-full border border-navy-100 bg-white px-6 py-3.5 text-[15px] font-semibold text-navy-800 shadow-sm transition-colors hover:bg-navy-50 disabled:opacity-60"
              >
                {authLoading ? (
                  <Loader2 size={18} className="animate-spin" />
                ) : (
                  <GoogleIcon />
                )}
                {authLoading ? 'Redirecting to Google…' : 'Sign in with Google'}
              </button>

              {authError && (
                <p className="mt-4 flex items-start gap-2 text-left text-[13.5px] text-red-600">
                  <AlertCircle size={15} className="mt-0.5 shrink-0" />
                  {authError}
                </p>
              )}
            </div>
          )}

          {session && !deleted && (
            <div className="rounded-2xl border border-navy-100 p-7 shadow-card sm:p-9">
              <div className="mb-6 flex items-center justify-between gap-4 rounded-xl bg-navy-50 px-4 py-3">
                <p className="text-[13.5px] text-navy-500">
                  Signed in as{' '}
                  <span className="font-semibold text-navy-900">
                    {session.user.email}
                  </span>
                </p>
                <button
                  onClick={handleSignOut}
                  className="flex items-center gap-1.5 text-[13px] font-semibold text-navy-400 hover:text-brand-600"
                >
                  <LogOut size={14} /> Sign out
                </button>
              </div>

              <div className="mb-8 flex items-start gap-3 rounded-xl border border-amber-100 bg-amber-50 p-4">
                <ShieldAlert size={18} className="mt-0.5 shrink-0 text-amber-600" />
                <p className="text-[13.5px] leading-relaxed text-amber-800">
                  This will permanently delete your BazzarGo account and all
                  associated data, including delivery history, saved
                  addresses, and KYC records. This action cannot be undone.
                </p>
              </div>

              {deleteError && (
                <p className="mb-4 flex items-start gap-2 text-[13.5px] text-red-600">
                  <AlertCircle size={15} className="mt-0.5 shrink-0" />
                  {deleteError}
                </p>
              )}

              <button
                type="button"
                onClick={handleDeleteClick}
                className="w-full rounded-full bg-red-600 px-6 py-3.5 text-[15px] font-semibold text-white transition-colors hover:bg-red-700"
              >
                Delete Account
              </button>
            </div>
          )}
        </Container>
      </section>

      <ConfirmDialog
        open={confirmOpen}
        danger
        title="Permanently delete your account?"
        description="This will permanently delete your BazzarGo account, delivery history, saved addresses, and KYC records. This cannot be undone."
        confirmLabel="Yes, delete my account"
        cancelLabel="Keep my account"
        loading={deleteLoading}
        onConfirm={confirmDelete}
        onCancel={() => setConfirmOpen(false)}
      />
    </Layout>
  )
}