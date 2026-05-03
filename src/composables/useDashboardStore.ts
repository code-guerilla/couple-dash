import { computed, readonly, ref } from 'vue'
import { defaultState } from '@/data/defaults'
import { i18n } from '@/i18n'
import { canStorePreferences } from '@/composables/usePrivacyConsent'
import { isSupabaseConfigured, supabase } from '@/services/supabase'
import type { CoupleAlert, DashboardState, DashboardWidget } from '@/types'

const storageKey = 'couple-dash-state-v1'
const channelName = 'couple-dash-realtime'
const emptyState: DashboardState = { couples: [], widgets: [], alerts: [] }
const state = ref<DashboardState>(
  isSupabaseConfigured ? emptyState : canStorePreferences() ? loadLocalState() : cloneDefaults(),
)
const loading = ref(false)
const error = ref<string | null>(null)
const broadcast = typeof BroadcastChannel === 'undefined' ? null : new BroadcastChannel(channelName)
let activeSubscription: { unsubscribe: () => void } | null = null

function t(key: string) {
  return i18n.global.t(key)
}

broadcast?.addEventListener('message', (event: MessageEvent<DashboardState>) => {
  if (!isSupabaseConfigured) {
    state.value = event.data
  }
})

function cloneDefaults(): DashboardState {
  return JSON.parse(JSON.stringify(defaultState)) as DashboardState
}

function loadLocalState(): DashboardState {
  const stored = localStorage.getItem(storageKey)

  if (!stored) {
    return cloneDefaults()
  }

  try {
    return JSON.parse(stored) as DashboardState
  } catch {
    return cloneDefaults()
  }
}

function persistLocalState() {
  if (isSupabaseConfigured) {
    return
  }

  if (!canStorePreferences()) {
    localStorage.removeItem(storageKey)
    broadcast?.postMessage(state.value)
    return
  }

  localStorage.setItem(storageKey, JSON.stringify(state.value))
  broadcast?.postMessage(state.value)
}

function mapWidgetFromRow(row: Record<string, unknown>): DashboardWidget {
  return {
    id: String(row.id),
    coupleId: String(row.couple_id),
    label: String(row.label),
    value: String(row.value),
    unit: row.unit ? String(row.unit) : undefined,
    detail: String(row.detail ?? ''),
    scope: row.scope === 'person' ? 'person' : 'shared',
    personId: row.person_id ? String(row.person_id) : undefined,
    visual: String(row.visual ?? 'stat') as DashboardWidget['visual'],
    order: Number(row.sort_order ?? 0),
    min: row.min_value === null ? undefined : Number(row.min_value ?? 0),
    max: row.max_value === null ? undefined : Number(row.max_value ?? 100),
    numericValue: row.numeric_value === null ? undefined : Number(row.numeric_value ?? 0),
    tone: String(row.tone ?? 'info') as DashboardWidget['tone'],
    visible: Boolean(row.visible ?? true),
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
      'id, slug, name, subtitle, relationship_start, wedding_date, anniversary_date, theme, created_at, partner(id, couple_id, slug, name, role, accent, created_at)',
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
        anniversaryDate: String(couple.anniversary_date),
        theme: String(couple.theme ?? 'night'),
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
      { event: '*', schema: 'public', table: 'couple_alert', filter: `couple_id=eq.${coupleId}` },
      () => void loadSupabaseCouple(coupleSlug),
    )
    .subscribe()
}

function applyLocalWidgetUpdate(widgetId: string, patch: Partial<DashboardWidget>) {
  const index = state.value.widgets.findIndex((item) => item.id === widgetId)
  const currentWidget = state.value.widgets[index]

  if (index === -1 || !currentWidget) {
    return
  }

  state.value.widgets[index] = {
    ...currentWidget,
    ...patch,
    updatedAt: new Date().toISOString(),
  }

  persistLocalState()
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
      .filter((item) => item.coupleId === couple.value?.id && item.active)
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt)),
  )

  async function loadCouple() {
    if (!coupleSlug) {
      return
    }

    if (supabase) {
      await loadSupabaseCouple(coupleSlug)
      return
    }

    state.value = loadLocalState()
  }

  async function updateWidget(widgetId: string, patch: Partial<DashboardWidget>) {
    if (supabase) {
      const { error: updateError } = await supabase.rpc('update_dashboard_widget', {
        p_widget_id: widgetId,
        p_label: patch.label,
        p_value: patch.value,
        p_unit: patch.unit,
        p_detail: patch.detail,
        p_visual: patch.visual,
        p_tone: patch.tone,
        p_numeric_value: patch.numericValue,
      })

      if (updateError) {
        error.value = updateError.message
        throw updateError
      }

      await loadCouple()
      return
    }

    applyLocalWidgetUpdate(widgetId, patch)
  }

  async function addWidget(widget: Omit<DashboardWidget, 'id' | 'updatedAt' | 'order'>) {
    if (supabase) {
      const { error: addError } = await supabase.rpc('add_dashboard_widget', {
        p_couple_id: widget.coupleId,
        p_label: widget.label,
        p_value: widget.value,
        p_unit: widget.unit,
        p_detail: widget.detail,
        p_scope: widget.scope,
        p_person_id: widget.personId,
        p_visual: widget.visual,
        p_sort_order: widgets.value.length + 1,
        p_min_value: widget.min,
        p_max_value: widget.max,
        p_numeric_value: widget.numericValue,
        p_tone: widget.tone,
      })

      if (addError) {
        error.value = addError.message
        throw addError
      }

      await loadCouple()
      return
    }

    state.value.widgets.push({
      ...widget,
      id: crypto.randomUUID(),
      order: widgets.value.length + 1,
      visible: true,
      updatedAt: new Date().toISOString(),
    })
    persistLocalState()
  }

  async function setWidgetVisible(widgetId: string, visible: boolean) {
    if (supabase) {
      const { error: visibleError } = await supabase.rpc('set_widget_visible', {
        p_widget_id: widgetId,
        p_visible: visible,
      })

      if (visibleError) {
        error.value = visibleError.message
        throw visibleError
      }

      await loadCouple()
      return
    }

    applyLocalWidgetUpdate(widgetId, { visible })
  }

  async function triggerAlert(alert: Omit<CoupleAlert, 'id' | 'createdAt' | 'active'>) {
    if (supabase) {
      const { error: alertError } = await supabase.rpc('trigger_couple_alert', {
        p_couple_id: alert.coupleId,
        p_title: alert.title,
        p_detail: alert.detail,
        p_severity: alert.severity,
        p_source: alert.source,
        p_triggered_by: alert.triggeredBy,
      })

      if (alertError) {
        error.value = alertError.message
        throw alertError
      }

      await loadCouple()
      return
    }

    state.value.alerts.unshift({
      ...alert,
      id: crypto.randomUUID(),
      active: true,
      createdAt: new Date().toISOString(),
    })
    persistLocalState()
  }

  async function setAlertActive(alertId: string, active: boolean) {
    if (supabase) {
      const { error: alertError } = await supabase.rpc('set_alert_active', {
        p_alert_id: alertId,
        p_active: active,
      })

      if (alertError) {
        error.value = alertError.message
        throw alertError
      }

      await loadCouple()
      return
    }

    const index = state.value.alerts.findIndex((item) => item.id === alertId)
    const currentAlert = state.value.alerts[index]

    if (index !== -1 && currentAlert) {
      state.value.alerts[index] = { ...currentAlert, active }
      persistLocalState()
    }
  }

  return {
    couples,
    couple,
    widgets,
    visibleWidgets,
    alerts,
    loading: readonly(loading),
    error: readonly(error),
    isSupabaseConfigured,
    loadCouple,
    updateWidget,
    addWidget,
    setWidgetVisible,
    triggerAlert,
    setAlertActive,
  }
}
