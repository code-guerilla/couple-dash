<script setup lang="ts">
import { computed } from 'vue'
import {
  VisAxis,
  VisDonut,
  VisLine,
  VisSingleContainer,
  VisStackedBar,
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
const chartX = (_datum: ChartDataPoint, index: number) => index
const chartY = (datum: ChartDataPoint) => datum.value
const donutValue = (datum: ChartDataPoint) => datum.value
const chartTickFormat = (index: number) => props.widget.chartData[index]?.label ?? ''
</script>

<template>
  <UCard>
    <div class="grid gap-4">
      <div class="flex items-start justify-between gap-4">
        <div class="min-w-0">
          <p class="text-sm font-medium text-muted">{{ widget.label }}</p>
          <h2
            class="mt-1 break-words text-2xl font-black leading-tight sm:text-3xl"
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
        <div v-if="hasChartData" class="grid gap-4">
          <div class="h-56">
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
              class="flex justify-between gap-3 rounded-md bg-muted px-3 py-2"
            >
              <span>{{ item.label }}</span>
              <span class="font-black">{{ item.value }}</span>
            </div>
          </div>
        </div>
        <p v-else class="text-sm leading-relaxed text-muted">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'bar'">
        <div v-if="hasChartData" class="h-56">
          <VisXYContainer :data="widget.chartData" height="100%">
            <VisStackedBar :x="chartX" :y="chartY" :rounded-corners="true" />
            <VisAxis type="x" :tick-format="chartTickFormat" />
            <VisAxis type="y" />
          </VisXYContainer>
        </div>
        <p class="text-sm leading-relaxed text-muted">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'line'">
        <div v-if="hasChartData" class="h-56">
          <VisXYContainer :data="widget.chartData" height="100%">
            <VisLine :x="chartX" :y="chartY" :color="toneColors[widget.tone]" />
            <VisAxis type="x" :tick-format="chartTickFormat" />
            <VisAxis type="y" />
          </VisXYContainer>
        </div>
        <p class="text-sm leading-relaxed text-muted">{{ widget.detail }}</p>
      </template>

      <div v-else-if="widget.visual === 'radial'" class="flex items-center gap-4">
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
        <UProgress :model-value="widget.numericValue ?? 0" />
        <p class="text-sm leading-relaxed text-muted">{{ widget.detail }}</p>
      </template>

      <template v-else-if="widget.visual === 'memory'">
        <div class="rounded-md border border-default bg-muted p-4">
          <p class="text-sm font-semibold leading-relaxed">{{ widget.value }}</p>
          <p class="mt-2 text-xs text-muted">{{ widget.detail }}</p>
        </div>
      </template>

      <template v-else>
        <p class="text-sm leading-relaxed text-muted">{{ widget.detail }}</p>
      </template>

      <p class="text-xs text-dimmed opacity-75">
        {{
          t('metric.updated', {
            time: new Date(widget.updatedAt).toLocaleTimeString(locale),
          })
        }}
      </p>
    </div>
  </UCard>
</template>
