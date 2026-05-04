<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AlertFeed from '@/components/AlertFeed.vue'
import MetricTile from '@/components/MetricTile.vue'
import QrCodeCard from '@/components/QrCodeCard.vue'
import RelationshipTimelineWidget from '@/components/RelationshipTimelineWidget.vue'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'

const route = useRoute()
const router = useRouter()
const { locale, t } = useI18n()
const coupleSlug = computed(() => String(route.params.coupleSlug))
const displayToken = ref(String(route.query.token ?? ''))
const claimError = ref<string | null>(null)
const claiming = ref(false)
const { ensureAnonymousSession, isSupabaseConfigured } = useSupabaseAuth()
const { couple, visibleWidgets, alerts, loading, error, loadCouple } = useDashboardStore(
  coupleSlug.value,
)

const sharedWidgets = computed(() =>
  visibleWidgets.value.filter((widget) => widget.scope === 'shared' && widget.visual !== 'timeline'),
)
const timelineWidgets = computed(() =>
  visibleWidgets.value.filter((widget) => widget.visual === 'timeline'),
)
const personWidgets = computed(() =>
  visibleWidgets.value.filter((widget) => widget.scope === 'person'),
)

const daysUntilWedding = computed(() => {
  if (!couple.value) {
    return 0
  }

  const today = new Date()
  const wedding = new Date(couple.value.weddingDate)
  return Math.max(0, Math.ceil((wedding.getTime() - today.getTime()) / 86_400_000))
})

const relationshipUptime = computed(() => {
  if (!couple.value) {
    return '0d'
  }

  const start = new Date(couple.value.relationshipStart)
  const days = Math.max(0, Math.floor((Date.now() - start.getTime()) / 86_400_000))
  const years = Math.floor(days / 365)
  const restDays = days % 365
  return `${years}y ${restDays}d`
})

function partnerName(personId?: string) {
  return couple.value?.partners.find((partner) => partner.id === personId)?.name
}

async function claimDisplay() {
  claimError.value = null

  if (!isSupabaseConfigured || !supabase) {
    await loadCouple()
    return
  }

  if (!displayToken.value) {
    claimError.value = t('dashboard.missingToken')
    return
  }

  claiming.value = true
  await ensureAnonymousSession()
  const { error: claimDisplayError } = await supabase.rpc('claim_display_device', {
    p_slug: coupleSlug.value,
    p_display_token: displayToken.value,
  })
  claiming.value = false

  if (claimDisplayError) {
    claimError.value = claimDisplayError.message
    return
  }

  displayToken.value = ''
  await router.replace({ name: 'display', params: { coupleSlug: coupleSlug.value } })
  await loadCouple()
}

onMounted(async () => {
  if (!isSupabaseConfigured) {
    await loadCouple()
    return
  }

  await ensureAnonymousSession()

  if (displayToken.value) {
    await claimDisplay()
    return
  }

  await loadCouple()
})
</script>

<template>
  <section v-if="couple" class="relative space-y-8 pb-36 xl:pb-0">
    <div class="grid gap-4 xl:grid-cols-[1fr_21rem]">
      <UCard :ui="{ body: 'p-6 sm:p-10' }">
        <div class="w-full justify-start">
          <div class="max-w-4xl">
            <div class="mb-5 flex flex-wrap gap-2">
              <UBadge color="success" variant="soft">{{ t('dashboard.privateSession') }}</UBadge>
              <UBadge color="neutral" variant="soft">
                {{
                  isSupabaseConfigured ? t('dashboard.protectedRealtime') : t('dashboard.localDemo')
                }}
              </UBadge>
            </div>
            <h1 class="text-5xl font-black leading-none sm:text-7xl">{{ couple.name }}</h1>
            <p class="mt-4 max-w-2xl text-lg text-muted">{{ couple.subtitle }}</p>

            <div
              class="mt-8 grid overflow-hidden rounded-md border border-default bg-default shadow-sm sm:grid-cols-3"
            >
              <div
                class="border-t border-default p-5 first:border-t-0 sm:border-l sm:border-t-0 sm:first:border-l-0"
              >
                <div class="text-sm text-muted">{{ t('dashboard.relationshipUptime') }}</div>
                <div class="mt-1 text-4xl font-black leading-none text-green-500 sm:text-5xl">
                  {{ relationshipUptime }}
                </div>
                <div class="mt-1 text-sm text-muted">
                  {{
                    t('dashboard.since', {
                      date: new Date(couple.relationshipStart).toLocaleDateString(locale),
                    })
                  }}
                </div>
              </div>
              <div
                class="border-t border-default p-5 first:border-t-0 sm:border-l sm:border-t-0 sm:first:border-l-0"
              >
                <div class="text-sm text-muted">{{ t('dashboard.daysUntilWedding') }}</div>
                <div class="mt-1 text-4xl font-black leading-none text-primary-500 sm:text-5xl">
                  {{ daysUntilWedding }}
                </div>
                <div class="mt-1 text-sm text-muted">
                  {{ new Date(couple.weddingDate).toLocaleDateString(locale) }}
                </div>
              </div>
              <div
                class="border-t border-default p-5 first:border-t-0 sm:border-l sm:border-t-0 sm:first:border-l-0"
              >
                <div class="text-sm text-muted">{{ t('dashboard.commitmentLevel') }}</div>
                <div class="mt-1 text-4xl font-black leading-none text-primary-400 sm:text-5xl">
                  100%
                </div>
                <div class="mt-1 text-sm text-muted">{{ t('dashboard.noRollback') }}</div>
              </div>
            </div>
          </div>
        </div>
      </UCard>

      <AlertFeed :alerts="alerts" />
    </div>

    <div v-if="loading" class="grid gap-4 md:grid-cols-3">
      <USkeleton v-for="item in 6" :key="item" class="h-44" />
    </div>

    <section v-if="timelineWidgets.length" class="grid gap-4 xl:grid-cols-2">
      <RelationshipTimelineWidget
        v-for="widget in timelineWidgets"
        :key="widget.id"
        :widget="widget"
      />
    </section>

    <section class="space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-black">{{ t('dashboard.coreMetrics') }}</h2>
        <UBadge color="info" variant="soft">
          {{ t('dashboard.visible', { count: sharedWidgets.length }) }}
        </UBadge>
      </div>
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <MetricTile v-for="widget in sharedWidgets" :key="widget.id" :widget="widget" />
      </div>
    </section>

    <section class="space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-black">{{ t('dashboard.personMetrics') }}</h2>
        <UBadge color="neutral" variant="soft">
          {{ t('dashboard.visible', { count: personWidgets.length }) }}
        </UBadge>
      </div>
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <MetricTile
          v-for="widget in personWidgets"
          :key="widget.id"
          :owner-name="partnerName(widget.personId)"
          :widget="widget"
        />
      </div>
    </section>

    <div class="grid gap-4 sm:grid-cols-2 xl:hidden">
      <QrCodeCard
        v-for="partner in couple.partners"
        :key="partner.id"
        :label="t('dashboard.editLogin', { name: partner.name })"
        :person="partner.name"
        :url="`/edit/${couple.slug}`"
      />
    </div>

    <div class="pointer-events-none fixed inset-x-4 bottom-4 z-10 hidden justify-between xl:flex">
      <QrCodeCard
        v-for="partner in couple.partners"
        :key="partner.id"
        class="pointer-events-auto"
        :label="t('dashboard.editLogin', { name: partner.name })"
        :person="partner.name"
        :url="`/edit/${couple.slug}`"
      />
    </div>
  </section>

  <section v-else class="mx-auto max-w-xl space-y-4">
    <UCard>
      <form class="grid gap-4" @submit.prevent="claimDisplay">
        <div>
          <h1 class="text-2xl font-black">{{ t('dashboard.claimTitle') }}</h1>
          <p class="text-sm text-muted">
            {{ t('dashboard.claimDescription') }}
          </p>
        </div>

        <UAlert
          v-if="error || claimError"
          color="warning"
          variant="soft"
          :description="claimError ?? error ?? ''"
        />

        <UFormField :label="t('dashboard.tokenLabel')" required>
          <UInput
            v-model="displayToken"
            autocomplete="off"
            class="w-full"
            :placeholder="t('dashboard.tokenPlaceholder')"
            type="password"
          />
        </UFormField>
        <UButton :label="t('dashboard.claimButton')" :loading="claiming" type="submit" />
      </form>
    </UCard>
  </section>
</template>
