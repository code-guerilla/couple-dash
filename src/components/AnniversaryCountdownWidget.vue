<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    weddingDate?: string
    now: number
  }>(),
  {
    weddingDate: '',
  },
)

const target = computed(() => {
  if (!props.weddingDate) return null
  const wedding = new Date(props.weddingDate)
  if (Number.isNaN(wedding.getTime())) return null
  const today = new Date(props.now)
  const next = new Date(today.getFullYear(), wedding.getMonth(), wedding.getDate())
  if (next.getTime() <= today.getTime()) {
    next.setFullYear(today.getFullYear() + 1)
  }
  return next
})

const yearsTogetherAtNext = computed(() => {
  if (!props.weddingDate || !target.value) return null
  const wedding = new Date(props.weddingDate)
  return target.value.getFullYear() - wedding.getFullYear()
})

const countdown = computed(() => {
  if (!target.value) return { d: 0, h: 0, m: 0, s: 0 }
  let s = Math.max(0, Math.floor((target.value.getTime() - props.now) / 1000))
  const d = Math.floor(s / 86_400)
  s %= 86_400
  const h = Math.floor(s / 3_600)
  s %= 3_600
  const m = Math.floor(s / 60)
  s %= 60
  return { d, h, m, s }
})

const formatted = computed(
  () => `${countdown.value.d}d ${countdown.value.h}h ${countdown.value.m}m ${countdown.value.s}s`,
)
</script>

<template>
  <UCard
    class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl"
    :ui="{ body: 'flex h-full flex-col justify-between gap-4 p-5 sm:p-6' }"
  >
    <div class="flex items-start justify-between gap-3">
      <div>
        <p class="mb-2 text-xs font-extrabold uppercase text-primary">Nächster Hochzeitstag</p>
        <h2 class="text-2xl font-black leading-none">
          <template v-if="yearsTogetherAtNext"> {{ yearsTogetherAtNext }}. Jubiläum </template>
          <template v-else> Jubiläum </template>
        </h2>
      </div>
      <UIcon name="i-lucide-cake" class="mt-1 size-7 text-primary" />
    </div>

    <div class="text-3xl font-black leading-none text-primary sm:text-4xl xl:text-5xl">
      {{ formatted }}
    </div>

    <p class="text-sm text-white/60">
      <template v-if="target">
        am {{ target.toLocaleDateString('de-DE', { day: '2-digit', month: 'long' }) }}
      </template>
    </p>
  </UCard>
</template>
