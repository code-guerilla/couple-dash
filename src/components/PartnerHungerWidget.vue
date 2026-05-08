<script setup lang="ts">
import { hungerLevelLabelForPartner, normalizeHungerLevelValue } from '@/data/hungerLevels'
import type { HungerLevelValue, Partner } from '@/types'

defineProps<{
  partners: (Partner | undefined)[]
}>()

const hungerIcons: Record<HungerLevelValue, string> = {
  'Absolut vollgefressen': 'i-lucide-utensils-crossed',
  'Kleiner Snack wär nice': 'i-lucide-cookie',
  'Alles normal': 'i-lucide-utensils',
  Hungrig: 'i-lucide-sandwich',
  'Richtig hungrig': 'i-lucide-pizza',
  'Am Verhungern': 'i-lucide-drumstick',
}

const hungerLevels: Record<HungerLevelValue, string> = {
  'Absolut vollgefressen': 'Satt',
  'Kleiner Snack wär nice': 'Snack',
  'Alles normal': 'Okay',
  Hungrig: 'Hunger',
  'Richtig hungrig': 'Heißhunger',
  'Am Verhungern': 'Notstand',
}

function partnerHungerStatus(partner?: Partner) {
  return partner ? hungerLevelLabelForPartner(partner) : 'Hunger offen'
}

function partnerHungerIcon(partner?: Partner) {
  return partner
    ? hungerIcons[normalizeHungerLevelValue(partner.hungerLevel)]
    : 'i-lucide-utensils'
}

function partnerHungerLevel(partner?: Partner) {
  return partner ? hungerLevels[normalizeHungerLevelValue(partner.hungerLevel)] : 'Offen'
}
</script>

<template>
  <UCard
    class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl md:col-span-2 xl:col-span-2"
    :ui="{ body: 'grid h-full gap-4 p-5 sm:p-6' }"
  >
    <div class="flex items-start justify-between gap-4">
      <div>
        <p class="mb-2 text-xs font-extrabold uppercase text-primary">Live Status</p>
        <h2 class="text-2xl font-black leading-none">Partner-Hunger</h2>
      </div>
      <span class="mt-2 h-3 w-3 animate-pulse rounded-full bg-primary shadow-lg shadow-primary/30" />
    </div>

    <div class="grid gap-3 sm:grid-cols-2">
      <article
        v-for="(partner, index) in partners"
        :key="partner?.id ?? `hunger-partner-${index}`"
        class="flex min-w-0 items-center gap-3 rounded-md border border-primary/15 bg-black/15 p-3"
      >
        <UAvatar
          :src="partner?.avatarUrl"
          :text="partner?.avatarUrl ? undefined : partner?.avatarFallback"
          :alt="partner?.name ?? `Partner ${index + 1}`"
          size="xl"
          class="ring-2 ring-primary/50"
          loading="lazy"
        />
        <div class="min-w-0">
          <h3 class="truncate text-xl font-black">
            {{ partner?.name ?? `Partner ${index + 1}` }}
          </h3>
          <div class="mt-2 flex flex-wrap items-center gap-2">
            <span
              class="inline-flex max-w-full rounded-full bg-primary/15 px-3 py-1 text-sm font-extrabold leading-tight text-primary shadow-[inset_0_0_0_1px_currentColor] ring-primary/35"
            >
              {{ partnerHungerStatus(partner) }}
            </span>
            <span
              class="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-extrabold uppercase text-primary ring-1 ring-primary/25"
              :aria-label="`Hunger: ${partnerHungerLevel(partner)}`"
            >
              <UIcon :name="partnerHungerIcon(partner)" class="size-5 text-primary" />
              {{ partnerHungerLevel(partner) }}
            </span>
          </div>
        </div>
      </article>
    </div>
  </UCard>
</template>
