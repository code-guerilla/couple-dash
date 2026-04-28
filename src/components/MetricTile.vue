<script setup lang="ts">
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
  info: 'var(--ui-info)',
  success: 'var(--ui-success)',
  warning: 'var(--ui-warning)',
  error: 'var(--ui-error)',
}

function valueWithUnit(widget: DashboardWidget) {
  return `${widget.value}${widget.unit ?? ''}`
}

const meterValues = computed(() => [
  {
    label: props.widget.label,
    value: props.widget.numericValue ?? 40,
    color: 'var(--ui-primary)',
  },
  { label: 'Shared', value: 35, color: 'var(--ui-bg-accented)' },
  { label: 'Reserve', value: 25, color: 'var(--ui-primary)' },
])
</script>

<template>
  <UCard>
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
        <UBadge v-if="ownerName" class="shrink-0" color="neutral" variant="soft">{{ ownerName }}</UBadge>
      </div>

      <div v-if="widget.visual === 'radial'" class="flex items-center gap-4">
        <div
          class="metric-radial"
          :style="{ '--metric-color': toneColors[widget.tone], '--metric-value': String(widget.numericValue ?? 0) }"
        >
          {{ widget.numericValue ?? 0 }}%
        </div>
        <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
      </div>

      <template v-else-if="widget.visual === 'progress' || widget.visual === 'line'">
        <UProgress :model-value="widget.numericValue ?? 0" />
        <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'bar'">
        <div class="metric-meter" aria-hidden="true">
          <span
            v-for="meter in meterValues"
            :key="meter.label"
            :style="{ width: `${meter.value}%`, background: meter.color }"
          />
        </div>
        <p class="text-sm leading-relaxed muted">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'doughnut'">
        <div class="flex items-center gap-4">
          <div
            class="metric-radial"
            :style="{ '--metric-color': 'var(--ui-primary)', '--metric-value': String(widget.numericValue ?? 0) }"
          >
            {{ widget.numericValue ?? 0 }}%
          </div>
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
  </UCard>
</template>
