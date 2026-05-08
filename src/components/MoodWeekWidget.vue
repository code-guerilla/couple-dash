<script setup lang="ts">
import { computed } from 'vue'

interface MoodEntry {
  label: string
  score: number
  emoji: string
}

const days: MoodEntry[] = [
  { label: 'Mo', score: 72, emoji: '🙂' },
  { label: 'Di', score: 58, emoji: '😐' },
  { label: 'Mi', score: 81, emoji: '😄' },
  { label: 'Do', score: 65, emoji: '🙂' },
  { label: 'Fr', score: 88, emoji: '🥰' },
  { label: 'Sa', score: 94, emoji: '😍' },
  { label: 'So', score: 92, emoji: '🥰' },
]

const average = computed(() => Math.round(days.reduce((sum, d) => sum + d.score, 0) / days.length))
const trend = computed(() => {
  const firstHalf = days.slice(0, 3).reduce((s, d) => s + d.score, 0) / 3
  const secondHalf = days.slice(-3).reduce((s, d) => s + d.score, 0) / 3
  const delta = Math.round(secondHalf - firstHalf)
  return delta
})
</script>

<template>
  <UCard
    class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl"
    :ui="{ body: 'flex h-full flex-col gap-4 p-5 sm:p-6' }"
  >
    <div class="flex items-start justify-between gap-3">
      <div>
        <p class="mb-2 text-xs font-extrabold uppercase text-primary">Stimmung diese Woche</p>
        <h2 class="text-2xl font-black leading-none">Mood-Verlauf</h2>
      </div>
      <div class="flex items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-extrabold uppercase text-primary ring-1 ring-primary/25">
        <UIcon
          :name="trend >= 0 ? 'i-lucide-trending-up' : 'i-lucide-trending-down'"
          class="size-4"
        />
        Ø {{ average }}%
      </div>
    </div>

    <div class="flex flex-1 items-end justify-between gap-1.5">
      <div
        v-for="day in days"
        :key="day.label"
        class="flex flex-1 flex-col items-center gap-1.5"
      >
        <span class="text-base leading-none">{{ day.emoji }}</span>
        <div class="flex h-20 w-full items-end overflow-hidden rounded-md bg-black/25">
          <div
            class="w-full rounded-md bg-gradient-to-t from-primary/80 to-primary shadow-[0_0_12px_rgba(34,197,94,0.35)]"
            :style="{ height: `${day.score}%` }"
          />
        </div>
        <span class="text-[10px] font-extrabold uppercase tracking-wide text-white/60">
          {{ day.label }}
        </span>
      </div>
    </div>
  </UCard>
</template>
