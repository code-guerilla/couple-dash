<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { DashboardWidget } from '@/types'

const props = defineProps<{
  widget: DashboardWidget
}>()

const { locale } = useI18n()

const items = computed(() =>
  (props.widget.timelineEntries ?? [])
    .filter((entry) => entry.title || entry.date)
    .map((entry) => ({
      date: entry.date ? new Date(entry.date).toLocaleDateString(locale.value) : '',
      title: entry.title,
      description: entry.description,
      icon: entry.icon || 'i-lucide-heart',
      value: entry.id,
    })),
)
</script>

<template>
  <UCard :ui="{ body: 'p-6 sm:p-8' }">
    <template #header>
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p class="text-xs font-semibold uppercase text-muted">{{ widget.value }}</p>
          <h2 class="text-2xl font-black">{{ widget.label }}</h2>
        </div>
        <UBadge :color="widget.tone" variant="soft">{{ items.length }}</UBadge>
      </div>
    </template>

    <UTimeline
      v-if="items.length"
      :default-value="items.length - 1"
      :items="items"
      class="w-full"
      color="primary"
    />
    <p v-else class="text-sm text-muted">{{ widget.detail }}</p>
  </UCard>
</template>
