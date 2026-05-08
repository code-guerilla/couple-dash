<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    score?: number
    label?: string
    detail?: string
  }>(),
  {
    score: 92,
    label: 'Heute besonders harmonisch',
    detail: 'Stimmung, Akku & Aufgabenbalance im Einklang.',
  },
)

const circumference = 2 * Math.PI * 42
const dashOffset = computed(() => circumference - (props.score / 100) * circumference)
</script>

<template>
  <UCard
    class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl"
    :ui="{ body: 'flex h-full flex-col gap-4 p-5 sm:p-6' }"
  >
    <div class="flex items-start justify-between gap-3">
      <div>
        <p class="mb-2 text-xs font-extrabold uppercase text-primary">Daily Lovescore</p>
        <h2 class="text-2xl font-black leading-none">{{ label }}</h2>
      </div>
      <UIcon name="i-lucide-heart-pulse" class="mt-1 size-7 text-primary" />
    </div>

    <div class="flex flex-1 items-center gap-5">
      <div class="relative grid size-28 shrink-0 place-items-center sm:size-32">
        <svg viewBox="0 0 100 100" class="size-full -rotate-90">
          <circle
            cx="50"
            cy="50"
            r="42"
            stroke="currentColor"
            stroke-width="8"
            fill="none"
            class="text-white/10"
          />
          <circle
            cx="50"
            cy="50"
            r="42"
            stroke="currentColor"
            stroke-width="8"
            fill="none"
            stroke-linecap="round"
            class="text-primary drop-shadow-[0_0_6px_rgba(34,197,94,0.45)] transition-[stroke-dashoffset] duration-700"
            :stroke-dasharray="circumference"
            :stroke-dashoffset="dashOffset"
          />
        </svg>
        <div class="absolute inset-0 grid place-items-center">
          <span class="text-3xl font-black leading-none text-primary sm:text-4xl">
            {{ score }}<span class="text-base text-white/60">%</span>
          </span>
        </div>
      </div>

      <p class="min-w-0 text-sm text-white/70">{{ detail }}</p>
    </div>
  </UCard>
</template>
