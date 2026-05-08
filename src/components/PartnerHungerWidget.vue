<script setup lang="ts">
import { hungerLevelLabelForPartner } from '@/data/hungerLevels'
import type { Partner } from '@/types'

defineProps<{
  partners: (Partner | undefined)[]
}>()

function partnerHungerLabel(partner?: Partner) {
  return partner ? hungerLevelLabelForPartner(partner) : 'Hunger offen'
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
          <p class="mt-2 text-sm font-extrabold text-primary">
            {{ partnerHungerLabel(partner) }}
          </p>
        </div>
      </article>
    </div>
  </UCard>
</template>
