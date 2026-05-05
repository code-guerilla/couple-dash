<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase, type AdminTenantDetail, type CreatedTenant } from '@/services/supabase'

const route = useRoute()
const router = useRouter()
const tenantId = computed(() => String(route.params.tenantId ?? ''))
const { initialized, isAuthenticated, isSupabaseConfigured, userEmail, signOut } = useSupabaseAuth()
const checking = ref(false)
const loadingTenant = ref(false)
const savingTenant = ref(false)
const regenerating = ref(false)
const deletingTenant = ref(false)
const isAdmin = ref(false)
const adminError = ref<string | null>(null)
const selectedTenant = ref<AdminTenantDetail | null>(null)
const createdTenant = ref<CreatedTenant | null>(null)
const copiedKey = ref<string | null>(null)
const deleteConfirmation = ref('')
const text = {
  title: 'Manage Tenant',
  description: 'Update the couple configuration, partners, and provisioning links.',
  back: 'Back to admin',
  checkAccess: 'Check access',
  signOut: 'Sign out',
  setupError:
    'The admin tenant SQL has not been applied or Supabase has not reloaded its API schema cache yet. Run supabase/schema.sql in the Supabase SQL editor, then refresh this page.',
  supabaseMissing:
    'Supabase is not configured. Tenant management needs VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY.',
  notAdmin: 'This account is not listed in app_admin.',
  tenantNotFound: 'Tenant could not be loaded.',
  tokenWarning: 'Original invite links cannot be recovered. Generate fresh links when needed.',
  regenerateLinks: 'Regenerate links',
  coupleName: 'Couple name',
  tenantSlug: 'Tenant slug',
  subtitle: 'Subtitle',
  relationshipStart: 'Relationship start',
  weddingDate: 'Wedding date',
  partnerAName: 'Partner A name',
  partnerASlug: 'Partner A slug',
  partnerBName: 'Partner B name',
  partnerBSlug: 'Partner B slug',
  saveChanges: 'Save changes',
  deleteTenant: 'Delete Tenant',
  deleteDescription: 'This removes the couple, partners, widgets, alerts, and memberships.',
  delete: 'Delete',
  provisioningLinks: 'Account Links',
  displayUrl: 'Shared display',
  copied: 'Copied',
  copy: 'Copy',
  partnerAInvite: 'Partner A invite',
  partnerBInvite: 'Partner B invite',
}

const today = new Date().toISOString().slice(0, 10)
const editForm = reactive({
  coupleId: '',
  name: '',
  slug: '',
  subtitle: '',
  relationshipStart: today,
  weddingDate: today,
  partnerAId: '',
  partnerAName: '',
  partnerASlug: '',
  partnerBId: '',
  partnerBName: '',
  partnerBSlug: '',
})

const origin = computed(() =>
  typeof window === 'undefined' ? '' : window.location.origin.replace(/\/$/, ''),
)
const setupError = computed(() => {
  if (!adminError.value?.includes('admin_')) {
    return null
  }

  return text.setupError
})
const deleteMatchesSelectedSlug = computed(
  () => Boolean(selectedTenant.value) && deleteConfirmation.value === selectedTenant.value?.slug,
)
const createdLinks = computed(() => {
  if (!createdTenant.value) {
    return null
  }

  return {
    display: `${origin.value}/display/${createdTenant.value.slug}`,
    partnerA: `${origin.value}/invite/${createdTenant.value.slug}/${createdTenant.value.partner_a_slug}?token=${createdTenant.value.partner_a_invite_token}`,
    partnerB: `${origin.value}/invite/${createdTenant.value.slug}/${createdTenant.value.partner_b_slug}?token=${createdTenant.value.partner_b_invite_token}`,
  }
})
const pageTitle = computed(() => selectedTenant.value?.name ?? text.title)

function fillEditForm(tenant: AdminTenantDetail) {
  const [partnerA, partnerB] = tenant.partners

  editForm.coupleId = tenant.couple_id
  editForm.name = tenant.name
  editForm.slug = tenant.slug
  editForm.subtitle = tenant.subtitle ?? ''
  editForm.relationshipStart = tenant.relationship_start
  editForm.weddingDate = tenant.wedding_date
  editForm.partnerAId = partnerA?.id ?? ''
  editForm.partnerAName = partnerA?.name ?? ''
  editForm.partnerASlug = partnerA?.slug ?? ''
  editForm.partnerBId = partnerB?.id ?? ''
  editForm.partnerBName = partnerB?.name ?? ''
  editForm.partnerBSlug = partnerB?.slug ?? ''
  deleteConfirmation.value = ''
}

function typeToConfirmLabel(slug: string) {
  return `Type ${slug} to confirm`
}

async function copyText(key: string, value: string) {
  await navigator.clipboard.writeText(value)
  copiedKey.value = key
  window.setTimeout(() => {
    if (copiedKey.value === key) {
      copiedKey.value = null
    }
  }, 1600)
}

async function loadTenant() {
  if (!supabase || !isAdmin.value || !tenantId.value) {
    selectedTenant.value = null
    return
  }

  loadingTenant.value = true
  adminError.value = null
  createdTenant.value = null

  const { data, error } = await supabase
    .rpc('admin_get_tenant', {
      p_couple_id: tenantId.value,
    })
    .single()

  loadingTenant.value = false

  if (error) {
    adminError.value = error.message
    selectedTenant.value = null
    return
  }

  selectedTenant.value = data as AdminTenantDetail
  fillEditForm(selectedTenant.value)
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
    await loadTenant()
  }
}

async function saveTenant() {
  if (!supabase || !selectedTenant.value) {
    return
  }

  savingTenant.value = true
  adminError.value = null

  const { error } = await supabase.rpc('admin_update_tenant', {
    p_couple_id: editForm.coupleId,
    p_slug: editForm.slug,
    p_name: editForm.name,
    p_subtitle: editForm.subtitle,
    p_relationship_start: editForm.relationshipStart,
    p_wedding_date: editForm.weddingDate,
    p_partner_a_id: editForm.partnerAId,
    p_partner_a_name: editForm.partnerAName,
    p_partner_a_slug: editForm.partnerASlug,
    p_partner_b_id: editForm.partnerBId,
    p_partner_b_name: editForm.partnerBName,
    p_partner_b_slug: editForm.partnerBSlug,
  })

  savingTenant.value = false

  if (error) {
    adminError.value = error.message
    return
  }

  await loadTenant()
}

async function regenerateCredentials() {
  if (!supabase || !selectedTenant.value) {
    return
  }

  regenerating.value = true
  adminError.value = null

  const { data, error } = await supabase
    .rpc('admin_regenerate_tenant_credentials', {
      p_couple_id: selectedTenant.value.couple_id,
    })
    .single()

  regenerating.value = false

  if (error) {
    adminError.value = error.message
    return
  }

  createdTenant.value = data as CreatedTenant
}

async function deleteSelectedTenant() {
  if (!supabase || !selectedTenant.value || !deleteMatchesSelectedSlug.value) {
    return
  }

  deletingTenant.value = true
  adminError.value = null

  const { error } = await supabase.rpc('admin_delete_tenant', {
    p_couple_id: selectedTenant.value.couple_id,
  })

  deletingTenant.value = false

  if (error) {
    adminError.value = error.message
    return
  }

  await router.push({ name: 'admin' })
}

onMounted(() => void checkAdmin())

watch([initialized, isAuthenticated], () => void checkAdmin())
</script>

<template>
  <section class="mx-auto max-w-3xl space-y-6 pb-10">
    <AuthPanel v-if="isSupabaseConfigured && initialized && !isAuthenticated" mode="admin" />

    <template v-else>
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p class="text-sm font-semibold text-muted">{{ text.title }}</p>
          <h1 class="text-3xl font-black">{{ pageTitle }}</h1>
          <p class="text-sm text-muted">{{ text.description }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <UBadge v-if="userEmail" color="neutral" variant="soft">{{ userEmail }}</UBadge>
          <UButton
            icon="i-lucide-arrow-left"
            :label="text.back"
            color="neutral"
            variant="ghost"
            type="button"
            @click="router.push({ name: 'admin' })"
          />
          <UButton
            icon="i-lucide-refresh-cw"
            :label="text.checkAccess"
            :loading="checking || loadingTenant"
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

      <UAlert
        v-else-if="isAdmin && !loadingTenant && !selectedTenant"
        color="warning"
        variant="soft"
        :description="text.tenantNotFound"
      />

      <template v-else-if="isAdmin && selectedTenant">
        <UCard>
          <template #header>
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 class="text-xl font-black">{{ selectedTenant.name }}</h2>
                <p class="text-sm text-muted">{{ text.tokenWarning }}</p>
              </div>
              <UButton
                icon="i-lucide-key-round"
                :label="text.regenerateLinks"
                :loading="regenerating"
                color="warning"
                variant="soft"
                type="button"
                @click="regenerateCredentials"
              />
            </div>
          </template>

          <form class="grid gap-4" @submit.prevent="saveTenant">
            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField :label="text.coupleName" required>
                <UInput v-model="editForm.name" class="w-full" required />
              </UFormField>
              <UFormField :label="text.tenantSlug" required>
                <UInput v-model="editForm.slug" class="w-full" required />
              </UFormField>
            </div>

            <UFormField :label="text.subtitle">
              <UInput v-model="editForm.subtitle" class="w-full" />
            </UFormField>

            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField :label="text.relationshipStart" required>
                <UInput v-model="editForm.relationshipStart" class="w-full" required type="date" />
              </UFormField>
              <UFormField :label="text.weddingDate" required>
                <UInput v-model="editForm.weddingDate" class="w-full" required type="date" />
              </UFormField>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField :label="text.partnerAName" required>
                <UInput v-model="editForm.partnerAName" class="w-full" required />
              </UFormField>
              <UFormField :label="text.partnerASlug" required>
                <UInput v-model="editForm.partnerASlug" class="w-full" required />
              </UFormField>
              <UFormField :label="text.partnerBName" required>
                <UInput v-model="editForm.partnerBName" class="w-full" required />
              </UFormField>
              <UFormField :label="text.partnerBSlug" required>
                <UInput v-model="editForm.partnerBSlug" class="w-full" required />
              </UFormField>
            </div>

            <div class="flex flex-wrap justify-end gap-2">
              <UButton
                icon="i-lucide-save"
                :label="text.saveChanges"
                :loading="savingTenant"
                type="submit"
              />
            </div>
          </form>

          <div class="mt-6 rounded-md border border-error/30 p-4">
            <div class="grid gap-3 md:grid-cols-[1fr_auto] md:items-end">
              <div>
                <h3 class="font-bold text-error">{{ text.deleteTenant }}</h3>
                <p class="mt-1 text-sm text-muted">
                  {{ text.deleteDescription }}
                </p>
                <UFormField class="mt-3" :label="typeToConfirmLabel(selectedTenant.slug)">
                  <UInput v-model="deleteConfirmation" class="w-full" />
                </UFormField>
              </div>
              <UButton
                icon="i-lucide-trash-2"
                :label="text.delete"
                color="error"
                :disabled="!deleteMatchesSelectedSlug"
                :loading="deletingTenant"
                type="button"
                @click="deleteSelectedTenant"
              />
            </div>
          </div>
        </UCard>

        <UCard v-if="createdTenant && createdLinks">
          <template #header
            ><h2 class="text-xl font-black">{{ text.provisioningLinks }}</h2></template
          >

          <div class="grid gap-3">
            <div class="rounded-md border border-default p-3">
              <div class="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <p class="text-sm font-semibold">{{ text.displayUrl }}</p>
                  <p class="break-all text-sm text-muted">{{ createdLinks.display }}</p>
                </div>
                <UButton
                  icon="i-lucide-copy"
                  :label="copiedKey === 'display' ? text.copied : text.copy"
                  size="sm"
                  variant="outline"
                  type="button"
                  @click="copyText('display', createdLinks.display)"
                />
              </div>
            </div>

            <div class="grid gap-3 md:grid-cols-2">
              <div class="rounded-md border border-default p-3">
                <div class="flex flex-wrap items-center justify-between gap-2">
                  <p class="text-sm font-semibold">{{ text.partnerAInvite }}</p>
                  <UButton
                    icon="i-lucide-copy"
                    :label="copiedKey === 'partner-a' ? text.copied : text.copy"
                    size="sm"
                    variant="outline"
                    type="button"
                    @click="copyText('partner-a', createdLinks.partnerA)"
                  />
                </div>
                <p class="mt-2 break-all text-sm text-muted">{{ createdLinks.partnerA }}</p>
              </div>
              <div class="rounded-md border border-default p-3">
                <div class="flex flex-wrap items-center justify-between gap-2">
                  <p class="text-sm font-semibold">{{ text.partnerBInvite }}</p>
                  <UButton
                    icon="i-lucide-copy"
                    :label="copiedKey === 'partner-b' ? text.copied : text.copy"
                    size="sm"
                    variant="outline"
                    type="button"
                    @click="copyText('partner-b', createdLinks.partnerB)"
                  />
                </div>
                <p class="mt-2 break-all text-sm text-muted">{{ createdLinks.partnerB }}</p>
              </div>
            </div>
          </div>
        </UCard>
      </template>
    </template>
  </section>
</template>
