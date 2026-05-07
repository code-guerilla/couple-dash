<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import AlertFeed from '@/components/AlertFeed.vue'
import AuthPanel from '@/components/AuthPanel.vue'
import QrCodeCard from '@/components/QrCodeCard.vue'
import RelationshipTimelineWidget from '@/components/RelationshipTimelineWidget.vue'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { hungerLevelLabelForPartner } from '@/data/hungerLevels'
import type { Partner } from '@/types'

const route = useRoute()
const { locale, t } = useI18n()

const coupleSlug = computed(() => String(route.params.coupleSlug))
const { initialized, isAuthenticated, isSupabaseConfigured } = useSupabaseAuth()
const { couple, visibleWidgets, alerts, loading, error, loadCouple } = useDashboardStore(
  coupleSlug.value,
)
const now = ref(Date.now())
let clockInterval: number | undefined

const timelineWidget = computed(() =>
  visibleWidgets.value.find((widget) => widget.visual === 'timeline'),
)

const firstPartner = computed(() => couple.value?.partners[0])
const secondPartner = computed(() => couple.value?.partners[1])
const choreTurnPartner = computed(() =>
  couple.value?.partners.find((partner) => partner.id === couple.value?.choreTurnPartnerId),
)

const relationshipUptime = computed(() => {
  if (!couple.value) {
    return '0 Jahre 0 Tage 0 Std 0 Min'
  }

  const start = new Date(couple.value.relationshipStart)
  let seconds = Math.max(0, Math.floor((now.value - start.getTime()) / 1000))
  const years = Math.floor(seconds / 31_536_000)
  seconds %= 31_536_000
  const days = Math.floor(seconds / 86_400)
  seconds %= 86_400
  const hours = Math.floor(seconds / 3600)
  seconds %= 3600
  const minutes = Math.floor(seconds / 60)
  seconds %= 60

  return `${years} Jahre ${days} Tage ${hours} Std ${minutes} Min`
})

const weddingCountdown = computed(() => {
  if (!couple.value) {
    return {
      label: 'Seit dem Ja-Wort:',
      value: '0 Tage 0 Std 0 Min',
      date: '',
      isFuture: false,
    }
  }

  const wedding = new Date(couple.value.weddingDate)
  const diff = wedding.getTime() - now.value
  const absoluteMs = Math.abs(diff)
  const totalMinutes = Math.floor(absoluteMs / 60_000)
  const days = Math.floor(totalMinutes / 1_440)
  const hours = Math.floor((totalMinutes % 1_440) / 60)
  const minutes = totalMinutes % 60

  return {
    label: diff > 0 ? 'Zu dem Ja-Wort noch:' : 'Seit dem Ja-Wort:',
    value: `${days} Tage ${hours} Std ${minutes} Min`,
    date: wedding.toLocaleDateString(locale.value),
    isFuture: diff > 0,
  }
})

const statusColors: Record<string, string> = {
  'Voll motiviert - Lass uns Ausgehen': 'bg-primary/15 text-primary ring-primary/35',
  Kuschelbedürftig: 'bg-primary/15 text-primary ring-primary/35',
  Hangry: 'bg-primary/15 text-primary ring-primary/35',
  'Im Tunnel': 'bg-primary/15 text-primary ring-primary/35',
  'Pause benötigt - Sofazeit': 'bg-primary/15 text-primary ring-primary/35',
}

function statusClass(partner?: Partner) {
  return partner ? statusColors[partner.hungerLevel] : 'bg-primary/10 text-white/70 ring-primary/20'
}

function partnerStatus(partner?: Partner) {
  return partner ? hungerLevelLabelForPartner(partner) : 'Status offen'
}

async function loadDisplay() {
  if (!isSupabaseConfigured || !initialized.value || !isAuthenticated.value) {
    return
  }

  await loadCouple()
}

onMounted(() => {
  clockInterval = window.setInterval(() => {
    now.value = Date.now()
  }, 1000)
  void loadDisplay()
})
onUnmounted(() => {
  window.clearInterval(clockInterval)
})
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

  <section
    v-else-if="couple"
    class="min-h-[calc(100vh-4rem)] w-full p-4 text-white sm:p-6 lg:p-8"
  >
    <div
      class="relative grid min-h-[calc(100vh-8rem)] w-full grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-[minmax(0,1.25fr)_minmax(0,1.05fr)_minmax(18rem,0.9fr)_minmax(18rem,0.85fr)] xl:grid-rows-[minmax(12rem,auto)_minmax(15rem,auto)_minmax(15rem,1fr)_auto]"
    >
      <UCard
        class="overflow-hidden border-primary/20 bg-primary/[0.06] shadow-2xl shadow-primary/10 backdrop-blur-xl xl:col-span-2 xl:row-span-2"
        :ui="{ body: 'flex min-h-[23rem] flex-col justify-between gap-8 p-5 sm:p-7 lg:min-h-[25rem]' }"
      >
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div class="min-w-0">
            <p class="mb-2 text-xs font-extrabold uppercase text-primary">Private Couple Display</p>
            <h1 class="max-w-[14ch] text-5xl font-black leading-[0.9] sm:text-7xl xl:text-8xl">
              {{ couple.name }}
            </h1>
            <p class="mt-4 max-w-3xl text-base text-white/70 sm:text-xl">
              {{ couple.subtitle }}
            </p>
          </div>
          <div class="flex -space-x-3">
            <UAvatar
              :src="firstPartner?.avatarUrl"
              :text="firstPartner?.avatarUrl ? undefined : firstPartner?.avatarFallback"
              :alt="firstPartner?.name ?? 'Partner 1'"
              size="xl"
              class="ring-2 ring-primary/50"
              loading="lazy"
            />
            <UAvatar
              :src="secondPartner?.avatarUrl"
              :text="secondPartner?.avatarUrl ? undefined : secondPartner?.avatarFallback"
              :alt="secondPartner?.name ?? 'Partner 2'"
              size="xl"
              class="ring-2 ring-primary/50"
              loading="lazy"
            />
          </div>
        </div>

        <div class="grid gap-1 border-t border-primary/20 pt-4">
          <p class="text-white/60">Gemeinsame Erinnerungen</p>
          <strong class="text-3xl font-black leading-none sm:text-5xl">{{ relationshipUptime }}</strong>
          <span class="text-white/60">
            Seit {{ new Date(couple.relationshipStart).toLocaleDateString(locale) }}
          </span>
        </div>
      </UCard>

      <UCard
        class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl"
        :ui="{ body: 'flex h-full min-h-48 flex-col justify-between gap-6 p-5 sm:p-6' }"
      >
        <div>
          <p class="mb-2 text-xs font-extrabold uppercase text-primary">Seit dem Ja-Wort</p>
          <h2 class="text-2xl font-black leading-none">{{ weddingCountdown.label }}</h2>
        </div>
        <div class="text-4xl font-black leading-none text-primary sm:text-5xl xl:text-6xl">
          {{ weddingCountdown.value }}
        </div>
        <p class="text-white/60">{{ weddingCountdown.date }}</p>
      </UCard>

      <UCard
        class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl"
        :ui="{ body: 'h-full p-5 sm:p-6' }"
      >
        <p class="mb-2 text-xs font-extrabold uppercase text-primary">Wer ist dran?</p>
        <h2 class="text-2xl font-black leading-none">Wer macht den Kaffee?</h2>
        <div class="mt-6 flex items-center gap-4">
          <UAvatar
            :src="choreTurnPartner?.avatarUrl"
            :text="choreTurnPartner?.avatarUrl ? undefined : choreTurnPartner?.avatarFallback"
            :alt="choreTurnPartner?.name ?? 'Kein Partner ausgewählt'"
            size="3xl"
            class="ring-2 ring-primary/50"
            loading="lazy"
          />
          <div class="min-w-0">
            <p class="truncate text-3xl font-black leading-none">
              {{ choreTurnPartner?.name ?? 'Noch niemand' }}
            </p>
            <span class="text-white/60">Aktuelle Kaffee-Schicht</span>
          </div>
        </div>
      </UCard>

      <UCard
        class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl md:col-span-2"
        :ui="{ body: 'grid h-full gap-4 p-5 sm:p-6' }"
      >
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="mb-2 text-xs font-extrabold uppercase text-primary">Live Status</p>
            <h2 class="text-2xl font-black leading-none">Partner-Akku</h2>
          </div>
          <span class="mt-2 h-3 w-3 animate-pulse rounded-full bg-primary shadow-lg shadow-primary/30" />
        </div>

        <div class="grid gap-3 sm:grid-cols-2">
          <article class="flex min-w-0 items-center gap-3 rounded-md border border-primary/15 bg-black/15 p-3">
            <UAvatar
              :src="firstPartner?.avatarUrl"
              :text="firstPartner?.avatarUrl ? undefined : firstPartner?.avatarFallback"
              :alt="firstPartner?.name ?? 'Partner 1'"
              size="xl"
              class="ring-2 ring-primary/50"
              loading="lazy"
            />
            <div class="min-w-0">
              <h3 class="truncate text-xl font-black">{{ firstPartner?.name ?? 'Partner 1' }}</h3>
              <span
                :class="[
                  'mt-2 inline-flex max-w-full rounded-full px-3 py-1 text-sm font-extrabold leading-tight shadow-[inset_0_0_0_1px_currentColor]',
                  statusClass(firstPartner),
                ]"
              >
                {{ partnerStatus(firstPartner) }}
              </span>
            </div>
          </article>

          <article class="flex min-w-0 items-center gap-3 rounded-md border border-primary/15 bg-black/15 p-3">
            <UAvatar
              :src="secondPartner?.avatarUrl"
              :text="secondPartner?.avatarUrl ? undefined : secondPartner?.avatarFallback"
              :alt="secondPartner?.name ?? 'Partner 2'"
              size="xl"
              class="ring-2 ring-primary/50"
              loading="lazy"
            />
            <div class="min-w-0">
              <h3 class="truncate text-xl font-black">{{ secondPartner?.name ?? 'Partner 2' }}</h3>
              <span
                :class="[
                  'mt-2 inline-flex max-w-full rounded-full px-3 py-1 text-sm font-extrabold leading-tight shadow-[inset_0_0_0_1px_currentColor]',
                  statusClass(secondPartner),
                ]"
              >
                {{ partnerStatus(secondPartner) }}
              </span>
            </div>
          </article>
        </div>
      </UCard>

      <section
        class="min-w-0 xl:col-span-3 xl:row-span-2 [&_.text-muted]:!text-white/60 [&_.rounded-lg]:h-full [&_.rounded-lg]:border-primary/15 [&_.rounded-lg]:bg-white/[0.075] [&_.rounded-lg]:text-white [&_.rounded-lg]:shadow-2xl [&_.rounded-lg]:shadow-primary/10 [&_.rounded-lg]:backdrop-blur-xl [&_.rounded-xl]:h-full [&_.rounded-xl]:border-primary/15 [&_.rounded-xl]:bg-white/[0.075] [&_.rounded-xl]:text-white [&_.rounded-xl]:shadow-2xl [&_.rounded-xl]:shadow-primary/10 [&_.rounded-xl]:backdrop-blur-xl"
      >
        <RelationshipTimelineWidget v-if="timelineWidget" :widget="timelineWidget" />
        <UCard
          v-else
          class="h-full border-primary/15 bg-white/[0.075] text-white shadow-2xl shadow-primary/10 backdrop-blur-xl"
          :ui="{ body: 'grid h-full place-content-center gap-2 p-6 text-center' }"
        >
          <p class="text-xs font-extrabold uppercase text-primary">Timeline</p>
          <h2 class="text-2xl font-black">Unsere Meilensteine</h2>
          <p class="text-white/60">Die nächsten Erinnerungen warten schon.</p>
        </UCard>
      </section>

      <UCard
        class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl"
        :ui="{ body: 'grid h-full content-start gap-4 p-5 sm:p-6' }"
      >
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="mb-2 text-xs font-extrabold uppercase text-primary">Alerts</p>
            <h2 class="text-2xl font-black leading-none">Live Hinweise</h2>
          </div>
          <UBadge color="primary" variant="soft">{{ alerts.length }} aktiv</UBadge>
        </div>
        <div
          v-if="alerts.length"
          class="[&_.alert-strip-track]:grid [&_.alert-strip-track]:min-w-0 [&_.alert-strip-track]:animate-none [&_.alert-strip-track]:p-0 [&_.border-y]:border-0 [&_.border-y]:bg-transparent"
        >
          <AlertFeed :alerts="alerts" />
        </div>
        <div
          v-else
          class="grid min-h-28 place-content-center gap-1 rounded-md border border-dashed border-primary/20 bg-primary/5 text-center"
        >
          <strong>Alles ruhig.</strong>
          <span class="text-white/60">Keine aktiven Hinweise auf dem Display.</span>
        </div>
      </UCard>

      <section class="self-end [&_.rounded-lg]:rounded-md [&_.rounded-xl]:rounded-md">
        <QrCodeCard
          :label="t('dashboard.editLogin')"
          :person="t('edit.sharedDashboard')"
          :url="`/edit/${couple.slug}`"
        />
      </section>

      <div v-if="loading" class="pointer-events-none absolute inset-0 opacity-30">
        <USkeleton class="h-full min-h-40 rounded-md" />
      </div>
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
