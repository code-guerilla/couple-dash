<script setup lang="ts">
import { ref } from 'vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'

const props = defineProps<{
  redirectTo?: string
}>()

const { loading, error, signInWithMagicLink } = useSupabaseAuth()
const email = ref('')
const sent = ref(false)

async function submit() {
  await signInWithMagicLink(email.value, props.redirectTo)
  sent.value = true
}
</script>

<template>
  <UCard>
    <template #header>
      <div>
        <h2 class="text-xl font-black">Sign in</h2>
        <p class="text-sm text-muted">Enter your email and we will send a private login link.</p>
      </div>
    </template>

    <form class="grid gap-4" @submit.prevent="submit">
      <UAlert v-if="error" color="error" variant="soft" :description="error" />
      <UAlert
        v-if="sent"
        color="success"
        variant="soft"
        description="Check your email for the login link, then return to this page."
      />

      <UFormField label="Email" required>
        <UInput
          v-model="email"
          autocomplete="email"
          required
          type="email"
          class="w-full"
          placeholder="you@example.com"
        />
      </UFormField>

      <UButton icon="i-lucide-mail" label="Send login link" :loading="loading" type="submit" />
    </form>
  </UCard>
</template>
