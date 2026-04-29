<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import {
  supabase,
  type AdminTenantDetail,
  type AdminTenantRow,
  type CreatedTenant,
} from '@/services/supabase'

const { initialized, isAuthenticated, isSupabaseConfigured, userEmail, signOut } = useSupabaseAuth()
const checking = ref(false)
const creating = ref(false)
const loadingTenants = ref(false)
const loadingTenant = ref(false)
const savingTenant = ref(false)
const regenerating = ref(false)
const deletingTenant = ref(false)
const isAdmin = ref(false)
const adminError = ref<string | null>(null)
const tenants = ref<AdminTenantRow[]>([])
const createdTenant = ref<CreatedTenant | null>(null)
const selectedTenant = ref<AdminTenantDetail | null>(null)
const tenantSlugEdited = ref(false)
const partnerASlugEdited = ref(false)
const partnerBSlugEdited = ref(false)
const copiedKey = ref<string | null>(null)
const deleteConfirmation = ref('')

const today = new Date().toISOString().slice(0, 10)
const form = reactive({
  name: '',
  slug: '',
  subtitle: '',
  relationshipStart: today,
  weddingDate: today,
  anniversaryDate: today,
  theme: 'night',
  partnerAName: '',
  partnerASlug: '',
  partnerBName: '',
  partnerBSlug: '',
})
const editForm = reactive({
  coupleId: '',
  name: '',
  slug: '',
  subtitle: '',
  relationshipStart: today,
  weddingDate: today,
  anniversaryDate: today,
  theme: 'night',
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

  return 'The admin tenant SQL has not been applied or Supabase has not reloaded its API schema cache yet. Run supabase/schema.sql in the Supabase SQL editor, then refresh this page.'
})

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
const deleteMatchesSelectedSlug = computed(
  () => Boolean(selectedTenant.value) && deleteConfirmation.value === selectedTenant.value?.slug,
)

function slugify(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function inputValue(value: string | number) {
  return String(value)
}

function updateName(value: string | number) {
  form.name = inputValue(value)

  if (!tenantSlugEdited.value) {
    form.slug = slugify(form.name)
  }
}

function updateSlug(value: string | number) {
  tenantSlugEdited.value = true
  form.slug = slugify(inputValue(value))
}

function updatePartnerAName(value: string | number) {
  form.partnerAName = inputValue(value)

  if (!partnerASlugEdited.value) {
    form.partnerASlug = slugify(form.partnerAName)
  }
}

function updatePartnerASlug(value: string | number) {
  partnerASlugEdited.value = true
  form.partnerASlug = slugify(inputValue(value))
}

function updatePartnerBName(value: string | number) {
  form.partnerBName = inputValue(value)

  if (!partnerBSlugEdited.value) {
    form.partnerBSlug = slugify(form.partnerBName)
  }
}

function updatePartnerBSlug(value: string | number) {
  partnerBSlugEdited.value = true
  form.partnerBSlug = slugify(inputValue(value))
}

function tenantDisplayUrl(slug: string) {
  return `/display/${slug}`
}

function tenantEditUrl(slug: string) {
  return `/edit/${slug}`
}

function fillEditForm(tenant: AdminTenantDetail) {
  const [partnerA, partnerB] = tenant.partners

  editForm.coupleId = tenant.couple_id
  editForm.name = tenant.name
  editForm.slug = tenant.slug
  editForm.subtitle = tenant.subtitle ?? ''
  editForm.relationshipStart = tenant.relationship_start
  editForm.weddingDate = tenant.wedding_date
  editForm.anniversaryDate = tenant.anniversary_date
  editForm.theme = tenant.theme ?? 'night'
  editForm.partnerAId = partnerA?.id ?? ''
  editForm.partnerAName = partnerA?.name ?? ''
  editForm.partnerASlug = partnerA?.slug ?? ''
  editForm.partnerBId = partnerB?.id ?? ''
  editForm.partnerBName = partnerB?.name ?? ''
  editForm.partnerBSlug = partnerB?.slug ?? ''
  deleteConfirmation.value = ''
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

async function manageTenant(tenantId: string) {
  if (!supabase || !isAdmin.value) {
    return
  }

  loadingTenant.value = true
  adminError.value = null
  createdTenant.value = null

  const { data, error } = await supabase
    .rpc('admin_get_tenant', {
      p_couple_id: tenantId,
    })
    .single()

  loadingTenant.value = false

  if (error) {
    adminError.value = error.message
    return
  }

  selectedTenant.value = data as AdminTenantDetail
  fillEditForm(selectedTenant.value)
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
    p_anniversary_date: editForm.anniversaryDate,
    p_theme: editForm.theme,
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

  await loadTenants()
  await manageTenant(editForm.coupleId)
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

  selectedTenant.value = null
  createdTenant.value = null
  deleteConfirmation.value = ''
  await loadTenants()
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

async function createTenant() {
  if (!supabase || !isAdmin.value) {
    return
  }

  creating.value = true
  adminError.value = null
  createdTenant.value = null

  const { data, error } = await supabase
    .rpc('admin_create_tenant', {
      p_slug: form.slug,
      p_name: form.name,
      p_subtitle: form.subtitle,
      p_relationship_start: form.relationshipStart,
      p_wedding_date: form.weddingDate,
      p_anniversary_date: form.anniversaryDate,
      p_theme: form.theme,
      p_partner_a_name: form.partnerAName,
      p_partner_a_slug: form.partnerASlug,
      p_partner_b_name: form.partnerBName,
      p_partner_b_slug: form.partnerBSlug,
    })
    .single()

  creating.value = false

  if (error) {
    adminError.value = error.message
    return
  }

  createdTenant.value = data as CreatedTenant
  await loadTenants()

  form.name = ''
  form.slug = ''
  form.subtitle = ''
  form.relationshipStart = today
  form.weddingDate = today
  form.anniversaryDate = today
  form.theme = 'night'
  form.partnerAName = ''
  form.partnerASlug = ''
  form.partnerBName = ''
  form.partnerBSlug = ''
  tenantSlugEdited.value = false
  partnerASlugEdited.value = false
  partnerBSlugEdited.value = false
}

onMounted(() => void checkAdmin())
</script>

<template>
  <section class="mx-auto max-w-5xl space-y-6 pb-10">
    <AuthPanel
      v-if="isSupabaseConfigured && initialized && !isAuthenticated"
    />

    <template v-else>
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 class="text-3xl font-black">Admin</h1>
          <p class="text-sm text-muted">Create couple tenants, partner invites, and display tokens.</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <UBadge v-if="userEmail" color="neutral" variant="soft">{{ userEmail }}</UBadge>
          <UButton
            icon="i-lucide-refresh-cw"
            label="Check access"
            :loading="checking"
            size="sm"
            type="button"
            @click="checkAdmin"
          />
          <UButton
            icon="i-lucide-log-out"
            label="Sign out"
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
        description="Supabase is not configured. Tenant management needs VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY."
      />

      <UAlert
        v-else-if="initialized && isAuthenticated && !isAdmin"
        color="warning"
        variant="soft"
        description="This account is not listed in app_admin."
      />

      <template v-else-if="isAdmin">
        <UCard>
          <template #header>
            <div class="flex items-center justify-between gap-3">
              <h2 class="text-xl font-black">New Couple Tenant</h2>
              <UBadge color="success" variant="soft">Admin session confirmed</UBadge>
            </div>
          </template>

          <form class="grid gap-4" @submit.prevent="createTenant">
            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField label="Couple name" required>
                <UInput
                  :model-value="form.name"
                  class="w-full"
                  required
                  placeholder="Anna + Paul"
                  @update:model-value="updateName"
                />
              </UFormField>
              <UFormField label="Tenant slug" required>
                <UInput
                  :model-value="form.slug"
                  class="w-full"
                  required
                  placeholder="anna-paul"
                  @update:model-value="updateSlug"
                />
              </UFormField>
            </div>

            <UFormField label="Subtitle">
              <UInput
                v-model="form.subtitle"
                class="w-full"
                placeholder="Private kitchen dashboard"
              />
            </UFormField>

            <div class="grid gap-3 sm:grid-cols-3">
              <UFormField label="Relationship start" required>
                <UInput v-model="form.relationshipStart" class="w-full" required type="date" />
              </UFormField>
              <UFormField label="Wedding date" required>
                <UInput v-model="form.weddingDate" class="w-full" required type="date" />
              </UFormField>
              <UFormField label="Anniversary date" required>
                <UInput v-model="form.anniversaryDate" class="w-full" required type="date" />
              </UFormField>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField label="Partner A name" required>
                <UInput
                  :model-value="form.partnerAName"
                  class="w-full"
                  required
                  placeholder="Anna"
                  @update:model-value="updatePartnerAName"
                />
              </UFormField>
              <UFormField label="Partner A slug" required>
                <UInput
                  :model-value="form.partnerASlug"
                  class="w-full"
                  required
                  placeholder="anna"
                  @update:model-value="updatePartnerASlug"
                />
              </UFormField>
              <UFormField label="Partner B name" required>
                <UInput
                  :model-value="form.partnerBName"
                  class="w-full"
                  required
                  placeholder="Paul"
                  @update:model-value="updatePartnerBName"
                />
              </UFormField>
              <UFormField label="Partner B slug" required>
                <UInput
                  :model-value="form.partnerBSlug"
                  class="w-full"
                  required
                  placeholder="paul"
                  @update:model-value="updatePartnerBSlug"
                />
              </UFormField>
            </div>

            <div class="flex flex-wrap items-center justify-between gap-3">
              <UFormField label="Theme">
                <USelect v-model="form.theme" :items="['night', 'dawn', 'garden']" class="w-44" />
              </UFormField>
              <UButton
                icon="i-lucide-plus"
                label="Create tenant"
                :loading="creating"
                type="submit"
              />
            </div>
          </form>
        </UCard>

        <UCard v-if="createdTenant && createdLinks">
          <template #header><h2 class="text-xl font-black">Provisioning Links</h2></template>

          <div class="grid gap-3">
            <div class="rounded-md border border-default p-3">
              <div class="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <p class="text-sm font-semibold">Display URL</p>
                  <p class="break-all text-sm text-muted">{{ createdLinks.display }}</p>
                </div>
                <UButton
                  icon="i-lucide-copy"
                  :label="copiedKey === 'display' ? 'Copied' : 'Copy'"
                  size="sm"
                  variant="outline"
                  type="button"
                  @click="copyText('display', createdLinks.display)"
                />
              </div>
              <div class="mt-2 flex flex-wrap items-center justify-between gap-2">
                <p class="break-all text-sm">Token: {{ createdTenant.display_token }}</p>
                <UButton
                  icon="i-lucide-copy"
                  :label="copiedKey === 'display-token' ? 'Copied' : 'Copy token'"
                  size="sm"
                  variant="ghost"
                  type="button"
                  @click="copyText('display-token', createdTenant.display_token)"
                />
              </div>
            </div>

            <div class="grid gap-3 md:grid-cols-2">
              <div class="rounded-md border border-default p-3">
                <div class="flex flex-wrap items-center justify-between gap-2">
                  <p class="text-sm font-semibold">Partner A invite</p>
                  <UButton
                    icon="i-lucide-copy"
                    :label="copiedKey === 'partner-a' ? 'Copied' : 'Copy'"
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
                  <p class="text-sm font-semibold">Partner B invite</p>
                  <UButton
                    icon="i-lucide-copy"
                    :label="copiedKey === 'partner-b' ? 'Copied' : 'Copy'"
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

        <UCard v-if="selectedTenant">
          <template #header>
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 class="text-xl font-black">Manage {{ selectedTenant.name }}</h2>
                <p class="text-sm text-muted">Original tokens cannot be recovered. Generate fresh links when needed.</p>
              </div>
              <UButton
                icon="i-lucide-key-round"
                label="Regenerate links"
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
              <UFormField label="Couple name" required>
                <UInput v-model="editForm.name" class="w-full" required />
              </UFormField>
              <UFormField label="Tenant slug" required>
                <UInput v-model="editForm.slug" class="w-full" required />
              </UFormField>
            </div>

            <UFormField label="Subtitle">
              <UInput v-model="editForm.subtitle" class="w-full" />
            </UFormField>

            <div class="grid gap-3 sm:grid-cols-3">
              <UFormField label="Relationship start" required>
                <UInput v-model="editForm.relationshipStart" class="w-full" required type="date" />
              </UFormField>
              <UFormField label="Wedding date" required>
                <UInput v-model="editForm.weddingDate" class="w-full" required type="date" />
              </UFormField>
              <UFormField label="Anniversary date" required>
                <UInput v-model="editForm.anniversaryDate" class="w-full" required type="date" />
              </UFormField>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField label="Partner A name" required>
                <UInput v-model="editForm.partnerAName" class="w-full" required />
              </UFormField>
              <UFormField label="Partner A slug" required>
                <UInput v-model="editForm.partnerASlug" class="w-full" required />
              </UFormField>
              <UFormField label="Partner B name" required>
                <UInput v-model="editForm.partnerBName" class="w-full" required />
              </UFormField>
              <UFormField label="Partner B slug" required>
                <UInput v-model="editForm.partnerBSlug" class="w-full" required />
              </UFormField>
            </div>

            <div class="flex flex-wrap items-center justify-between gap-3">
              <UFormField label="Theme">
                <USelect
                  v-model="editForm.theme"
                  :items="['night', 'dawn', 'garden']"
                  class="w-44"
                />
              </UFormField>
              <div class="flex flex-wrap gap-2">
                <UButton
                  icon="i-lucide-x"
                  label="Close"
                  color="neutral"
                  variant="ghost"
                  type="button"
                  @click="selectedTenant = null"
                />
                <UButton
                  icon="i-lucide-save"
                  label="Save changes"
                  :loading="savingTenant"
                  type="submit"
                />
              </div>
            </div>
          </form>

          <div class="mt-6 rounded-md border border-error/30 p-4">
            <div class="grid gap-3 md:grid-cols-[1fr_auto] md:items-end">
              <div>
                <h3 class="font-bold text-error">Delete Tenant</h3>
                <p class="mt-1 text-sm text-muted">
                  This removes the couple, partners, widgets, alerts, display devices, and memberships.
                </p>
                <UFormField class="mt-3" :label="`Type ${selectedTenant.slug} to confirm`">
                  <UInput v-model="deleteConfirmation" class="w-full" />
                </UFormField>
              </div>
              <UButton
                icon="i-lucide-trash-2"
                label="Delete"
                color="error"
                :disabled="!deleteMatchesSelectedSlug"
                :loading="deletingTenant"
                type="button"
                @click="deleteSelectedTenant"
              />
            </div>
          </div>
        </UCard>

        <section class="space-y-3">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <h2 class="text-xl font-black">Tenants</h2>
            <UButton
              icon="i-lucide-refresh-cw"
              label="Refresh"
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
                <p class="mt-1 text-sm text-muted">{{ tenant.subtitle || 'No subtitle' }}</p>
                <div class="mt-3 flex flex-wrap gap-2 text-sm">
                  <UBadge color="info" variant="soft">
                    {{ tenant.accepted_partner_count }}/{{ tenant.partner_count }} partners
                  </UBadge>
                  <UBadge color="success" variant="soft">{{ tenant.widget_count }} widgets</UBadge>
                  <UBadge color="warning" variant="soft">
                    {{ tenant.active_alert_count }} active alerts
                  </UBadge>
                </div>
              </div>
              <div class="flex flex-wrap gap-2 lg:justify-end">
                <UButton
                  icon="i-lucide-monitor"
                  label="Display"
                  size="sm"
                  variant="outline"
                  :to="tenantDisplayUrl(tenant.slug)"
                />
                <UButton
                  icon="i-lucide-pencil"
                  label="Edit"
                  size="sm"
                  variant="outline"
                  :to="tenantEditUrl(tenant.slug)"
                />
                <UButton
                  icon="i-lucide-settings"
                  label="Manage"
                  :loading="loadingTenant && selectedTenant?.couple_id === tenant.couple_id"
                  size="sm"
                  type="button"
                  @click="manageTenant(tenant.couple_id)"
                />
              </div>
            </div>
          </UCard>

          <UAlert
            v-if="!loadingTenants && tenants.length === 0"
            color="neutral"
            variant="soft"
            description="No tenants have been created yet."
          />
        </section>
      </template>
    </template>
  </section>
</template>
