<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import AlertFeed from '@/components/AlertFeed.vue'
import AuthPanel from '@/components/AuthPanel.vue'
import MetricTile from '@/components/MetricTile.vue'
import QrCodeCard from '@/components/QrCodeCard.vue'
import RelationshipTimelineWidget from '@/components/RelationshipTimelineWidget.vue'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'

const route = useRoute()
const { locale, t } = useI18n()
const coupleSlug = computed(() => String(route.params.coupleSlug))
const { initialized, isAuthenticated, isSupabaseConfigured } = useSupabaseAuth()
const { couple, visibleWidgets, alerts, loading, error, loadCouple } = useDashboardStore(
  coupleSlug.value,
)

const sharedWidgets = computed(() =>
  visibleWidgets.value.filter((widget) => widget.visual !== 'timeline'),
)
const timelineWidgets = computed(() =>
  visibleWidgets.value.filter((widget) => widget.visual === 'timeline'),
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

async function loadDisplay() {
  if (!isSupabaseConfigured || !initialized.value || !isAuthenticated.value) {
    return
  }

  await loadCouple()
}

onMounted(() => void loadDisplay())
watch([initialized, isAuthenticated], () => void loadDisplay())
</script>

<template>
  <section v-if="isSupabaseConfigured && initialized && !isAuthenticated" class="mx-auto max-w-md">
    <AuthPanel />
  </section>

  <section v-else-if="!isSupabaseConfigured" class="mx-auto max-w-xl space-y-4">
    <UCard>
      <UAlert color="warning" variant="soft" :description="t('dashboard.supabaseRequired')" />
    </UCard>
  </section>

  <section v-else-if="couple" class="relative space-y-8 pb-36 xl:pb-0">
    <AlertFeed
      class="relative left-1/2 -mt-8 w-screen -translate-x-1/2 sm:-mt-10"
      :alerts="alerts"
    />

    <div class="grid gap-4">
      <UCard :ui="{ body: 'p-6 sm:p-10' }">
        <div class="w-full justify-start">
          <div class="max-w-4xl">
            <div class="mb-5 flex flex-wrap gap-2">
              <UBadge color="success" variant="soft">{{ t('dashboard.privateSession') }}</UBadge>
              <UBadge color="neutral" variant="soft">{{ t('dashboard.protectedRealtime') }}</UBadge>
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

    <div class="grid gap-4 sm:grid-cols-2 xl:hidden">
      <QrCodeCard
        :label="t('dashboard.editLogin')"
        :person="t('edit.sharedDashboard')"
        :url="`/edit/${couple.slug}`"
      />
    </div>

    <div class="pointer-events-none fixed inset-x-4 bottom-4 z-10 hidden justify-end xl:flex">
      <QrCodeCard
        class="pointer-events-auto"
        :label="t('dashboard.editLogin')"
        :person="t('edit.sharedDashboard')"
        :url="`/edit/${couple.slug}`"
      />
    </div>
  </section>

  <section v-else class="mx-auto max-w-xl space-y-4">
    <UCard>
      <div class="grid gap-4">
        <div>
          <h1 class="text-2xl font-black">{{ t('dashboard.claimTitle') }}</h1>
          <p class="text-sm text-muted">{{ t('dashboard.claimDescription') }}</p>
        </div>
        <UAlert color="warning" variant="soft" :description="error ?? t('dashboard.unavailable')" />
      </div>
    </UCard>
  </section>
</template>
