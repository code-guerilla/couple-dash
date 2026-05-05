<script setup lang="ts">
import { computed } from 'vue'
import {
  VisArea,
  VisAxis,
  VisCrosshair,
  VisDonut,
  VisLine,
  VisSingleContainer,
  VisStackedBar,
  VisTooltip,
  VisXYContainer,
} from '@unovis/vue'
import { useI18n } from 'vue-i18n'
import type { ChartDataPoint, DashboardWidget } from '@/types'

const props = defineProps<{
  widget: DashboardWidget
  ownerName?: string
}>()

const { locale, t } = useI18n()

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

const hasChartData = computed(() => props.widget.chartData.length > 0)
const totalChartValue = computed(() =>
  props.widget.chartData.reduce((sum, item) => sum + item.value, 0),
)
const chartX = (_datum: ChartDataPoint, index: number) => index
const chartY = (datum: ChartDataPoint) => datum.value
const donutValue = (datum: ChartDataPoint) => datum.value
const chartTickFormat = (index: number) => {
  const label = props.widget.chartData[index]?.label ?? ''

  return label.length > 14 ? `${label.slice(0, 12)}...` : label
}
const chartTooltip = (datum: ChartDataPoint) => `${datum.label}: ${formatChartValue(datum.value)}`

function formatChartValue(value: number) {
  return new Intl.NumberFormat(locale.value, {
    maximumFractionDigits: 1,
  }).format(value)
}

function percentageOfTotal(value: number) {
  if (totalChartValue.value <= 0) {
    return '0%'
  }

  return `${Math.round((value / totalChartValue.value) * 100)}%`
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

      <template v-if="widget.visual === 'donut'">
        <div v-if="hasChartData" class="grid gap-4 px-4 sm:px-6">
          <div class="h-56 chart-surface rounded-md bg-elevated/35 p-2">
            <VisSingleContainer :data="widget.chartData" height="100%">
              <VisDonut
                :arc-width="24"
                :central-label="widget.chartOptions.centralLabel ?? widget.label"
                :central-sub-label="widget.chartOptions.centralSubLabel ?? widget.detail"
                :corner-radius="6"
                :pad-angle="0.02"
                :value="donutValue"
              />
            </VisSingleContainer>
          </div>
          <div class="grid gap-2 text-sm">
            <div
              v-for="item in widget.chartData"
              :key="item.label"
              class="grid grid-cols-[1fr_auto_auto] items-center gap-3 rounded-md border border-default bg-muted/50 px-3 py-2"
            >
              <span class="min-w-0 truncate text-muted">{{ item.label }}</span>
              <span class="font-semibold text-highlighted">{{ formatChartValue(item.value) }}</span>
              <UBadge color="neutral" variant="soft">{{ percentageOfTotal(item.value) }}</UBadge>
            </div>
          </div>
        </div>
        <p v-else class="px-4 text-sm leading-relaxed text-muted sm:px-6">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'bar'">
        <div v-if="hasChartData" class="chart-surface h-64 px-2">
          <VisXYContainer :data="widget.chartData" height="100%" :padding="{ top: 24, left: 8 }">
            <VisStackedBar :x="chartX" :y="chartY" :color="toneColors[widget.tone]" />
            <VisAxis type="x" :x="chartX" :tick-format="chartTickFormat" />
            <VisAxis type="y" />
            <VisCrosshair :color="toneColors[widget.tone]" :template="chartTooltip" />
            <VisTooltip />
          </VisXYContainer>
        </div>
        <p class="px-4 text-sm leading-relaxed text-muted sm:px-6">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'line'">
        <div v-if="hasChartData" class="chart-surface h-64 px-2">
          <VisXYContainer :data="widget.chartData" height="100%" :padding="{ top: 24, left: 8 }">
            <VisLine :x="chartX" :y="chartY" :color="toneColors[widget.tone]" />
            <VisArea :x="chartX" :y="chartY" :color="toneColors[widget.tone]" :opacity="0.12" />
            <VisAxis type="x" :x="chartX" :tick-format="chartTickFormat" />
            <VisAxis type="y" />
            <VisCrosshair :color="toneColors[widget.tone]" :template="chartTooltip" />
            <VisTooltip />
          </VisXYContainer>
        </div>
        <p class="px-4 text-sm leading-relaxed text-muted sm:px-6">{{ widget.detail }}</p>
      </template>

      <div v-else-if="widget.visual === 'radial'" class="flex items-center gap-4 px-4 sm:px-6">
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

<style scoped>
.chart-surface :deep(.unovis-xy-container) {
  --vis-crosshair-line-stroke-color: currentColor;
  --vis-crosshair-circle-stroke-color: var(--ui-bg);

  --vis-axis-grid-color: var(--ui-border);
  --vis-axis-tick-color: var(--ui-border);
  --vis-axis-tick-label-color: var(--ui-text-dimmed);

  --vis-tooltip-background-color: var(--ui-bg);
  --vis-tooltip-border-color: var(--ui-border);
  --vis-tooltip-text-color: var(--ui-text-highlighted);
}

.chart-surface :deep(.unovis-donut) {
  --vis-donut-central-label-text-color: var(--ui-text-highlighted);
  --vis-donut-central-sub-label-text-color: var(--ui-text-muted);
}
</style>
