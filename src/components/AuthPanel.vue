<script setup lang="ts">
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { ref } from 'vue'
import type { AuthFormField, ButtonProps, FormSubmitEvent } from '@nuxt/ui'

const props = defineProps<{
  redirectTo?: string
}>()

type MagicLinkPayload = {
  email: string
}

const { loading, error, signInWithGoogle, sendMagicLink } = useSupabaseAuth()
const magicLinkSent = ref(false)

const fields: AuthFormField[] = [
  {
    name: 'email',
    type: 'email',
    label: 'Email',
    placeholder: 'you@example.com',
    required: true,
  },
]

const providers: ButtonProps[] = [
  {
    label: 'Continue with Google',
    icon: 'i-simple-icons-google',
    color: 'neutral',
    variant: 'subtle',
    onClick: signInGoogle,
  },
]

async function signInGoogle() {
  await signInWithGoogle(props.redirectTo)
}

async function submitMagicLink(event: FormSubmitEvent<MagicLinkPayload>) {
  await sendMagicLink(event.data.email, props.redirectTo)
  magicLinkSent.value = true
}
</script>

<template>
  <UAuthForm
    title="Sign in"
    description="Use Google or an email magic link."
    icon="i-lucide-lock"
    :fields="fields"
    :providers="providers"
    :loading="loading"
    :submit="{ label: 'Send magic link' }"
    class="w-full max-w-md"
    @submit="submitMagicLink"
  >
    <template #validation>
      <UAlert v-if="error" color="error" variant="soft" :description="error" />
      <UAlert
        v-else-if="magicLinkSent"
        color="success"
        variant="soft"
        description="Check your email for a secure sign-in link."
      />
    </template>
  </UAuthForm>
</template>
