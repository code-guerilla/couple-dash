<script setup lang="ts">
import Button from 'primevue/button'
import Card from 'primevue/card'
import Message from 'primevue/message'
import { onMounted, ref } from 'vue'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'

const { initialized, isAuthenticated, isSupabaseConfigured } = useSupabaseAuth()
const checking = ref(false)
const isAdmin = ref(false)
const adminError = ref<string | null>(null)

async function checkAdmin() {
  adminError.value = null

  if (!isSupabaseConfigured || !supabase || !isAuthenticated.value) {
    return
  }

  checking.value = true
  const { data, error } = await supabase.rpc('is_app_admin')
  checking.value = false

  if (error) {
    adminError.value = error.message
    return
  }

  isAdmin.value = Boolean(data)
}

onMounted(() => void checkAdmin())
</script>

<template>
  <section class="mx-auto max-w-3xl space-y-4">
    <AuthPanel v-if="isSupabaseConfigured && initialized && !isAuthenticated" @signed-in="checkAdmin" />

    <Card v-else>
      <template #content>
        <div class="grid gap-4">
        <div class="flex items-center justify-between gap-4">
          <div>
            <h1 class="text-2xl font-black">Admin</h1>
            <p class="text-sm muted">App admins can manage all private dashboard tenants.</p>
          </div>
          <Button label="Check access" :loading="checking" size="small" type="button" @click="checkAdmin" />
        </div>

        <Message v-if="adminError" severity="error" :closable="false">{{ adminError }}</Message>

        <Message v-else-if="isAdmin" severity="success" :closable="false">
          Admin session confirmed. Build tenant management here.
        </Message>

        <Message v-else severity="warn" :closable="false">This account is not listed in app_admin.</Message>
        </div>
      </template>
    </Card>
  </section>
</template>

