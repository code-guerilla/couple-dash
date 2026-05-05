import { computed, readonly, ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/services/supabase'

const initialized = ref(false)
const loading = ref(false)
const error = ref<string | null>(null)
const userId = ref<string | null>(null)
const userEmail = ref<string | null>(null)

async function refreshSession() {
  if (!supabase) {
    initialized.value = true
    return
  }

  const { data, error: sessionError } = await supabase.auth.getSession()

  if (sessionError) {
    error.value = sessionError.message
  }

  userId.value = data.session?.user.id ?? null
  userEmail.value = data.session?.user.email ?? null
  initialized.value = true
}

void refreshSession()

if (supabase) {
  supabase.auth.onAuthStateChange((_event, session) => {
    userId.value = session?.user.id ?? null
    userEmail.value = session?.user.email ?? null
    initialized.value = true
  })
}

export function useSupabaseAuth() {
  const isAuthenticated = computed(() => Boolean(userId.value))

  async function signInWithGoogle(redirectTo = window.location.href) {
    if (!supabase) {
      return
    }

    loading.value = true
    error.value = null
    const { error: oauthError } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo,
      },
    })

    if (oauthError) {
      loading.value = false
      error.value = oauthError.message
      throw oauthError
    }
  }

  async function sendMagicLink(email: string, redirectTo = window.location.href) {
    if (!supabase) {
      return
    }

    loading.value = true
    error.value = null
    const { error: magicLinkError } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: redirectTo,
      },
    })
    loading.value = false

    if (magicLinkError) {
      error.value = magicLinkError.message
      throw magicLinkError
    }
  }

  async function signOut() {
    if (!supabase) {
      return
    }

    await supabase.auth.signOut()
  }

  return {
    initialized: readonly(initialized),
    loading: readonly(loading),
    error: readonly(error),
    userId: readonly(userId),
    userEmail: readonly(userEmail),
    isAuthenticated,
    isSupabaseConfigured,
    refreshSession,
    signInWithGoogle,
    sendMagicLink,
    signOut,
  }
}
