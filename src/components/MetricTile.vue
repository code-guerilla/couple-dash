<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { DashboardWidget } from '@/types'

const props = defineProps<{
  widget: DashboardWidget
  ownerName?: string
}>()

const { locale, t } = useI18n()

const toneClasses: Record<DashboardWidget['tone'], string> = {
  info: 'text-primary',
  success: 'text-primary',
  warning: 'text-amber-500',
  error: 'text-red-500',
}

const toneColors: Record<DashboardWidget['tone'], string> = {
  info: 'var(--ui-primary)',
  success: 'var(--ui-primary)',
  warning: 'var(--ui-warning)',
  error: 'var(--ui-error)',
}

function valueWithUnit(widget: DashboardWidget) {
  return `${widget.value}${widget.unit ?? ''}`
}
</script>

<template>
  <UCard :ui="{ root: 'overflow-visible', body: 'p-0!' }">
    <div class="grid gap-4">
      <div class="flex items-start justify-between gap-4 px-4 pt-4 sm:px-6 sm:pt-6">
        <div class="min-w-0">
          <p class="text-xs font-medium uppercase text-muted">{{ widget.label }}</p>
          <h2
            class="mt-1 wrap-break-word text-2xl font-semibold leading-tight text-highlighted sm:text-3xl"
            :class="toneClasses[widget.tone]"
          >
            {{ valueWithUnit(widget) }}
          </h2>
        </div>
        <UBadge v-if="ownerName" class="shrink-0" color="neutral" variant="soft">{{
          ownerName
        }}</UBadge>
      </div>

      <div v-if="widget.visual === 'radial'" class="flex items-center gap-4 px-4 sm:px-6">
        <div
          class="grid h-22 w-22 shrink-0 place-items-center rounded-full text-sm font-black [background:radial-gradient(circle_at_center,var(--ui-bg)_55%,transparent_56%),conic-gradient(var(--metric-color)_calc(var(--metric-value)*1%),var(--ui-bg-elevated)_0)]"
          :style="{
            '--metric-color': toneColors[widget.tone],
            '--metric-value': String(widget.numericValue ?? 0),
          }"
        >
          {{ widget.numericValue ?? 0 }}%
        </div>
        <p class="text-sm leading-relaxed text-muted">{{ widget.detail }}</p>
      </div>

      <template v-else-if="widget.visual === 'progress'">
        <div class="px-4 sm:px-6">
          <UProgress :model-value="widget.numericValue ?? 0" />
        </div>
        <p class="px-4 text-sm leading-relaxed text-muted sm:px-6">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'memory'">
        <div class="mx-4 rounded-md border border-default bg-muted p-4 sm:mx-6">
          <p class="text-sm font-semibold leading-relaxed">{{ widget.value }}</p>
          <p class="mt-2 text-xs text-muted">{{ widget.detail }}</p>
        </div>
      </template>

      <template v-else>
        <p class="px-4 text-sm leading-relaxed text-muted sm:px-6">{{ widget.detail }}</p>
      </template>

      <p class="px-4 pb-4 text-xs text-dimmed opacity-75 sm:px-6 sm:pb-6">
        {{
          t('metric.updated', {
            time: new Date(widget.updatedAt).toLocaleTimeString(locale),
          })
        }}
      </p>
    </div>
  </UCard>
</template>
