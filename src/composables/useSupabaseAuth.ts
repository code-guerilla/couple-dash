import { computed, readonly, ref } from 'vue'
import { isSupabaseConfigured, supabase } from '@/services/supabase'

const initialized = ref(false)
const loading = ref(false)
const error = ref<string | null>(null)
const userId = ref<string | null>(null)

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
  initialized.value = true
}

if (supabase) {
  void refreshSession()
  supabase.auth.onAuthStateChange((_event, session) => {
    userId.value = session?.user.id ?? null
    initialized.value = true
  })
}

export function useSupabaseAuth() {
  const isAuthenticated = computed(() => !isSupabaseConfigured || Boolean(userId.value))

  async function signIn(email: string, password: string) {
    if (!supabase) {
      return
    }

    loading.value = true
    error.value = null
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password })
    loading.value = false

    if (signInError) {
      error.value = signInError.message
      throw signInError
    }
  }

  async function signUp(email: string, password: string) {
    if (!supabase) {
      return
    }

    loading.value = true
    error.value = null
    const { error: signUpError } = await supabase.auth.signUp({ email, password })
    loading.value = false

    if (signUpError) {
      error.value = signUpError.message
      throw signUpError
    }
  }

  async function signOut() {
    if (!supabase) {
      return
    }

    await supabase.auth.signOut()
  }

  async function ensureAnonymousSession() {
    if (!supabase) {
      return
    }

    await refreshSession()

    if (userId.value) {
      return
    }

    loading.value = true
    error.value = null
    const { error: anonymousError } = await supabase.auth.signInAnonymously()
    loading.value = false

    if (anonymousError) {
      error.value = anonymousError.message
      throw anonymousError
    }
  }

  return {
    initialized: readonly(initialized),
    loading: readonly(loading),
    error: readonly(error),
    userId: readonly(userId),
    isAuthenticated,
    isSupabaseConfigured,
    refreshSession,
    signIn,
    signUp,
    signOut,
    ensureAnonymousSession,
  }
}
