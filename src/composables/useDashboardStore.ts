import { computed, readonly, ref } from 'vue'
import { i18n } from '@/i18n'
import { supabase } from '@/services/supabase'
import type {
  ChartDataPoint,
  ChartOptions,
  CoupleAlert,
  DashboardState,
  DashboardWidget,
  TimelineEntry,
} from '@/types'

const emptyState: DashboardState = { couples: [], widgets: [], alerts: [] }
const state = ref<DashboardState>(emptyState)
const loading = ref(false)
const error = ref<string | null>(null)
const currentTime = ref(Date.now())
let activeSubscription: { unsubscribe: () => void } | null = null

if (typeof window !== 'undefined') {
  window.setInterval(() => {
    currentTime.value = Date.now()
  }, 60_000)
}

function t(key: string) {
  return i18n.global.t(key)
}

function nextLocalMidnightIso() {
  const expiresAt = new Date()
  expiresAt.setHours(24, 0, 0, 0)
  return expiresAt.toISOString()
}

function isAlertVisible(alert: CoupleAlert) {
  if (!alert.active) {
    return false
  }

  return !alert.expiresAt || Date.parse(alert.expiresAt) > currentTime.value
}

function mapTimelineEntries(value: unknown): TimelineEntry[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.map((entry, index) => {
    const item = entry as Partial<TimelineEntry>

    return {
      id: String(item.id || `milestone-${index + 1}`),
      date: String(item.date ?? ''),
      title: String(item.title ?? ''),
      description: String(item.description ?? ''),
      icon: String(item.icon || 'i-lucide-heart'),
    }
  })
}

function mapChartData(value: unknown): ChartDataPoint[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.map((entry) => {
    const item = entry as Partial<ChartDataPoint>

    return {
      label: String(item.label ?? ''),
      value: Number(item.value ?? 0),
    }
  })
}

function mapChartOptions(value: unknown): ChartOptions {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {}
  }

  const options = value as Partial<ChartOptions>

  return {
    centralLabel: options.centralLabel ? String(options.centralLabel) : undefined,
    centralSubLabel: options.centralSubLabel ? String(options.centralSubLabel) : undefined,
  }
}

function mapWidgetFromRow(row: Record<string, unknown>): DashboardWidget {
  return {
    id: String(row.id),
    coupleId: String(row.couple_id),
    label: String(row.label),
    value: String(row.value),
    unit: row.unit ? String(row.unit) : undefined,
    detail: String(row.detail ?? ''),
    visual: String(row.visual ?? 'stat') as DashboardWidget['visual'],
    order: Number(row.sort_order ?? 0),
    min: row.min_value === null ? undefined : Number(row.min_value ?? 0),
    max: row.max_value === null ? undefined : Number(row.max_value ?? 100),
    numericValue: row.numeric_value === null ? undefined : Number(row.numeric_value ?? 0),
    tone: String(row.tone ?? 'info') as DashboardWidget['tone'],
    visible: Boolean(row.visible ?? true),
    timelineEntries: mapTimelineEntries(row.timeline_entries),
    chartData: mapChartData(row.chart_data),
    chartOptions: mapChartOptions(row.chart_options),
    updatedAt: String(row.updated_at ?? new Date().toISOString()),
  }
}

function mapAlertFromRow(row: Record<string, unknown>): CoupleAlert {
  return {
    id: String(row.id),
    coupleId: String(row.couple_id),
    title: String(row.title),
    detail: String(row.detail ?? ''),
    severity: String(row.severity ?? 'info') as CoupleAlert['severity'],
    source: row.source === 'partner' ? 'partner' : 'system',
    active: Boolean(row.active),
    createdAt: String(row.created_at ?? new Date().toISOString()),
    expiresAt: row.expires_at ? String(row.expires_at) : undefined,
    triggeredByPartnerId: row.triggered_by_partner_id
      ? String(row.triggered_by_partner_id)
      : undefined,
    triggeredBy: row.triggered_by ? String(row.triggered_by) : undefined,
  }
}

function mapSupabaseError(message: string) {
  if (
    message.includes('JWT') ||
    message.includes('permission denied') ||
    message.includes('Results contain 0 rows')
  ) {
    return t('dashboard.unavailable')
  }

  return message
}

async function loadSupabaseCouple(coupleSlug: string) {
  if (!supabase) {
    return
  }

  loading.value = true
  error.value = null

  const { data: couple, error: coupleError } = await supabase
    .from('couple')
    .select(
      'id, slug, name, subtitle, relationship_start, wedding_date, created_at, partner(id, couple_id, slug, name, role, accent, created_at)',
    )
    .eq('slug', coupleSlug)
    .single()

  if (coupleError) {
    error.value = mapSupabaseError(coupleError.message)
    state.value = emptyState
    loading.value = false
    return
  }

  const [{ data: widgets, error: widgetsError }, { data: alerts, error: alertsError }] =
    await Promise.all([
      supabase.from('dashboard_widget').select('*').eq('couple_id', couple.id).order('sort_order'),
      supabase
        .from('couple_alert')
        .select('*')
        .eq('couple_id', couple.id)
        .eq('active', true)
        .order('created_at', { ascending: false }),
    ])

  if (widgetsError || alertsError) {
    error.value = mapSupabaseError(
      widgetsError?.message ?? alertsError?.message ?? t('dashboard.supabaseLoadFailed'),
    )
    loading.value = false
    return
  }

  state.value = {
    couples: [
      {
        id: String(couple.id),
        slug: String(couple.slug),
        name: String(couple.name),
        subtitle: String(couple.subtitle ?? ''),
        relationshipStart: String(couple.relationship_start),
        weddingDate: String(couple.wedding_date),
        partners: (couple.partner ?? []).map((partner: Record<string, unknown>) => ({
          id: String(partner.id),
          slug: String(partner.slug),
          name: String(partner.name),
          role: String(partner.role ?? ''),
          accent: String(partner.accent ?? 'primary'),
        })),
      },
    ],
    widgets: (widgets ?? []).map(mapWidgetFromRow),
    alerts: (alerts ?? []).map(mapAlertFromRow),
  }

  subscribeSupabaseCouple(String(couple.id), coupleSlug)
  loading.value = false
}

function subscribeSupabaseCouple(coupleId: string, coupleSlug: string) {
  if (!supabase) {
    return
  }

  activeSubscription?.unsubscribe()

  activeSubscription = supabase
    .channel(`couple-dashboard:${coupleId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'dashboard_widget',
        filter: `couple_id=eq.${coupleId}`,
      },
      () => void loadSupabaseCouple(coupleSlug),
    )
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'couple_alert',
        filter: `couple_id=eq.${coupleId}`,
      },
      () => void loadSupabaseCouple(coupleSlug),
    )
    .subscribe()
}

export function useDashboardStore(coupleSlug?: string) {
  const couples = computed(() => state.value.couples)
  const couple = computed(() => state.value.couples.find((item) => item.slug === coupleSlug))
  const widgets = computed(() =>
    state.value.widgets
      .filter((item) => item.coupleId === couple.value?.id)
      .sort((a, b) => a.order - b.order),
  )
  const visibleWidgets = computed(() => widgets.value.filter((item) => item.visible))
  const alerts = computed(() =>
    state.value.alerts
      .filter((item) => item.coupleId === couple.value?.id && isAlertVisible(item))
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt)),
  )

  async function loadCouple() {
    if (!coupleSlug) {
      return
    }

    if (!supabase) {
      error.value = t('dashboard.supabaseRequired')
      state.value = emptyState
      return
    }

    await loadSupabaseCouple(coupleSlug)
  }

  async function updateWidget(widgetId: string, patch: Partial<DashboardWidget>) {
    if (!supabase) {
      throw new Error(t('dashboard.supabaseRequired'))
    }

    const { error: updateError } = await supabase.rpc('update_dashboard_widget', {
      p_widget_id: widgetId,
      p_label: patch.label ?? null,
      p_value: patch.value ?? null,
      p_unit: patch.unit ?? null,
      p_detail: patch.detail ?? null,
      p_visual: patch.visual ?? null,
      p_tone: patch.tone ?? null,
      p_numeric_value: patch.numericValue ?? null,
      p_timeline_entries: patch.timelineEntries ?? null,
      p_chart_data: patch.chartData ?? null,
      p_chart_options: patch.chartOptions ?? null,
    })

    if (updateError) {
      error.value = updateError.message
      throw updateError
    }

    await loadCouple()
  }

  async function addWidget(widget: Omit<DashboardWidget, 'id' | 'updatedAt'>) {
    if (!supabase) {
      throw new Error(t('dashboard.supabaseRequired'))
    }

    const { error: addError } = await supabase.rpc('add_dashboard_widget', {
      p_couple_id: widget.coupleId,
      p_label: widget.label,
      p_value: widget.value ?? '',
      p_unit: widget.unit ?? null,
      p_detail: widget.detail ?? '',
      p_visual: widget.visual,
      p_sort_order: widget.order,
      p_min_value: widget.min ?? null,
      p_max_value: widget.max ?? null,
      p_numeric_value: widget.numericValue ?? null,
      p_tone: widget.tone,
      p_timeline_entries: widget.timelineEntries ?? [],
      p_chart_data: widget.chartData,
      p_chart_options: widget.chartOptions,
    })

    if (addError) {
      error.value = addError.message
      throw addError
    }

    await loadCouple()
  }

  async function deleteWidget(widgetId: string) {
    if (!supabase) {
      throw new Error(t('dashboard.supabaseRequired'))
    }

    const { error: deleteError } = await supabase.rpc('delete_dashboard_widget', {
      p_widget_id: widgetId,
    })

    if (deleteError) {
      error.value = deleteError.message
      throw deleteError
    }

    await loadCouple()
  }

  async function setWidgetVisible(widgetId: string, visible: boolean) {
    if (!supabase) {
      throw new Error(t('dashboard.supabaseRequired'))
    }

    const { error: visibleError } = await supabase.rpc('set_widget_visible', {
      p_widget_id: widgetId,
      p_visible: visible,
    })

    if (visibleError) {
      error.value = visibleError.message
      throw visibleError
    }

    await loadCouple()
  }

  async function triggerAlert(alert: Omit<CoupleAlert, 'id' | 'createdAt' | 'active'>) {
    const expiresAt = alert.expiresAt ?? nextLocalMidnightIso()

    if (!supabase) {
      throw new Error(t('dashboard.supabaseRequired'))
    }

    const { error: alertError } = await supabase.rpc('trigger_couple_alert', {
      p_couple_id: alert.coupleId,
      p_title: alert.title,
      p_detail: alert.detail,
      p_severity: alert.severity,
      p_source: alert.source,
      p_triggered_by: alert.triggeredBy,
      p_expires_at: expiresAt,
      p_triggered_by_partner_id: alert.triggeredByPartnerId ?? null,
    })

    if (alertError) {
      error.value = alertError.message
      throw alertError
    }

    await loadCouple()
  }

  async function setAlertActive(alertId: string, active: boolean) {
    if (!supabase) {
      throw new Error(t('dashboard.supabaseRequired'))
    }

    const { error: alertError } = await supabase.rpc('set_alert_active', {
      p_alert_id: alertId,
      p_active: active,
    })

    if (alertError) {
      error.value = alertError.message
      throw alertError
    }

    await loadCouple()
  }

  return {
    couples,
    couple,
    widgets,
    visibleWidgets,
    alerts,
    loading: readonly(loading),
    error: readonly(error),
    loadCouple,
    updateWidget,
    addWidget,
    deleteWidget,
    setWidgetVisible,
    triggerAlert,
    setAlertActive,
  }
}
