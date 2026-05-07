<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { RouterLink } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { isSupabaseConfigured, supabase, type MyCoupleRow } from '@/services/supabase'

const { locale, t } = useI18n()
const { initialized, isAuthenticated } = useSupabaseAuth()
const myCouples = ref<MyCoupleRow[]>([])
const loadingCouples = ref(false)
const homeError = ref<string | null>(null)
const isAdmin = ref(false)

function partnerCountLabel(accepted: string | number, total: string | number) {
  return `${accepted}/${total}`
}

async function loadAccountHome() {
  if (!supabase || !initialized.value || !isAuthenticated.value) {
    myCouples.value = []
    isAdmin.value = false
    return
  }

  loadingCouples.value = true
  homeError.value = null

  const { data: adminAccess, error: adminError } = await supabase.rpc('is_app_admin')
  if (adminError) {
    homeError.value = adminError.message
    isAdmin.value = false
  } else {
    isAdmin.value = Boolean(adminAccess)
  }

  const { data, error } = isAdmin.value
    ? await supabase.rpc('admin_list_tenants')
    : await supabase.rpc('list_my_couples')

  loadingCouples.value = false

  if (error) {
    homeError.value = error.message
    myCouples.value = []
    return
  }

  myCouples.value = (data ?? []) as MyCoupleRow[]
}

onMounted(() => void loadAccountHome())
watch([initialized, isAuthenticated], () => void loadAccountHome())
</script>

<template>
  <section class="mx-auto max-w-5xl space-y-8">
    <div class="space-y-4">
      <UBadge color="info" variant="soft">Multi tenant couple dashboards</UBadge>
      <h1 class="max-w-3xl text-4xl font-black leading-tight sm:text-6xl">
        CoupleDash
      </h1>
      <p class="max-w-2xl text-lg text-muted">
        Private couple dashboards are loaded only after a linked partner or app admin account signs in.
      </p>
    </div>

    <div class="space-y-4">
      <UAlert
        v-if="!isSupabaseConfigured"
        color="warning"
        variant="soft"
        :description="t('dashboard.supabaseRequired')"
      />

      <AuthPanel v-else-if="initialized && !isAuthenticated" />

      <template v-else-if="isAuthenticated">
        <UAlert v-if="homeError" color="warning" variant="soft" :description="homeError" />

        <section class="space-y-3">
          <div>
            <h2 class="text-2xl font-black">
              {{ isAdmin ? t('home.adminCouplesTitle') : t('home.accountTitle') }}
            </h2>
            <p class="text-sm text-muted">
              {{ isAdmin ? t('home.adminCouplesDescription') : t('home.accountDescription') }}
            </p>
          </div>

          <div v-if="myCouples.length" class="grid gap-4 md:grid-cols-2">
            <UCard
              v-for="couple in myCouples"
              :key="couple.couple_id"
              :as="RouterLink"
              :to="{ name: 'display', params: { coupleSlug: couple.slug } }"
              class="transition-transform hover:-translate-y-0.5"
            >
              <template #header>
                <div class="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <h3 class="text-2xl font-black">{{ couple.name }}</h3>
                    <p class="mt-1 text-sm font-normal text-muted">
                      {{ couple.subtitle || t('home.noSubtitle') }}
                    </p>
                  </div>
                  <UBadge color="success" variant="soft">{{ couple.slug }}</UBadge>
                </div>
              </template>

              <div class="grid gap-4">
                <div class="grid grid-cols-2 gap-3 text-sm">
                  <div class="rounded-md bg-muted p-3 ring ring-default">
                    <p class="text-muted">{{ t('home.wedding') }}</p>
                    <p class="font-bold">
                      {{ new Date(couple.wedding_date).toLocaleDateString(locale) }}
                    </p>
                  </div>
                  <div class="rounded-md bg-muted p-3 ring ring-default">
                    <p class="text-muted">{{ t('home.partners') }}</p>
                    <p class="font-bold">
                      {{ partnerCountLabel(couple.accepted_partner_count, couple.partner_count) }}
                    </p>
                  </div>
                </div>

                <div v-if="!isAdmin" class="flex flex-wrap gap-2">
                  <UButton
                    icon="i-lucide-monitor"
                    :label="t('home.openDisplay')"
                    :to="{ name: 'display', params: { coupleSlug: couple.slug } }"
                    @click.stop
                  />
                  <UButton
                    icon="i-lucide-pencil"
                    :label="t('home.editDashboard')"
                    variant="outline"
                    :to="{ name: 'edit', params: { coupleSlug: couple.slug } }"
                    @click.stop
                  />
                </div>
              </div>
            </UCard>
          </div>

          <UAlert
            v-else
            color="neutral"
            variant="soft"
            :description="
              loadingCouples
                ? t('home.loadingCouples')
                : isAdmin
                  ? t('home.noAdminCouples')
                  : t('home.noCouples')
            "
          />
        </section>
      </template>
    </div>
  </section>
</template>
