<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import AlertFeed from '@/components/AlertFeed.vue'
import AuthPanel from '@/components/AuthPanel.vue'
import PartnerHungerWidget from '@/components/PartnerHungerWidget.vue'
import QrCodeCard from '@/components/QrCodeCard.vue'
import RelationshipTimelineWidget from '@/components/RelationshipTimelineWidget.vue'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { batteryLevelLabelForPartner, normalizeBatteryLevelValue } from '@/data/batteryLevels'
import type { BatteryLevelValue, Partner } from '@/types'

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
const alternateChorePartner = computed(() =>
  couple.value?.partners.find((partner) => partner.id !== couple.value?.choreTurnPartnerId),
)
const isRightPartnerTurn = computed(
  () => !!secondPartner.value && choreTurnPartner.value?.id === secondPartner.value.id,
)

const choreQuestions = computed(() => [
  {
    id: 'lotte',
    question: 'Wer geht mit dem Hund Lotte?',
    icon: 'i-lucide-dog',
    partner: choreTurnPartner.value,
  },
  {
    id: 'cooking',
    question: 'Wer ist mit Kochen dran?',
    icon: 'i-lucide-cooking-pot',
    partner: alternateChorePartner.value ?? choreTurnPartner.value,
  },
  {
    id: 'bathroom',
    question: 'Wer macht das Bad sauber?',
    icon: 'i-lucide-bath',
    partner: choreTurnPartner.value,
  },
  {
    id: 'trash',
    question: 'Wer bringt den Müll raus?',
    icon: 'i-lucide-trash-2',
    partner: alternateChorePartner.value ?? choreTurnPartner.value,
  },
])

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

const statusColors: Record<BatteryLevelValue, string> = {
  'Absolut ausgelaugt - alles absagen': 'bg-primary/15 text-primary ring-primary/35',
  'Pause benötigt - Sofazeit': 'bg-primary/15 text-primary ring-primary/35',
  'Kleiner Spaziergang wär super': 'bg-primary/15 text-primary ring-primary/35',
  'Voll geladen und motiviert - Lass uns was starten': 'bg-primary/15 text-primary ring-primary/35',
}

const batteryIcons: Record<BatteryLevelValue, string> = {
  'Absolut ausgelaugt - alles absagen': 'i-lucide-battery',
  'Pause benötigt - Sofazeit': 'i-lucide-battery',
  'Kleiner Spaziergang wär super': 'i-lucide-battery-medium',
  'Voll geladen und motiviert - Lass uns was starten': 'i-lucide-battery-full',
}

const batteryLevels: Record<BatteryLevelValue, string> = {
  'Absolut ausgelaugt - alles absagen': 'Leer',
  'Pause benötigt - Sofazeit': 'Niedrig',
  'Kleiner Spaziergang wär super': 'Mittel',
  'Voll geladen und motiviert - Lass uns was starten': 'Voll',
}

function statusClass(partner?: Partner) {
  return partner
    ? statusColors[normalizeBatteryLevelValue(partner.batteryLevel)]
    : 'bg-primary/10 text-white/70 ring-primary/20'
}

function partnerStatus(partner?: Partner) {
  return partner ? batteryLevelLabelForPartner(partner) : 'Status offen'
}

function partnerBatteryIcon(partner?: Partner) {
  return partner
    ? batteryIcons[normalizeBatteryLevelValue(partner.batteryLevel)]
    : 'i-lucide-battery'
}

function partnerBatteryLevel(partner?: Partner) {
  return partner ? batteryLevels[normalizeBatteryLevelValue(partner.batteryLevel)] : 'Offen'
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
    class="min-h-[calc(100vh-4rem)] w-full space-y-4 p-4 text-white sm:p-6 lg:p-8"
  >
    <div
      v-if="alerts.length"
      class="-mx-4 sm:-mx-6 lg:-mx-8 [&_.border-y]:border-primary/20 [&_.border-y]:bg-primary/[0.08]"
    >
      <AlertFeed :alerts="alerts" />
    </div>

    <div
      class="relative grid min-h-[calc(100vh-10rem)] w-full grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-[minmax(0,1.25fr)_minmax(0,1.05fr)_minmax(18rem,0.9fr)_minmax(18rem,0.85fr)] xl:grid-rows-[minmax(12rem,auto)_minmax(15rem,auto)_minmax(15rem,1fr)_auto]"
    >
      <UCard
        class="overflow-hidden border-primary/20 bg-primary/[0.06] shadow-2xl shadow-primary/10 backdrop-blur-xl xl:col-span-2 xl:row-span-2"
        :ui="{
          body: 'flex min-h-[23rem] flex-col justify-between gap-8 p-5 sm:p-7 lg:min-h-[25rem]',
        }"
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
          <strong class="text-3xl font-black leading-none sm:text-5xl">{{
            relationshipUptime
          }}</strong>
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
        <div class="flex items-start justify-between gap-3">
          <div>
            <p class="mb-2 text-xs font-extrabold uppercase text-primary">Wer macht den Kaffee?</p>
            <h2 class="text-2xl font-black leading-none">Wer ist dran?</h2>
          </div>
          <UIcon name="i-lucide-coffee" class="mt-1 size-7 text-primary" />
        </div>

        <div class="mt-5 grid grid-cols-[minmax(0,1fr)_3.5rem_minmax(0,1fr)] items-center gap-2">
          <article
            v-for="(partner, index) in [firstPartner, secondPartner]"
            :key="partner?.id ?? `missing-partner-${index}`"
            :class="[
              'relative grid min-h-36 min-w-0 place-items-center gap-2 rounded-md border p-3 text-center transition',
              partner?.id === choreTurnPartner?.id
                ? 'border-primary/60 bg-primary/20 shadow-lg shadow-primary/15'
                : 'border-primary/15 bg-black/15 opacity-70',
            ]"
          >
            <UIcon
              v-if="partner?.id === choreTurnPartner?.id"
              name="i-lucide-crown"
              class="absolute right-2 top-2 size-5 text-primary"
            />
            <UAvatar
              :src="partner?.avatarUrl"
              :text="partner?.avatarUrl ? undefined : partner?.avatarFallback"
              :alt="partner?.name ?? 'Partner'"
              size="xl"
              :class="[
                'ring-2',
                partner?.id === choreTurnPartner?.id ? 'ring-primary/70' : 'ring-white/15',
              ]"
              loading="lazy"
            />
            <div class="min-w-0">
              <p class="truncate text-lg font-black leading-tight">
                {{ partner?.name ?? 'Offen' }}
              </p>
              <p
                :class="[
                  'text-xs font-extrabold uppercase',
                  partner?.id === choreTurnPartner?.id ? 'text-primary' : 'text-white/45',
                ]"
              >
                {{ partner?.id === choreTurnPartner?.id ? 'Dran' : 'Pause' }}
              </p>
            </div>
          </article>

          <div class="grid place-items-center">
            <div
              class="grid size-12 place-items-center rounded-full border border-primary/35 bg-black/25 shadow-inner shadow-primary/10"
              aria-hidden="true"
            >
              <UIcon name="i-lucide-repeat-2" class="size-6 text-primary" />
            </div>
          </div>
        </div>

        <div class="mt-5 grid gap-2">
          <article
            v-for="item in choreQuestions"
            :key="item.id"
            class="grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 rounded-md border border-primary/15 bg-black/15 px-3 py-2"
          >
            <UIcon :name="item.icon" class="size-5 text-primary" />
            <p class="min-w-0 truncate text-sm font-semibold text-white/75">{{ item.question }}</p>
            <div class="flex min-w-0 items-center gap-1.5">
              <UIcon name="i-lucide-crown" class="size-4 text-primary" />
              <span class="max-w-24 truncate text-sm font-black text-white">
                {{ item.partner?.name ?? 'Offen' }}
              </span>
            </div>
          </article>
        </div>

        <div
          class="mt-5 grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-3 rounded-md border border-primary/15 bg-black/15 px-3 py-3"
        >
          <div
            :class="[
              'flex min-w-0 items-center justify-end gap-1.5 text-sm font-black',
              !isRightPartnerTurn && choreTurnPartner ? 'text-primary' : 'text-white/45',
            ]"
          >
            <span class="truncate">{{ firstPartner?.name ?? 'Links' }}</span>
            <UIcon
              v-if="!isRightPartnerTurn && choreTurnPartner"
              name="i-lucide-crown"
              class="size-4 shrink-0"
            />
          </div>
          <USwitch
            :model-value="isRightPartnerTurn"
            disabled
            checked-icon="i-lucide-arrow-right"
            unchecked-icon="i-lucide-arrow-left"
            size="xl"
            :aria-label="`Gewinner: ${choreTurnPartner?.name ?? 'offen'}`"
          />
          <div
            :class="[
              'flex min-w-0 items-center gap-1.5 text-sm font-black',
              isRightPartnerTurn && choreTurnPartner ? 'text-primary' : 'text-white/45',
            ]"
          >
            <UIcon
              v-if="isRightPartnerTurn && choreTurnPartner"
              name="i-lucide-crown"
              class="size-4 shrink-0"
            />
            <span class="truncate">{{ secondPartner?.name ?? 'Rechts' }}</span>
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
          <span
            class="mt-2 h-3 w-3 animate-pulse rounded-full bg-primary shadow-lg shadow-primary/30"
          />
        </div>

        <div class="grid gap-3 sm:grid-cols-2">
          <article
            class="flex min-w-0 items-center gap-3 rounded-md border border-primary/15 bg-black/15 p-3"
          >
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
              <div class="mt-2 flex flex-wrap items-center gap-2">
                <span
                  :class="[
                    'inline-flex max-w-full rounded-full px-3 py-1 text-sm font-extrabold leading-tight shadow-[inset_0_0_0_1px_currentColor]',
                    statusClass(firstPartner),
                  ]"
                >
                  {{ partnerStatus(firstPartner) }}
                </span>
                <span
                  class="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-extrabold uppercase text-primary ring-1 ring-primary/25"
                  :aria-label="`Akku: ${partnerBatteryLevel(firstPartner)}`"
                >
                  <UIcon :name="partnerBatteryIcon(firstPartner)" class="size-5 text-primary" />
                  {{ partnerBatteryLevel(firstPartner) }}
                </span>
              </div>
            </div>
          </article>

          <article
            class="flex min-w-0 items-center gap-3 rounded-md border border-primary/15 bg-black/15 p-3"
          >
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
              <div class="mt-2 flex flex-wrap items-center gap-2">
                <span
                  :class="[
                    'inline-flex max-w-full rounded-full px-3 py-1 text-sm font-extrabold leading-tight shadow-[inset_0_0_0_1px_currentColor]',
                    statusClass(secondPartner),
                  ]"
                >
                  {{ partnerStatus(secondPartner) }}
                </span>
                <span
                  class="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-extrabold uppercase text-primary ring-1 ring-primary/25"
                  :aria-label="`Akku: ${partnerBatteryLevel(secondPartner)}`"
                >
                  <UIcon :name="partnerBatteryIcon(secondPartner)" class="size-5 text-primary" />
                  {{ partnerBatteryLevel(secondPartner) }}
                </span>
              </div>
            </div>
          </article>
        </div>
      </UCard>

      <PartnerHungerWidget :partners="[firstPartner, secondPartner]" />

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
