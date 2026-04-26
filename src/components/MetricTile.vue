<script setup lang="ts">
import Card from 'primevue/card'
import Knob from 'primevue/knob'
import MeterGroup from 'primevue/metergroup'
import ProgressBar from 'primevue/progressbar'
import Tag from 'primevue/tag'
import { computed } from 'vue'
import type { DashboardWidget } from '@/types'

const props = defineProps<{
  widget: DashboardWidget
  ownerName?: string
}>()

const toneClasses: Record<DashboardWidget['tone'], string> = {
  info: 'text-info-500',
  success: 'text-green-500',
  warning: 'text-amber-500',
  error: 'text-red-500',
}

const toneColors: Record<DashboardWidget['tone'], string> = {
  info: 'var(--p-blue-500)',
  success: 'var(--p-green-500)',
  warning: 'var(--p-amber-500)',
  error: 'var(--p-red-500)',
}

function valueWithUnit(widget: DashboardWidget) {
  return `${widget.value}${widget.unit ?? ''}`
}

const meterValues = computed(() => [
  {
    label: props.widget.label,
    value: props.widget.numericValue ?? 40,
    color: 'var(--p-primary-500)',
  },
  { label: 'Shared', value: 35, color: 'var(--p-surface-500)' },
  { label: 'Reserve', value: 25, color: 'var(--p-primary-300)' },
])
</script>

<template>
  <Card>
    <template #content>
      <div class="grid gap-4">
      <div class="flex items-start justify-between gap-4">
        <div class="min-w-0">
          <p class="text-sm font-medium muted">{{ widget.label }}</p>
          <h2
            class="mt-1 break-words text-2xl font-black leading-tight sm:text-3xl"
            :class="toneClasses[widget.tone]"
          >
            {{ valueWithUnit(widget) }}
          </h2>
        </div>
        <Tag v-if="ownerName" class="shrink-0" severity="secondary" :value="ownerName" />
      </div>

      <div v-if="widget.visual === 'radial'" class="flex items-center gap-4">
        <Knob
          :model-value="widget.numericValue ?? 0"
          readonly
          :size="86"
          :value-color="toneColors[widget.tone]"
          range-color="var(--p-surface-200)"
          text-color="var(--p-text-color)"
        />
        <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
      </div>

      <template v-else-if="widget.visual === 'progress' || widget.visual === 'line'">
        <ProgressBar :value="widget.numericValue ?? 0" />
        <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'bar'">
        <MeterGroup :value="meterValues" label-position="end" />
        <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'doughnut'">
        <div class="flex items-center gap-4">
          <Knob
            :model-value="widget.numericValue ?? 0"
            readonly
            :size="86"
            :stroke-width="14"
            value-color="var(--p-primary-500)"
            range-color="var(--p-surface-200)"
            text-color="var(--p-text-color)"
          />
          <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
        </div>
      </template>

      <template v-else-if="widget.visual === 'memory'">
        <div class="metric-memory">
          <p class="text-sm font-semibold leading-relaxed">{{ widget.value }}</p>
          <p class="mt-2 text-xs muted">{{ widget.detail }}</p>
        </div>
      </template>

      <template v-else>
        <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
      </template>

      <p class="text-xs subtle">Updated {{ new Date(widget.updatedAt).toLocaleTimeString() }}</p>
      </div>
    </template>
  </Card>
</template>
