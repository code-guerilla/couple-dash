export type WidgetScope = 'shared' | 'person'

export type WidgetVisual =
  | 'stat'
  | 'progress'
  | 'radial'
  | 'doughnut'
  | 'bar'
  | 'line'
  | 'memory'
  | 'timeline'

export type AlertSeverity = 'info' | 'success' | 'warning' | 'error'

export interface Partner {
  id: string
  slug: string
  name: string
  role: string
  accent: string
}

export interface Couple {
  id: string
  slug: string
  name: string
  subtitle: string
  relationshipStart: string
  weddingDate: string
  anniversaryDate: string
  theme: string
  partners: Partner[]
}

export interface TimelineEntry {
  id: string
  date: string
  title: string
  description: string
  icon: string
}

export interface DashboardWidget {
  id: string
  coupleId: string
  label: string
  value: string
  unit?: string
  detail: string
  scope: WidgetScope
  personId?: string
  visual: WidgetVisual
  order: number
  min?: number
  max?: number
  numericValue?: number
  tone: AlertSeverity
  visible: boolean
  timelineEntries?: TimelineEntry[]
  updatedAt: string
}

export interface CoupleAlert {
  id: string
  coupleId: string
  title: string
  detail: string
  severity: AlertSeverity
  source: 'system' | 'partner'
  active: boolean
  createdAt: string
  triggeredBy?: string
}

export interface CoupleDashboard {
  couple: Couple
  widgets: DashboardWidget[]
  alerts: CoupleAlert[]
}

export interface DashboardState {
  couples: Couple[]
  widgets: DashboardWidget[]
  alerts: CoupleAlert[]
}
