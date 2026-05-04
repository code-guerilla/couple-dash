<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import slugify from 'slugify'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase, type CreatedTenant } from '@/services/supabase'

const router = useRouter()
const { initialized, isAuthenticated, isSupabaseConfigured, userEmail, signOut } = useSupabaseAuth()
const checking = ref(false)
const creating = ref(false)
const isAdmin = ref(false)
const adminError = ref<string | null>(null)
const createdTenant = ref<CreatedTenant | null>(null)
const copiedKey = ref<string | null>(null)
const text = {
  title: 'New Couple Tenant',
  description: 'Create one couple tenant and generate partner invite links.',
  back: 'Back to admin',
  checkAccess: 'Check access',
  signOut: 'Sign out',
  setupError:
    'The admin tenant SQL has not been applied or Supabase has not reloaded its API schema cache yet. Run supabase/schema.sql in the Supabase SQL editor, then refresh this page.',
  supabaseMissing:
    'Supabase is not configured. Tenant management needs VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY.',
  notAdmin: 'This account is not listed in app_admin.',
  coupleName: 'Couple name',
  coupleNamePlaceholder: 'Anna + Paul',
  tenantSlug: 'Tenant slug',
  tenantSlugPlaceholder: 'anna-paul',
  subtitle: 'Subtitle',
  subtitlePlaceholder: 'Private kitchen dashboard',
  relationshipStart: 'Relationship start',
  weddingDate: 'Wedding date',
  anniversaryDate: 'Anniversary date',
  partnerAName: 'Partner A name',
  partnerANamePlaceholder: 'Anna',
  partnerASlug: 'Partner A slug',
  partnerASlugPlaceholder: 'anna',
  partnerBName: 'Partner B name',
  partnerBNamePlaceholder: 'Paul',
  partnerBSlug: 'Partner B slug',
  partnerBSlugPlaceholder: 'paul',
  createTenant: 'Create tenant',
  provisioningLinks: 'Provisioning Links',
  displayUrl: 'Display URL',
  copied: 'Copied',
  copy: 'Copy',
  partnerAInvite: 'Partner A invite',
  partnerBInvite: 'Partner B invite',
}

const today = new Date().toISOString().slice(0, 10)
const form = reactive({
  name: '',
  slug: '',
  subtitle: '',
  relationshipStart: today,
  weddingDate: today,
  anniversaryDate: today,
  partnerAName: '',
  partnerASlug: '',
  partnerBName: '',
  partnerBSlug: '',
})
const tenantSlugEdited = ref(false)
const partnerASlugEdited = ref(false)
const partnerBSlugEdited = ref(false)
const origin = computed(() =>
  typeof window === 'undefined' ? '' : window.location.origin.replace(/\/$/, ''),
)
const setupError = computed(() => {
  if (!adminError.value?.includes('admin_')) {
    return null
  }

  return text.setupError
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

function toSlug(value: string) {
  return slugify(value, {
    lower: true,
    strict: true,
    trim: true,
  })
}

function inputValue(value: string | number) {
  return String(value)
}

function updateName(value: string | number) {
  form.name = inputValue(value)

  if (!tenantSlugEdited.value) {
    form.slug = toSlug(form.name)
  }
}

function updateSlug(value: string | number) {
  tenantSlugEdited.value = true
  form.slug = toSlug(inputValue(value))
}

function updatePartnerAName(value: string | number) {
  form.partnerAName = inputValue(value)

  if (!partnerASlugEdited.value) {
    form.partnerASlug = toSlug(form.partnerAName)
  }
}

function updatePartnerASlug(value: string | number) {
  partnerASlugEdited.value = true
  form.partnerASlug = toSlug(inputValue(value))
}

function updatePartnerBName(value: string | number) {
  form.partnerBName = inputValue(value)

  if (!partnerBSlugEdited.value) {
    form.partnerBSlug = toSlug(form.partnerBName)
  }
}

function updatePartnerBSlug(value: string | number) {
  partnerBSlugEdited.value = true
  form.partnerBSlug = toSlug(inputValue(value))
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

  form.name = ''
  form.slug = ''
  form.subtitle = ''
  form.relationshipStart = today
  form.weddingDate = today
  form.anniversaryDate = today
  form.partnerAName = ''
  form.partnerASlug = ''
  form.partnerBName = ''
  form.partnerBSlug = ''
  tenantSlugEdited.value = false
  partnerASlugEdited.value = false
  partnerBSlugEdited.value = false
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
          <h1 class="text-3xl font-black">{{ text.title }}</h1>
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

      <template v-else-if="isAdmin">
        <UCard>
          <form class="grid gap-4" @submit.prevent="createTenant">
            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField :label="text.coupleName" required>
                <UInput
                  :model-value="form.name"
                  class="w-full"
                  required
                  :placeholder="text.coupleNamePlaceholder"
                  @update:model-value="updateName"
                />
              </UFormField>
              <UFormField :label="text.tenantSlug" required>
                <UInput
                  :model-value="form.slug"
                  class="w-full"
                  required
                  :placeholder="text.tenantSlugPlaceholder"
                  @update:model-value="updateSlug"
                />
              </UFormField>
            </div>

            <UFormField :label="text.subtitle">
              <UInput
                v-model="form.subtitle"
                class="w-full"
                :placeholder="text.subtitlePlaceholder"
              />
            </UFormField>

            <div class="grid gap-3 sm:grid-cols-3">
              <UFormField :label="text.relationshipStart" required>
                <UInput v-model="form.relationshipStart" class="w-full" required type="date" />
              </UFormField>
              <UFormField :label="text.weddingDate" required>
                <UInput v-model="form.weddingDate" class="w-full" required type="date" />
              </UFormField>
              <UFormField :label="text.anniversaryDate" required>
                <UInput v-model="form.anniversaryDate" class="w-full" required type="date" />
              </UFormField>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField :label="text.partnerAName" required>
                <UInput
                  :model-value="form.partnerAName"
                  class="w-full"
                  required
                  :placeholder="text.partnerANamePlaceholder"
                  @update:model-value="updatePartnerAName"
                />
              </UFormField>
              <UFormField :label="text.partnerASlug" required>
                <UInput
                  :model-value="form.partnerASlug"
                  class="w-full"
                  required
                  :placeholder="text.partnerASlugPlaceholder"
                  @update:model-value="updatePartnerASlug"
                />
              </UFormField>
              <UFormField :label="text.partnerBName" required>
                <UInput
                  :model-value="form.partnerBName"
                  class="w-full"
                  required
                  :placeholder="text.partnerBNamePlaceholder"
                  @update:model-value="updatePartnerBName"
                />
              </UFormField>
              <UFormField :label="text.partnerBSlug" required>
                <UInput
                  :model-value="form.partnerBSlug"
                  class="w-full"
                  required
                  :placeholder="text.partnerBSlugPlaceholder"
                  @update:model-value="updatePartnerBSlug"
                />
              </UFormField>
            </div>

            <div class="flex flex-wrap items-center justify-end gap-3">
              <UButton
                icon="i-lucide-plus"
                :label="text.createTenant"
                :loading="creating"
                type="submit"
              />
            </div>
          </form>
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
