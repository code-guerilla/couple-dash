<script setup lang="ts">
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'

const props = defineProps<{
  redirectTo?: string
}>()

const { loading, error, signInWithApple, signInWithGoogle } = useSupabaseAuth()

async function signInGoogle() {
  await signInWithGoogle(props.redirectTo)
}

async function signInApple() {
  await signInWithApple(props.redirectTo)
}
</script>

<template>
  <UCard>
    <template #header>
      <div>
        <h2 class="text-xl font-black">Sign in</h2>
        <p class="text-sm text-muted">Use Google or Apple to open this private dashboard.</p>
      </div>
    </template>

    <div class="grid gap-3">
      <UAlert v-if="error" color="error" variant="soft" :description="error" />

      <UButton
        icon="i-simple-icons-google"
        label="Continue with Google"
        :loading="loading"
        type="button"
        @click="signInGoogle"
      />
      <UButton
        icon="i-simple-icons-apple"
        label="Continue with Apple"
        :loading="loading"
        color="neutral"
        type="button"
        @click="signInApple"
      />
    </div>
  </UCard>
</template>
