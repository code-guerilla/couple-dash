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
  'Voll motiviert - Lass uns Ausgehen': 'bg-emerald-500/15 text-emerald-300 ring-emerald-400/30',
  Kuschelbedürftig: 'bg-rose-500/15 text-rose-200 ring-rose-300/30',
  Hangry: 'bg-amber-500/15 text-amber-200 ring-amber-300/30',
  'Im Tunnel': 'bg-cyan-500/15 text-cyan-200 ring-cyan-300/30',
  'Pause benötigt - Sofazeit': 'bg-violet-500/15 text-violet-200 ring-violet-300/30',
}

function statusClass(partner?: Partner) {
  return partner ? statusColors[partner.hungerLevel] : 'bg-white/10 text-white/70 ring-white/15'
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
    class="-mx-4 -mb-16 -mt-8 min-h-[calc(100vh-5rem)] bg-[radial-gradient(circle_at_12%_15%,rgb(20_184_166_/_0.2),transparent_30rem),radial-gradient(circle_at_88%_18%,rgb(244_63_94_/_0.16),transparent_32rem),linear-gradient(135deg,#10151d_0%,#171a22_46%,#0d1417_100%)] p-4 text-white sm:-mx-6 sm:-mt-10 sm:p-6 lg:-mx-8 lg:p-8"
  >
    <div
      class="relative grid min-h-[calc(100vh-10rem)] grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-[minmax(0,1.15fr)_minmax(0,1fr)_minmax(18rem,0.9fr)_minmax(18rem,0.85fr)] xl:grid-rows-[minmax(12rem,auto)_minmax(15rem,auto)_minmax(15rem,1fr)_auto]"
    >
      <UCard
        class="overflow-hidden border-white/15 bg-white/[0.075] shadow-2xl backdrop-blur-xl xl:col-span-2 xl:row-span-2"
        :ui="{ body: 'flex min-h-[23rem] flex-col justify-between gap-8 p-5 sm:p-7 lg:min-h-[25rem]' }"
      >
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div class="min-w-0">
            <p class="mb-2 text-xs font-extrabold uppercase text-white/60">Private Couple Display</p>
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
              class="shadow-[0_0_0_2px_rgb(255_255_255_/_0.18)]"
              loading="lazy"
            />
            <UAvatar
              :src="secondPartner?.avatarUrl"
              :text="secondPartner?.avatarUrl ? undefined : secondPartner?.avatarFallback"
              :alt="secondPartner?.name ?? 'Partner 2'"
              size="xl"
              class="shadow-[0_0_0_2px_rgb(255_255_255_/_0.18)]"
              loading="lazy"
            />
          </div>
        </div>

        <div class="grid gap-1 border-t border-white/15 pt-4">
          <p class="text-white/60">Gemeinsame Erinnerungen</p>
          <strong class="text-3xl font-black leading-none sm:text-5xl">{{ relationshipUptime }}</strong>
          <span class="text-white/60">
            Seit {{ new Date(couple.relationshipStart).toLocaleDateString(locale) }}
          </span>
        </div>
      </UCard>

      <UCard
        class="border-white/15 bg-white/[0.075] shadow-2xl backdrop-blur-xl"
        :ui="{ body: 'flex h-full min-h-48 flex-col justify-between gap-6 p-5 sm:p-6' }"
      >
        <div>
          <p class="mb-2 text-xs font-extrabold uppercase text-white/60">Seit dem Ja-Wort</p>
          <h2 class="text-2xl font-black leading-none">{{ weddingCountdown.label }}</h2>
        </div>
        <div
          :class="[
            'text-4xl font-black leading-none sm:text-5xl xl:text-6xl',
            weddingCountdown.isFuture ? 'text-rose-300' : 'text-teal-300',
          ]"
        >
          {{ weddingCountdown.value }}
        </div>
        <p class="text-white/60">{{ weddingCountdown.date }}</p>
      </UCard>

      <UCard
        class="border-white/15 bg-white/[0.075] shadow-2xl backdrop-blur-xl"
        :ui="{ body: 'h-full p-5 sm:p-6' }"
      >
        <p class="mb-2 text-xs font-extrabold uppercase text-white/60">Wer ist dran?</p>
        <h2 class="text-2xl font-black leading-none">Wer macht den Kaffee?</h2>
        <div class="mt-6 flex items-center gap-4">
          <UAvatar
            :src="choreTurnPartner?.avatarUrl"
            :text="choreTurnPartner?.avatarUrl ? undefined : choreTurnPartner?.avatarFallback"
            :alt="choreTurnPartner?.name ?? 'Kein Partner ausgewählt'"
            size="3xl"
            class="shadow-[0_0_0_2px_rgb(255_255_255_/_0.18)]"
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
        class="border-white/15 bg-white/[0.075] shadow-2xl backdrop-blur-xl md:col-span-2"
        :ui="{ body: 'grid h-full gap-4 p-5 sm:p-6' }"
      >
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="mb-2 text-xs font-extrabold uppercase text-white/60">Live Status</p>
            <h2 class="text-2xl font-black leading-none">Partner-Akku</h2>
          </div>
          <span class="mt-2 h-3 w-3 rounded-full bg-teal-300 shadow-[0_0_0_6px_rgb(94_234_212_/_0.16)] animate-pulse" />
        </div>

        <div class="grid gap-3 sm:grid-cols-2">
          <article class="flex min-w-0 items-center gap-3 rounded-md border border-white/10 bg-black/15 p-3">
            <UAvatar
              :src="firstPartner?.avatarUrl"
              :text="firstPartner?.avatarUrl ? undefined : firstPartner?.avatarFallback"
              :alt="firstPartner?.name ?? 'Partner 1'"
              size="xl"
              class="shadow-[0_0_0_2px_rgb(255_255_255_/_0.18)]"
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

          <article class="flex min-w-0 items-center gap-3 rounded-md border border-white/10 bg-black/15 p-3">
            <UAvatar
              :src="secondPartner?.avatarUrl"
              :text="secondPartner?.avatarUrl ? undefined : secondPartner?.avatarFallback"
              :alt="secondPartner?.name ?? 'Partner 2'"
              size="xl"
              class="shadow-[0_0_0_2px_rgb(255_255_255_/_0.18)]"
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
        class="min-w-0 xl:col-span-3 xl:row-span-2 [&_.text-muted]:!text-white/60 [&_.rounded-lg]:h-full [&_.rounded-lg]:border-white/15 [&_.rounded-lg]:bg-white/[0.075] [&_.rounded-lg]:text-white [&_.rounded-lg]:shadow-2xl [&_.rounded-lg]:backdrop-blur-xl [&_.rounded-xl]:h-full [&_.rounded-xl]:border-white/15 [&_.rounded-xl]:bg-white/[0.075] [&_.rounded-xl]:text-white [&_.rounded-xl]:shadow-2xl [&_.rounded-xl]:backdrop-blur-xl"
      >
        <RelationshipTimelineWidget v-if="timelineWidget" :widget="timelineWidget" />
        <UCard
          v-else
          class="h-full border-white/15 bg-white/[0.075] text-white shadow-2xl backdrop-blur-xl"
          :ui="{ body: 'grid h-full place-content-center gap-2 p-6 text-center' }"
        >
          <p class="text-xs font-extrabold uppercase text-white/60">Timeline</p>
          <h2 class="text-2xl font-black">Unsere Meilensteine</h2>
          <p class="text-white/60">Die nächsten Erinnerungen warten schon.</p>
        </UCard>
      </section>

      <UCard
        class="border-white/15 bg-white/[0.075] shadow-2xl backdrop-blur-xl"
        :ui="{ body: 'grid h-full content-start gap-4 p-5 sm:p-6' }"
      >
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="mb-2 text-xs font-extrabold uppercase text-white/60">Alerts</p>
            <h2 class="text-2xl font-black leading-none">Live Hinweise</h2>
          </div>
          <UBadge color="warning" variant="soft">{{ alerts.length }} aktiv</UBadge>
        </div>
        <div
          v-if="alerts.length"
          class="[&_.alert-strip-track]:grid [&_.alert-strip-track]:min-w-0 [&_.alert-strip-track]:animate-none [&_.alert-strip-track]:p-0 [&_.border-y]:border-0 [&_.border-y]:bg-transparent"
        >
          <AlertFeed :alerts="alerts" />
        </div>
        <div
          v-else
          class="grid min-h-28 place-content-center gap-1 rounded-md border border-dashed border-white/15 bg-black/10 text-center"
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
