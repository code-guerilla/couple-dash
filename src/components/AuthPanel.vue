<script setup lang="ts">
import { ref } from 'vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'

const emit = defineEmits<{
  signedIn: []
}>()

const { loading, error, signIn, signUp } = useSupabaseAuth()
const email = ref('')
const password = ref('')
const mode = ref<'sign-in' | 'sign-up'>('sign-in')

async function submit() {
  if (mode.value === 'sign-in') {
    await signIn(email.value, password.value)
  } else {
    await signUp(email.value, password.value)
  }

  emit('signedIn')
}
</script>

<template>
  <UCard>
    <template #header>
      <div>
        <h2 class="text-xl font-black">{{ mode === 'sign-in' ? 'Sign in' : 'Create account' }}</h2>
        <p class="text-sm muted">Dashboard access uses Supabase Auth.</p>
      </div>
    </template>

    <form class="form-stack" @submit.prevent="submit">
      <UAlert v-if="error" color="error" variant="soft" :description="error" />

      <label class="field-stack">
        <span class="field-label">Email</span>
        <UInput v-model="email" autocomplete="email" required type="email" class="w-full" />
      </label>

      <label class="field-stack">
        <span class="field-label">Password</span>
        <UInput
          v-model="password"
          autocomplete="current-password"
          minlength="6"
          required
          type="password"
          class="w-full"
        />
      </label>

      <UButton :label="mode === 'sign-in' ? 'Sign in' : 'Create account'" :loading="loading" type="submit" />

      <UButton
        :label="mode === 'sign-in' ? 'Need an account?' : 'Already have an account?'"
        size="sm"
        variant="ghost"
        type="button"
        @click="mode = mode === 'sign-in' ? 'sign-up' : 'sign-in'"
      />
    </form>
  </UCard>
</template>
