<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { alertTemplates } from '@/data/defaults'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase, type CoupleInviteStatus, type PendingPartnerInvite } from '@/services/supabase'
import type { AlertSeverity, ChartDataPoint, DashboardWidget, TimelineEntry, WidgetVisual } from '@/types'

interface AlertOption {
  id: string
  label: string
  title: string
  severity: AlertSeverity
}

interface CustomAlertTemplate {
  id: string
  title: string
  severity: AlertSeverity
}

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const coupleSlug = computed(() => String(route.params.coupleSlug))
const { initialized, isAuthenticated, isSupabaseConfigured, userId } = useSupabaseAuth()
const {
  couple,
  widgets,
  alerts,
  error,
  loadCouple,
  updateWidget,
  addWidget,
  setWidgetVisible,
  triggerAlert,
  setAlertActive,
} = useDashboardStore(coupleSlug.value)

const currentPartnerId = ref<string | null>(null)
const membershipError = ref<string | null>(null)
const inviteStatus = ref<CoupleInviteStatus | null>(null)
const pendingInvite = ref<PendingPartnerInvite | null>(null)
const inviteError = ref<string | null>(null)
const generatingInvite = ref(false)
const customAlertDraft = ref('')
const customAlertTemplates = ref<CustomAlertTemplate[]>([])
type ChartVisual = Extract<WidgetVisual, 'donut' | 'bar' | 'line'>
const chartVisuals: ChartVisual[] = ['donut', 'bar', 'line']
const chartDraft = reactive({
  label: 'Woraus die Beziehung besteht',
  detail: 'Ein wissenschaftlich fragwürdiger Mini-Chart.',
  visual: 'donut' as ChartVisual,
  tone: 'info' as AlertSeverity,
  centralLabel: 'Mix',
  centralSubLabel: 'live',
  rows: [
    { label: 'Liebe', value: 40 },
    { label: 'Kaffee', value: 20 },
    { label: 'Diskussionen über Essen', value: 25 },
  ] as ChartDataPoint[],
})
const partner = computed(() =>
  couple.value?.partners.find((item) => item.id === currentPartnerId.value),
)
const pendingPartnerName = computed(() => inviteStatus.value?.pending_partner_name ?? null)
const pendingInviteUrl = computed(() => {
  if (!pendingInvite.value || typeof window === 'undefined') {
    return ''
  }

  const origin = window.location.origin.replace(/\/$/, '')
  return `${origin}/invite/${pendingInvite.value.couple_slug}/${pendingInvite.value.partner_slug}?token=${pendingInvite.value.invite_token}`
})
const editableWidgets = computed(() =>
  widgets.value.filter(
    (widget) => widget.scope === 'shared' || widget.personId === currentPartnerId.value,
  ),
)
const editableMetricWidgets = computed(() =>
  editableWidgets.value.filter((widget) => widget.visual !== 'timeline'),
)
const sharedMetricWidgets = computed(() =>
  editableMetricWidgets.value.filter((widget) => widget.scope === 'shared'),
)
const personalMetricWidgets = computed(() =>
  editableMetricWidgets.value.filter((widget) => widget.scope !== 'shared'),
)
const editableTimelineWidgets = computed(() =>
  editableWidgets.value.filter((widget) => widget.visual === 'timeline'),
)
const today = new Date().toISOString().slice(0, 10)

const visualOptionValues: WidgetVisual[] = [
  'stat',
  'progress',
  'radial',
  'donut',
  'bar',
  'line',
  'memory',
]
const toneOptionValues: AlertSeverity[] = ['info', 'success', 'warning', 'error']
const visualOptions = computed(() =>
  visualOptionValues.map((value) => ({ label: t(`edit.visuals.${value}`), value })),
)
const toneOptions = computed(() =>
  toneOptionValues.map((value) => ({ label: t(`edit.tones.${value}`), value })),
)
const chartVisualOptions = computed(() =>
  chartVisuals.map((value) => ({ label: t(`edit.visuals.${value}`), value })),
)
const customAlertStorageKey = computed(() => `couple-dash-custom-alerts:${coupleSlug.value}`)
const alertTemplateOptions = computed<AlertOption[]>(() =>
  alertTemplates.map((template) => {
    const templatePartner =
      couple.value?.partners.find(
        (item) => item.name.toLowerCase() === template.partnerName.toLowerCase(),
      ) ?? couple.value?.partners[template.partnerIndex]
    const name = templatePartner?.name ?? template.partnerName
    const title = `${name}: ${template.text}`

    return {
      id: template.id,
      label: title,
      title,
      severity: template.severity,
    }
  }),
)
const customAlertOptions = computed<AlertOption[]>(() =>
  customAlertTemplates.value.map((template) => ({
    id: template.id,
    label: template.title,
    title: template.title,
    severity: template.severity,
  })),
)
const alertTemplateCount = computed(
  () => alertTemplateOptions.value.length + customAlertOptions.value.length,
)
const editAccordionDefaultValue = ['trigger-alert', 'relationship-timeline', 'live-metrics']
const editAccordionItems = computed(() => [
  {
    label: `${t('edit.triggerAlert')} (${alertTemplateCount.value})`,
    icon: 'i-lucide-bell-ring',
    value: 'trigger-alert',
  },
  ...(editableTimelineWidgets.value.length
    ? [
        {
          label: `${t('edit.relationshipTimeline')} (${editableTimelineWidgets.value.length})`,
          icon: 'i-lucide-milestone',
          value: 'relationship-timeline',
        },
      ]
    : []),
  {
    label: `${t('edit.editLiveMetrics')} (${editableMetricWidgets.value.length})`,
    icon: 'i-lucide-chart-no-axes-combined',
    value: 'live-metrics',
  },
  {
    label: `${t('edit.alerts')} (${alerts.value.length})`,
    icon: 'i-lucide-message-circle-warning',
    value: 'alerts',
  },
])
const metricTabItems = computed(() => [
  {
    label: t('edit.shared'),
    icon: 'i-lucide-users',
    badge: sharedMetricWidgets.value.length,
    value: 'shared',
    widgets: sharedMetricWidgets.value,
  },
  {
    label: partner.value?.name ?? t('edit.onlyMine'),
    icon: 'i-lucide-user',
    badge: personalMetricWidgets.value.length,
    value: 'personal',
    widgets: personalMetricWidgets.value,
  },
])

async function loadMembership() {
  currentPartnerId.value = null
  membershipError.value = null

  if (!isSupabaseConfigured || !supabase || !couple.value || !userId.value) {
    currentPartnerId.value = couple.value?.partners[0]?.id ?? null
    return
  }

  const { data, error: memberError } = await supabase
    .from('couple_member')
    .select('partner_id')
    .eq('couple_id', couple.value.id)
    .eq('user_id', userId.value)
    .maybeSingle()

  if (memberError) {
    membershipError.value = memberError.message
    return
  }

  currentPartnerId.value = data?.partner_id ? String(data.partner_id) : null
}

async function loadInviteStatus() {
  inviteStatus.value = null
  inviteError.value = null

  if (!isSupabaseConfigured || !supabase || !couple.value || !currentPartnerId.value) {
    return
  }

  const { data, error: statusError } = await supabase
    .rpc('get_couple_invite_status', {
      p_couple_id: couple.value.id,
    })
    .single()

  if (statusError) {
    inviteError.value = statusError.message
    return
  }

  inviteStatus.value = data as CoupleInviteStatus
}

async function loadPrivateEditor() {
  if (!isSupabaseConfigured || isAuthenticated.value) {
    await loadCouple()
    await loadMembership()
    await loadInviteStatus()
  }
}

async function saveWidget(widget: DashboardWidget) {
  await updateWidget(widget.id, {
    label: widget.label,
    value: widget.value,
    detail: widget.detail,
    visual: widget.visual,
    tone: widget.tone,
    numericValue: widget.numericValue,
    chartData: sanitizeChartData(widget.chartData),
    chartOptions: widget.chartOptions,
  })
}

function isChartWidget(widget: DashboardWidget) {
  return chartVisuals.includes(widget.visual as ChartVisual)
}

function sanitizeChartData(rows: ChartDataPoint[]) {
  return rows
    .map((row) => ({
      label: row.label.trim(),
      value: Number(row.value) || 0,
    }))
    .filter((row) => row.label)
}

function addChartRow(widget: DashboardWidget) {
  widget.chartData = [...widget.chartData, { label: t('edit.chartNewLabel'), value: 10 }]
}

function removeChartRow(widget: DashboardWidget, index: number) {
  widget.chartData = widget.chartData.filter((_row, rowIndex) => rowIndex !== index)
}

function addDraftChartRow() {
  chartDraft.rows.push({ label: t('edit.chartNewLabel'), value: 10 })
}

function removeDraftChartRow(index: number) {
  chartDraft.rows = chartDraft.rows.filter((_row, rowIndex) => rowIndex !== index)
}

async function createChartWidget() {
  if (!couple.value) {
    return
  }

  const chartData = sanitizeChartData(chartDraft.rows)
  if (!chartDraft.label.trim() || !chartData.length) {
    return
  }

  await addWidget({
    coupleId: couple.value.id,
    label: chartDraft.label.trim(),
    value: String(chartData.reduce((sum, row) => sum + row.value, 0)),
    detail: chartDraft.detail.trim(),
    scope: 'shared',
    visual: chartDraft.visual,
    order: Math.max(0, ...widgets.value.map((widget) => widget.order)) + 1,
    tone: chartDraft.tone,
    visible: true,
    timelineEntries: [],
    chartData,
    chartOptions: {
      centralLabel: chartDraft.centralLabel.trim() || undefined,
      centralSubLabel: chartDraft.centralSubLabel.trim() || undefined,
    },
  })

  chartDraft.label = ''
  chartDraft.detail = ''
  chartDraft.rows = [
    { label: 'Liebe', value: 40 },
    { label: 'Kaffee', value: 20 },
  ]
}

function addTimelineEntry(widget: DashboardWidget) {
  widget.timelineEntries = [
    ...(widget.timelineEntries ?? []),
    {
      id: crypto.randomUUID(),
      date: today,
      title: t('edit.newMilestone'),
      description: '',
      icon: 'i-lucide-heart',
    },
  ]
}

function removeTimelineEntry(widget: DashboardWidget, entryId: string) {
  widget.timelineEntries = (widget.timelineEntries ?? []).filter((entry) => entry.id !== entryId)
}

async function saveTimelineWidget(widget: DashboardWidget) {
  await updateWidget(widget.id, {
    label: widget.label,
    value: widget.value,
    detail: widget.detail,
    tone: widget.tone,
    timelineEntries: (widget.timelineEntries ?? []).map((entry: TimelineEntry) => ({
      ...entry,
      description: '',
      icon: entry.icon || 'i-lucide-heart',
    })),
  })
}

function loadCustomAlertTemplates() {
  if (typeof localStorage === 'undefined') {
    return
  }

  const stored = localStorage.getItem(customAlertStorageKey.value)
  if (!stored) {
    customAlertTemplates.value = []
    return
  }

  try {
    const parsed = JSON.parse(stored) as Partial<CustomAlertTemplate>[]
    customAlertTemplates.value = parsed
      .filter((item) => item.id && item.title)
      .map((item) => ({
        id: String(item.id),
        title: String(item.title),
        severity: toneOptionValues.includes(item.severity as AlertSeverity)
          ? (item.severity as AlertSeverity)
          : 'info',
      }))
  } catch {
    customAlertTemplates.value = []
  }
}

function persistCustomAlertTemplates() {
  if (typeof localStorage === 'undefined') {
    return
  }

  localStorage.setItem(customAlertStorageKey.value, JSON.stringify(customAlertTemplates.value))
}

function customAlertTitle(text: string) {
  const title = text.trim()
  if (!title) {
    return ''
  }

  if (title.includes(':')) {
    return title
  }

  return `${partner.value?.name ?? t('edit.partnerFallback')}: ${title}`
}

function addCustomAlertTemplate() {
  const title = customAlertTitle(customAlertDraft.value)
  if (!title) {
    return
  }

  const exists = customAlertTemplates.value.some(
    (template) => template.title.toLowerCase() === title.toLowerCase(),
  )
  if (!exists) {
    customAlertTemplates.value = [
      ...customAlertTemplates.value,
      {
        id: crypto.randomUUID(),
        title,
        severity: 'info',
      },
    ]
    persistCustomAlertTemplates()
  }

  customAlertDraft.value = ''
}

function removeCustomAlertTemplate(templateId: string) {
  customAlertTemplates.value = customAlertTemplates.value.filter(
    (template) => template.id !== templateId,
  )
  persistCustomAlertTemplates()
}

async function sendAlert(alert: Pick<AlertOption, 'title' | 'severity'>) {
  if (!couple.value) {
    return
  }

  await triggerAlert({
    coupleId: couple.value.id,
    title: alert.title,
    detail: t('edit.raisedFrom', { name: partner.value?.name ?? t('alerts.partnerFallback') }),
    severity: alert.severity,
    source: 'partner',
    triggeredBy: partner.value?.name,
  })
}

async function createPartnerInvite() {
  if (!supabase || !couple.value) {
    return
  }

  generatingInvite.value = true
  inviteError.value = null
  pendingInvite.value = null

  const { data, error: createError } = await supabase
    .rpc('create_pending_partner_invite', {
      p_couple_id: couple.value.id,
    })
    .single()

  generatingInvite.value = false

  if (createError) {
    inviteError.value = createError.message
    return
  }

  pendingInvite.value = data as PendingPartnerInvite
  await loadInviteStatus()
}

async function copyPendingInvite() {
  if (!pendingInviteUrl.value) {
    return
  }

  await navigator.clipboard.writeText(pendingInviteUrl.value)
}

watch(userId, () => void loadPrivateEditor())
watch(coupleSlug, loadCustomAlertTemplates)

onMounted(() => {
  loadCustomAlertTemplates()
  void loadPrivateEditor()
})
</script>

<template>
  <section v-if="isSupabaseConfigured && initialized && !isAuthenticated" class="mx-auto max-w-md">
    <AuthPanel />
  </section>

  <section v-else-if="couple" class="mx-auto max-w-3xl space-y-6 pb-10">
    <div class="flex items-center justify-between gap-4">
      <div>
        <p class="text-sm font-semibold text-muted">{{ couple.name }}</p>
        <h1 class="text-3xl font-black">
          {{ t('edit.console', { name: partner?.name ?? t('edit.partnerFallback') }) }}
        </h1>
      </div>
      <UButton
        :label="t('edit.display')"
        size="sm"
        variant="ghost"
        type="button"
        @click="router.push({ name: 'display', params: { coupleSlug: couple.slug } })"
      />
    </div>

    <UAlert
      v-if="error || membershipError"
      color="warning"
      variant="soft"
      :description="membershipError ?? error ?? ''"
    />

    <UCard v-if="pendingPartnerName || pendingInviteUrl" variant="subtle">
      <div class="grid gap-4 md:grid-cols-[1fr_auto] md:items-center">
        <div>
          <h2 class="text-xl font-black">{{ t('edit.pendingInviteTitle') }}</h2>
          <p class="text-sm text-muted">
            {{ t('edit.pendingInviteDescription', { name: pendingPartnerName }) }}
          </p>
          <p v-if="pendingInviteUrl" class="mt-2 break-all text-sm text-muted">
            {{ pendingInviteUrl }}
          </p>
          <UAlert
            v-if="inviteError"
            class="mt-3"
            color="warning"
            variant="soft"
            :description="inviteError"
          />
        </div>
        <div class="flex flex-wrap gap-2 md:justify-end">
          <UButton
            icon="i-lucide-link"
            :label="t('edit.generateInvite')"
            :loading="generatingInvite"
            type="button"
            @click="createPartnerInvite"
          />
          <UButton
            v-if="pendingInviteUrl"
            icon="i-lucide-copy"
            :label="t('edit.copyInvite')"
            variant="outline"
            type="button"
            @click="copyPendingInvite"
          />
        </div>
      </div>
    </UCard>

    <div class="grid gap-3 sm:grid-cols-2">
      <UCard variant="subtle" :ui="{ body: 'p-4 sm:p-4' }">
        <div class="flex items-center justify-between gap-3">
          <div>
            <div class="text-sm text-muted">{{ t('edit.editableMetrics') }}</div>
            <div class="text-sm text-muted">{{ t('edit.editableMetricsDescription') }}</div>
          </div>
          <div class="text-3xl font-black leading-none">{{ editableWidgets.length }}</div>
        </div>
      </UCard>
      <UCard variant="subtle" :ui="{ body: 'p-4 sm:p-4' }">
        <div class="flex items-center justify-between gap-3">
          <div>
            <div class="text-sm text-muted">{{ t('edit.activeAlerts') }}</div>
            <div class="text-sm text-muted">{{ t('edit.activeAlertsDescription') }}</div>
          </div>
          <div class="text-3xl font-black leading-none text-amber-500">{{ alerts.length }}</div>
        </div>
      </UCard>
    </div>

    <UAccordion
      :items="editAccordionItems"
      :default-value="editAccordionDefaultValue"
      :unmount-on-hide="false"
      type="multiple"
      class="rounded-xl border border-default px-4"
    >
      <template #body="{ item }">
        <section v-if="item.value === 'trigger-alert'" class="space-y-4">
          <div class="grid gap-2 sm:grid-cols-2">
            <UButton
              v-for="template in alertTemplateOptions"
              :key="template.id"
              class="justify-start text-left"
              :label="template.label"
              variant="outline"
              type="button"
              @click="sendAlert(template)"
            />
          </div>

          <form
            class="grid gap-3 rounded-xl border border-default p-3"
            @submit.prevent="addCustomAlertTemplate"
          >
            <UFormField :label="t('edit.customAlert')">
              <UInput
                v-model="customAlertDraft"
                class="w-full"
                :placeholder="t('edit.customAlertPlaceholder')"
              />
            </UFormField>
            <div class="flex flex-wrap justify-end gap-2">
              <UButton :label="t('edit.saveCustomAlert')" icon="i-lucide-plus" type="submit" />
            </div>
          </form>

          <div v-if="customAlertOptions.length" class="grid gap-2 sm:grid-cols-2">
            <div v-for="template in customAlertOptions" :key="template.id" class="flex gap-2">
              <UButton
                class="min-w-0 flex-1 justify-start text-left"
                :label="template.label"
                variant="soft"
                type="button"
                @click="sendAlert(template)"
              />
              <UButton
                :aria-label="t('edit.delete')"
                color="neutral"
                icon="i-lucide-trash-2"
                variant="ghost"
                type="button"
                @click="removeCustomAlertTemplate(template.id)"
              />
            </div>
          </div>
        </section>

        <section v-else-if="item.value === 'relationship-timeline'" class="space-y-3">
          <UCard
            v-for="widget in editableTimelineWidgets"
            :key="widget.id"
            variant="subtle"
            :ui="{ body: 'p-4 sm:p-4' }"
          >
            <form class="grid gap-4" @submit.prevent="saveTimelineWidget(widget)">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <div class="flex items-center gap-2">
                  <UBadge color="success" variant="soft">{{ t('edit.staticWidget') }}</UBadge>
                  <UBadge :color="widget.visible ? 'success' : 'neutral'" variant="soft">
                    {{ widget.visible ? t('edit.visible') : t('edit.hidden') }}
                  </UBadge>
                </div>
                <div class="flex gap-2">
                  <UButton
                    :label="widget.visible ? t('edit.hide') : t('edit.show')"
                    variant="outline"
                    size="sm"
                    type="button"
                    @click="setWidgetVisible(widget.id, !widget.visible)"
                  />
                  <UButton
                    :label="t('edit.addMilestone')"
                    variant="outline"
                    size="sm"
                    type="button"
                    @click="addTimelineEntry(widget)"
                  />
                  <UButton :label="t('edit.save')" size="sm" type="submit" />
                </div>
              </div>

              <div class="grid gap-3 sm:grid-cols-2">
                <UFormField :label="t('edit.timelineTitle')">
                  <UInput v-model="widget.label" class="w-full font-semibold" />
                </UFormField>
                <UFormField :label="t('edit.timelineSummary')">
                  <UInput v-model="widget.value" class="w-full" />
                </UFormField>
              </div>

              <div class="grid gap-2">
                <div
                  v-for="entry in widget.timelineEntries"
                  :key="entry.id"
                  class="grid gap-3 rounded-md border border-default p-3 lg:grid-cols-[1fr_10rem_10rem_auto] lg:items-end"
                >
                  <UFormField :label="t('edit.milestoneTitle')">
                    <UInput v-model="entry.title" class="w-full" />
                  </UFormField>
                  <UFormField :label="t('edit.milestoneDate')">
                    <UInput v-model="entry.date" class="w-full" type="date" />
                  </UFormField>
                  <UFormField :label="t('edit.icon')">
                    <UInput v-model="entry.icon" class="w-full" placeholder="i-lucide-heart" />
                  </UFormField>
                  <UButton
                    :label="t('edit.delete')"
                    color="error"
                    variant="ghost"
                    size="sm"
                    type="button"
                    @click="removeTimelineEntry(widget, entry.id)"
                  />
                </div>
              </div>
            </form>
          </UCard>
        </section>

        <section v-else-if="item.value === 'live-metrics'" class="space-y-4">
          <form
            class="grid gap-4 rounded-xl border border-default bg-muted/40 p-4"
            @submit.prevent="createChartWidget"
          >
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h3 class="text-lg font-black">{{ t('edit.chartDesigner') }}</h3>
                <p class="text-sm text-muted">{{ t('edit.chartDesignerDescription') }}</p>
              </div>
              <UButton icon="i-lucide-plus" :label="t('edit.createChart')" type="submit" />
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <UFormField :label="t('edit.metricKey')">
                <UInput v-model="chartDraft.label" class="w-full" />
              </UFormField>
              <UFormField :label="t('edit.visual')">
                <USelect
                  v-model="chartDraft.visual"
                  class="w-full"
                  label-key="label"
                  value-key="value"
                  :items="chartVisualOptions"
                />
              </UFormField>
            </div>

            <UFormField :label="t('edit.explanation')">
              <UTextarea v-model="chartDraft.detail" autoresize class="w-full" />
            </UFormField>

            <div v-if="chartDraft.visual === 'donut'" class="grid gap-3 sm:grid-cols-2">
              <UFormField :label="t('edit.chartCentralLabel')">
                <UInput v-model="chartDraft.centralLabel" class="w-full" />
              </UFormField>
              <UFormField :label="t('edit.chartCentralSubLabel')">
                <UInput v-model="chartDraft.centralSubLabel" class="w-full" />
              </UFormField>
            </div>

            <div class="grid gap-2">
              <div
                v-for="(row, index) in chartDraft.rows"
                :key="index"
                class="grid gap-2 sm:grid-cols-[1fr_8rem_auto]"
              >
                <UInput v-model="row.label" :placeholder="t('edit.chartLabel')" />
                <UInputNumber
                  :model-value="row.value"
                  @update:model-value="row.value = $event ?? 0"
                />
                <UButton
                  :aria-label="t('edit.delete')"
                  color="neutral"
                  icon="i-lucide-trash-2"
                  variant="ghost"
                  type="button"
                  @click="removeDraftChartRow(index)"
                />
              </div>
              <UButton
                class="justify-self-start"
                icon="i-lucide-plus"
                :label="t('edit.addChartRow')"
                variant="outline"
                type="button"
                @click="addDraftChartRow"
              />
            </div>
          </form>

          <UTabs
            :items="metricTabItems"
            :unmount-on-hide="false"
            default-value="shared"
            variant="link"
          >
            <template #content="{ item: tab }">
              <div class="space-y-3">
                <UCard
                  v-for="widget in tab.widgets"
                  :key="widget.id"
                  variant="subtle"
                  :ui="{ body: 'p-4 sm:p-4' }"
                >
                  <form class="grid gap-4" @submit.prevent="saveWidget(widget)">
                    <div class="flex flex-wrap items-center justify-between gap-3">
                      <div class="flex items-center gap-2">
                        <UBadge
                          :color="widget.scope === 'shared' ? 'info' : 'neutral'"
                          variant="soft"
                        >
                          {{ widget.scope === 'shared' ? t('edit.shared') : t('edit.onlyMine') }}
                        </UBadge>
                        <UBadge :color="widget.visible ? 'success' : 'neutral'" variant="soft">
                          {{ widget.visible ? t('edit.visible') : t('edit.hidden') }}
                        </UBadge>
                      </div>
                      <div class="flex gap-2">
                        <UButton
                          :label="widget.visible ? t('edit.hide') : t('edit.show')"
                          variant="outline"
                          size="sm"
                          type="button"
                          @click="setWidgetVisible(widget.id, !widget.visible)"
                        />
                        <UButton :label="t('edit.save')" size="sm" type="submit" />
                      </div>
                    </div>

                    <div class="grid gap-3 sm:grid-cols-2">
                      <UFormField :label="t('edit.metricKey')">
                        <UInput v-model="widget.label" class="w-full font-semibold" />
                      </UFormField>
                      <UFormField :label="t('edit.value')">
                        <UInput v-model="widget.value" class="w-full text-lg" />
                      </UFormField>
                    </div>

                    <UFormField :label="t('edit.explanation')">
                      <UTextarea v-model="widget.detail" autoresize class="w-full" />
                    </UFormField>

                    <div v-if="isChartWidget(widget)" class="grid gap-3 rounded-md border border-default p-3">
                      <div
                        v-if="widget.visual === 'donut'"
                        class="grid gap-3 sm:grid-cols-2"
                      >
                        <UFormField :label="t('edit.chartCentralLabel')">
                          <UInput
                            v-model="widget.chartOptions.centralLabel"
                            class="w-full"
                          />
                        </UFormField>
                        <UFormField :label="t('edit.chartCentralSubLabel')">
                          <UInput
                            v-model="widget.chartOptions.centralSubLabel"
                            class="w-full"
                          />
                        </UFormField>
                      </div>

                      <div class="grid gap-2">
                        <div
                          v-for="(row, index) in widget.chartData"
                          :key="index"
                          class="grid gap-2 sm:grid-cols-[1fr_8rem_auto]"
                        >
                          <UInput v-model="row.label" :placeholder="t('edit.chartLabel')" />
                          <UInputNumber
                            :model-value="row.value"
                            @update:model-value="row.value = $event ?? 0"
                          />
                          <UButton
                            :aria-label="t('edit.delete')"
                            color="neutral"
                            icon="i-lucide-trash-2"
                            variant="ghost"
                            type="button"
                            @click="removeChartRow(widget, index)"
                          />
                        </div>
                        <UButton
                          class="justify-self-start"
                          icon="i-lucide-plus"
                          :label="t('edit.addChartRow')"
                          variant="outline"
                          type="button"
                          @click="addChartRow(widget)"
                        />
                      </div>
                    </div>

                    <div class="grid gap-3 sm:grid-cols-3">
                      <UFormField :label="t('edit.visual')">
                        <USelect
                          v-model="widget.visual"
                          class="w-full"
                          label-key="label"
                          value-key="value"
                          :items="visualOptions"
                        />
                      </UFormField>
                      <UFormField :label="t('edit.tone')">
                        <USelect
                          v-model="widget.tone"
                          class="w-full"
                          label-key="label"
                          value-key="value"
                          :items="toneOptions"
                        />
                      </UFormField>
                      <UFormField :label="t('edit.numericValue')">
                        <UInputNumber
                          class="w-full"
                          :max="100"
                          :min="0"
                          :model-value="widget.numericValue ?? 0"
                          @update:model-value="widget.numericValue = $event ?? 0"
                        />
                      </UFormField>
                    </div>
                  </form>
                </UCard>
              </div>
            </template>
          </UTabs>
        </section>

        <section v-else class="space-y-3">
          <UAlert
            v-for="alert in alerts"
            :key="alert.id"
            color="info"
            variant="outline"
            :description="alert.title"
          >
            <template #actions>
              <UButton
                :label="t('edit.deactivate')"
                size="sm"
                variant="ghost"
                type="button"
                @click="setAlertActive(alert.id, false)"
              />
            </template>
          </UAlert>
        </section>
      </template>
    </UAccordion>
  </section>

  <section v-else class="mx-auto max-w-md">
    <UAlert color="warning" variant="soft" :description="t('edit.noDashboard')" />
  </section>
</template>
