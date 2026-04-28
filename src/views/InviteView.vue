<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'

const route = useRoute()
const router = useRouter()
const coupleSlug = computed(() => String(route.params.coupleSlug))
const partnerSlug = computed(() => String(route.params.partnerSlug))
const inviteToken = computed(() => String(route.query.token ?? ''))
const accepting = ref(false)
const accepted = ref(false)
const acceptError = ref<string | null>(null)
const { initialized, isAuthenticated, isSupabaseConfigured } = useSupabaseAuth()

async function acceptInvite() {
  acceptError.value = null

  if (!isSupabaseConfigured || !supabase) {
    acceptError.value = 'Supabase is required for private partner invites.'
    return
  }

  if (!isAuthenticated.value) {
    return
  }

  if (!inviteToken.value) {
    acceptError.value = 'This invite link is missing its private token.'
    return
  }

  accepting.value = true
  const { error } = await supabase.rpc('accept_partner_invite', {
    p_slug: coupleSlug.value,
    p_partner_slug: partnerSlug.value,
    p_invite_token: inviteToken.value,
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
    <AuthPanel v-if="isSupabaseConfigured && initialized && !isAuthenticated" @signed-in="acceptInvite" />

    <UCard v-else>
      <template #header>
        <div>
          <h1 class="text-xl font-black">Partner Invite</h1>
          <p class="text-sm muted">Accepting this invite links your Supabase account to this partner profile.</p>
        </div>
      </template>

      <div class="form-stack">
        <UAlert v-if="acceptError" color="error" variant="soft" :description="acceptError" />

        <UAlert
          v-else-if="accepted"
          color="success"
          variant="soft"
          description="Invite accepted. Opening the private edit console."
        />

        <UButton label="Accept invite" :loading="accepting" type="button" @click="acceptInvite" />
      </div>
    </UCard>
  </section>
</template>
