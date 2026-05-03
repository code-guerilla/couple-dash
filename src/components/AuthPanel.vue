<script setup lang="ts">
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import type { AuthFormField, ButtonProps, FormSubmitEvent } from '@nuxt/ui'

const props = defineProps<{
  redirectTo?: string
}>()

type MagicLinkPayload = {
  email: string
}

const { loading, error, signInWithGoogle, sendMagicLink } = useSupabaseAuth()
const magicLinkSent = ref(false)
const { t } = useI18n()

const fields = computed<AuthFormField[]>(() => [
  {
    name: 'email',
    type: 'email',
    label: t('auth.email'),
    placeholder: t('auth.emailPlaceholder'),
    required: true,
  },
])

const providers = computed<ButtonProps[]>(() => [
  {
    label: t('auth.continueGoogle'),
    icon: 'i-simple-icons-google',
    color: 'neutral',
    variant: 'subtle',
    onClick: signInGoogle,
  },
])

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
    :title="t('auth.signIn')"
    :description="t('auth.description')"
    icon="i-lucide-lock"
    :fields="fields"
    :providers="providers"
    :loading="loading"
    :submit="{ label: t('auth.sendMagicLink') }"
    class="w-full max-w-md"
    @submit="submitMagicLink"
  >
    <template #validation>
      <UAlert v-if="error" color="error" variant="soft" :description="error" />
      <UAlert
        v-else-if="magicLinkSent"
        color="success"
        variant="soft"
        :description="t('auth.magicLinkSent')"
      />
    </template>
  </UAuthForm>
</template>
