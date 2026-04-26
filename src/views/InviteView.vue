<script setup lang="ts">
import Button from 'primevue/button'
import Card from 'primevue/card'
import Message from 'primevue/message'
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

    <Card v-else>
      <template #title>Partner Invite</template>
      <template #subtitle>
          Accepting this invite links your Supabase account to this partner profile.
      </template>
      <template #content>
        <div class="form-stack">

        <Message v-if="acceptError" severity="error" :closable="false">{{ acceptError }}</Message>

        <Message v-else-if="accepted" severity="success" :closable="false">
          Invite accepted. Opening the private edit console.
        </Message>

        <Button label="Accept invite" :loading="accepting" type="button" @click="acceptInvite" />
        </div>
      </template>
    </Card>
  </section>
</template>
