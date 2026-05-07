<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { DashboardWidget } from '@/types'

const props = defineProps<{
  widget: DashboardWidget
}>()

const { locale, t } = useI18n()

function dateOnlyTime(value: string) {
  const [year, month, day] = value.split('-').map(Number)

  if (!year || !month || !day) {
    return null
  }

  return new Date(year, month - 1, day).setHours(0, 0, 0, 0)
}

const timelineEntries = computed(() =>
  (props.widget.timelineEntries ?? [])
    .filter((entry) => entry.id !== 'first-date')
    .filter((entry) => entry.title || entry.date),
)

const items = computed(() =>
  timelineEntries.value.map((entry) => ({
    date: entry.date ? new Date(entry.date).toLocaleDateString(locale.value) : '',
    title: entry.title,
    description: entry.description,
    icon: entry.icon || 'i-lucide-heart',
    value: entry.id,
  })),
)

const activeMilestone = computed(() => {
  const today = new Date().setHours(0, 0, 0, 0)
  let index = 0

  timelineEntries.value.forEach((entry, entryIndex) => {
    const date = dateOnlyTime(entry.date)

    if (date !== null && date <= today) {
      index = entryIndex
    }
  })

  return index
})

const milestoneSummary = computed(() =>
  t(items.value.length === 1 ? 'dashboard.milestone' : 'dashboard.milestones', {
    count: items.value.length,
  }),
)
</script>

<template>
  <UCard :ui="{ body: 'p-6 sm:p-8' }">
    <template #header>
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p class="text-xs font-semibold uppercase text-muted">{{ milestoneSummary }}</p>
          <h2 class="text-2xl font-black">{{ widget.label }}</h2>
        </div>
        <UBadge color="primary" variant="soft">{{ items.length }}</UBadge>
      </div>
    </template>

    <UTimeline
      v-if="items.length"
      :default-value="activeMilestone"
      :items="items"
      class="w-full"
      color="primary"
    />
    <p v-else class="text-sm text-muted">{{ widget.detail }}</p>
  </UCard>
</template>
