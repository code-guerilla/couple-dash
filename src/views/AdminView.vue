<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase, type AdminTenantRow } from '@/services/supabase'

const router = useRouter()
const { initialized, isAuthenticated, isSupabaseConfigured, userEmail, signOut } = useSupabaseAuth()
const checking = ref(false)
const loadingTenants = ref(false)
const isAdmin = ref(false)
const adminError = ref<string | null>(null)
const tenants = ref<AdminTenantRow[]>([])
const text = {
  title: 'Admin',
  description: 'Create couple tenants, manage partner invites, and open account-based displays.',
  checkAccess: 'Check access',
  signOut: 'Sign out',
  setupError:
    'The admin tenant SQL has not been applied or Supabase has not reloaded its API schema cache yet. Run supabase/schema.sql in the Supabase SQL editor, then refresh this page.',
  supabaseMissing:
    'Supabase is not configured. Tenant management needs VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY.',
  notAdmin: 'This account is not listed in app_admin.',
  newTenant: 'New Couple Tenant',
  tenants: 'Tenants',
  refresh: 'Refresh',
  noSubtitle: 'No subtitle',
  display: 'Display',
  edit: 'Edit',
  manage: 'Manage',
  noTenants: 'No tenants have been created yet.',
}

const setupError = computed(() => {
  if (!adminError.value?.includes('admin_')) {
    return null
  }

  return text.setupError
})

function tenantDisplayUrl(slug: string) {
  return `/display/${slug}`
}

function tenantEditUrl(slug: string) {
  return `/edit/${slug}`
}

function partnerCountLabel(accepted: string | number, total: string | number) {
  return `${accepted}/${total} partners`
}

function widgetsLabel(count: string | number) {
  return `${count} widgets`
}

function activeAlertsLabel(count: string | number) {
  return `${count} active alerts`
}

async function loadTenants() {
  if (!supabase || !isAdmin.value) {
    tenants.value = []
    return
  }

  loadingTenants.value = true
  adminError.value = null
  const { data, error } = await supabase.rpc('admin_list_tenants')
  loadingTenants.value = false

  if (error) {
    adminError.value = error.message
    return
  }

  tenants.value = (data ?? []) as AdminTenantRow[]
}

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
    isAdmin.value = false
    return
  }

  isAdmin.value = Boolean(data)

  if (isAdmin.value) {
    await loadTenants()
  }
}

onMounted(() => void checkAdmin())

watch([initialized, isAuthenticated], () => void checkAdmin())
</script>

<template>
  <section class="mx-auto max-w-5xl space-y-6 pb-10">
    <AuthPanel v-if="isSupabaseConfigured && initialized && !isAuthenticated" mode="admin" />

    <template v-else>
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 class="text-3xl font-black">{{ text.title }}</h1>
          <p class="text-sm text-muted">{{ text.description }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <UBadge v-if="userEmail" color="neutral" variant="soft">{{ userEmail }}</UBadge>
          <UButton
            icon="i-lucide-plus"
            :label="text.newTenant"
            :disabled="!isAdmin"
            type="button"
            @click="router.push({ name: 'admin-new' })"
          />
          <UButton
            icon="i-lucide-refresh-cw"
            :label="text.checkAccess"
            :loading="checking"
            size="sm"
            type="button"
            @click="checkAdmin"
          />
          <UButton
            icon="i-lucide-log-out"
            :label="text.signOut"
            color="neutral"
            variant="ghost"
            size="sm"
            type="button"
            @click="signOut"
          />
        </div>
      </div>

      <UAlert
        v-if="adminError"
        color="error"
        variant="soft"
        :description="setupError ?? adminError"
      />

      <UAlert
        v-if="!isSupabaseConfigured"
        color="warning"
        variant="soft"
        :description="text.supabaseMissing"
      />

      <UAlert
        v-else-if="initialized && isAuthenticated && !isAdmin"
        color="warning"
        variant="soft"
        :description="text.notAdmin"
      />

      <section v-else-if="isAdmin" class="space-y-3">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <h2 class="text-xl font-black">{{ text.tenants }}</h2>
          <UButton
            icon="i-lucide-refresh-cw"
            :label="text.refresh"
            :loading="loadingTenants"
            size="sm"
            variant="ghost"
            type="button"
            @click="loadTenants"
          />
        </div>

        <UCard v-for="tenant in tenants" :key="tenant.couple_id">
          <div class="grid gap-4 lg:grid-cols-[1fr_auto] lg:items-center">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <h3 class="text-lg font-black">{{ tenant.name }}</h3>
                <UBadge color="neutral" variant="soft">{{ tenant.slug }}</UBadge>
              </div>
              <p class="mt-1 text-sm text-muted">
                {{ tenant.subtitle || text.noSubtitle }}
              </p>
              <div class="mt-3 flex flex-wrap gap-2 text-sm">
                <UBadge color="info" variant="soft">
                  {{ partnerCountLabel(tenant.accepted_partner_count, tenant.partner_count) }}
                </UBadge>
                <UBadge color="success" variant="soft">
                  {{ widgetsLabel(tenant.widget_count) }}
                </UBadge>
                <UBadge color="warning" variant="soft">
                  {{ activeAlertsLabel(tenant.active_alert_count) }}
                </UBadge>
              </div>
            </div>
            <div class="flex flex-wrap gap-2 lg:justify-end">
              <a
                class="inline-flex h-8 items-center gap-1.5 rounded-md border border-default px-2.5 text-sm font-medium text-default hover:bg-elevated"
                :href="tenantDisplayUrl(tenant.slug)"
              >
                <UIcon name="i-lucide-monitor" class="size-4" />
                {{ text.display }}
              </a>
              <a
                class="inline-flex h-8 items-center gap-1.5 rounded-md border border-default px-2.5 text-sm font-medium text-default hover:bg-elevated"
                :href="tenantEditUrl(tenant.slug)"
              >
                <UIcon name="i-lucide-pencil" class="size-4" />
                {{ text.edit }}
              </a>
              <UButton
                icon="i-lucide-settings"
                :label="text.manage"
                size="sm"
                type="button"
                @click="
                  router.push({ name: 'admin-tenant', params: { tenantId: tenant.couple_id } })
                "
              />
            </div>
          </div>
        </UCard>

        <UAlert
          v-if="!loadingTenants && tenants.length === 0"
          color="neutral"
          variant="soft"
          :description="text.noTenants"
        />
      </section>
    </template>
  </section>
</template>
