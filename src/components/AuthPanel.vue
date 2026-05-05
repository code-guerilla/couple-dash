<script setup lang="ts">
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { computed, ref } from 'vue'
import type { AuthFormField, ButtonProps, FormSubmitEvent } from '@nuxt/ui'

const props = defineProps<{
  redirectTo?: string
  mode?: 'admin' | 'partner'
}>()

type MagicLinkPayload = {
  email: string
}

const { loading, error, signInWithGoogle, sendMagicLink } = useSupabaseAuth()
const magicLinkSent = ref(false)
const isAdminMode = computed(() => props.mode === 'admin')

const fields = computed<AuthFormField[]>(() => [
  ...(isAdminMode.value
    ? []
    : [
        {
          name: 'email',
          type: 'email',
          label: 'Email',
          placeholder: 'you@example.com',
          required: true,
        },
      ]),
])

const providers = computed<ButtonProps[]>(() => [
  {
    label: 'Continue with Google',
    icon: 'i-simple-icons-google',
    color: 'neutral',
    variant: 'subtle',
    onClick: signInGoogle,
  },
])

const description = computed(() =>
  isAdminMode.value ? 'Use Google to access the admin area.' : 'Use Google or an email magic link.',
)

const submit = computed(() => (isAdminMode.value ? undefined : { label: 'Send magic link' }))

async function signInGoogle() {
  await signInWithGoogle(props.redirectTo)
}

async function submitMagicLink(event: FormSubmitEvent<MagicLinkPayload>) {
  await sendMagicLink(event.data.email, props.redirectTo)
  magicLinkSent.value = true
}
</script>

<template>
  <div class="flex w-full justify-center">
    <UPageCard class="w-full max-w-md">
      <div class="space-y-4">
        <UAuthForm
          title="Sign in"
          :description="description"
          icon="i-lucide-lock"
          :fields="fields"
          :providers="providers"
          :loading="loading"
          :submit="submit"
          separator="or"
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
      </div>
    </UPageCard>
  </div>
</template>
