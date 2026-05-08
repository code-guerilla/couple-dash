export type WidgetVisual = 'stat' | 'progress' | 'radial' | 'memory' | 'timeline'

export type AlertSeverity = 'info' | 'success' | 'warning' | 'error'

export type HungerLevelValue =
  | 'Absolut vollgefressen'
  | 'Kleiner Snack wär nice'
  | 'Alles normal'
  | 'Hungrig'
  | 'Richtig hungrig'
  | 'Am Verhungern'

export type BatteryLevelValue =
  | 'Absolut ausgelaugt - alles absagen'
  | 'Pause benötigt - Sofazeit'
  | 'Kleiner Spaziergang wär super'
  | 'Voll geladen und motiviert - Lass uns was starten'

export interface Partner {
  id: string
  slug: string
  name: string
  role: string
  accent: string
  hungerLevel: HungerLevelValue
  batteryLevel: BatteryLevelValue
  avatarPath?: string
  avatarUrl?: string
  avatarFallback?: string
}

export interface Couple {
  id: string
  slug: string
  name: string
  subtitle: string
  relationshipStart: string
  weddingDate: string
  choreTurnPartnerId?: string
  partners: Partner[]
}

export interface CoupleChoreTask {
  id: string
  coupleId: string
  title: string
  icon: string
  assignedPartnerId?: string
  order: number
  updatedAt: string
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
  expiresAt?: string
  triggeredByPartnerId?: string
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
  choreTasks: CoupleChoreTask[]
  alerts: CoupleAlert[]
}
