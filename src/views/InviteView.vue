<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const coupleSlug = computed(() => String(route.params.coupleSlug))
const partnerSlug = computed(() => String(route.params.partnerSlug))
const inviteToken = computed(() => String(route.query.token ?? ''))
const inviteRedirectTo = computed(() =>
  typeof window === 'undefined' ? undefined : window.location.href,
)
const accepting = ref(false)
const accepted = ref(false)
const acceptError = ref<string | null>(null)
const { initialized, isAuthenticated, isSupabaseConfigured } = useSupabaseAuth()

async function acceptInvite() {
  if (accepting.value || accepted.value) {
    return
  }

  acceptError.value = null

  if (!isSupabaseConfigured || !supabase) {
    acceptError.value = t('invite.required')
    return
  }

  if (!isAuthenticated.value) {
    return
  }

  const token = inviteToken.value.trim()

  if (!token) {
    acceptError.value = t('invite.missingToken')
    return
  }

  accepting.value = true
  const { error } = await supabase.rpc('accept_partner_invite', {
    p_slug: coupleSlug.value,
    p_partner_slug: partnerSlug.value,
    p_invite_token: token,
  })
  accepting.value = false

  if (error) {
    acceptError.value = error.message
    return
  }

  accepted.value = true
  await router.replace({ name: 'edit', params: { coupleSlug: coupleSlug.value } })
}

watch(isAuthenticated, () => void acceptInvite())
onMounted(() => void acceptInvite())
</script>

<template>
  <section class="mx-auto max-w-md space-y-4">
    <AuthPanel
      v-if="isSupabaseConfigured && initialized && !isAuthenticated"
      :redirect-to="inviteRedirectTo"
    />

    <UCard v-else>
      <template #header>
        <div>
          <h1 class="text-xl font-black">{{ t('invite.title') }}</h1>
          <p class="text-sm text-muted">
            {{ t('invite.description') }}
          </p>
        </div>
      </template>

      <div class="grid gap-4">
        <UAlert v-if="acceptError" color="error" variant="soft" :description="acceptError" />

        <UAlert
          v-else-if="accepted"
          color="success"
          variant="soft"
          :description="t('invite.accepted')"
        />

        <UButton
          :label="t('invite.accept')"
          :loading="accepting"
          type="button"
          @click="acceptInvite"
        />
      </div>
    </UCard>
  </section>
</template>
