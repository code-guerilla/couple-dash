import type {
  AlertSeverity,
  Couple,
  CoupleAlert,
  DashboardState,
  DashboardWidget,
  TimelineEntry,
} from '@/types'

const now = new Date().toISOString()
const nextMidnight = (() => {
  const expiresAt = new Date()
  expiresAt.setHours(24, 0, 0, 0)
  return expiresAt.toISOString()
})()

export const defaultCouples: Couple[] = [
  {
    id: 'couple-paul-anna',
    slug: 'paul-anna',
    name: 'Paul + Anna',
    subtitle: 'Kitchen table production environment',
    relationshipStart: '2018-04-04',
    weddingDate: '2026-08-22',
    partners: [
      {
        id: 'partner-paul',
        slug: 'paul',
        name: 'Paul',
        role: 'SnackOps lead',
        accent: 'primary',
      },
      {
        id: 'partner-anna',
        slug: 'anna',
        name: 'Anna',
        role: 'Mood reliability engineer',
        accent: 'secondary',
      },
    ],
  },
  {
    id: 'couple-lina-tom',
    slug: 'lina-tom',
    name: 'Lina + Tom',
    subtitle: 'Home happiness control plane',
    relationshipStart: '2020-10-17',
    weddingDate: '2026-09-12',
    partners: [
      {
        id: 'partner-lina',
        slug: 'lina',
        name: 'Lina',
        role: 'Calendar incident commander',
        accent: 'accent',
      },
      {
        id: 'partner-tom',
        slug: 'tom',
        name: 'Tom',
        role: 'Coffee dependency manager',
        accent: 'info',
      },
    ],
  },
]

const widget = (
  coupleId: string,
  id: string,
  label: string,
  value: string,
  detail: string,
  order: number,
  options: Partial<DashboardWidget> = {},
): DashboardWidget => ({
  id: `${coupleId}-${id}`,
  coupleId,
  label,
  value,
  detail,
  visual: 'stat',
  order,
  tone: 'info',
  visible: true,
  chartData: [],
  chartOptions: {},
  updatedAt: now,
  ...options,
})

const timelineEntry = (
  id: string,
  date: string,
  title: string,
  description: string,
  icon: string,
): TimelineEntry => ({
  id,
  date,
  title,
  description,
  icon,
})

const defaultTimelineEntries = (
  relationshipStart: string,
  weddingDate: string,
): TimelineEntry[] => [
  timelineEntry(
    'first-met',
    relationshipStart,
    'First Met',
    'The first chapter of the story.',
    'i-lucide-sparkles',
  ),
  timelineEntry(
    'wedding',
    weddingDate,
    'The Wedding',
    'The big day on the shared calendar.',
    'i-lucide-church',
  ),
]

export const defaultWidgets: DashboardWidget[] = [
  widget(
    'couple-paul-anna',
    'timeline',
    'Our Timeline',
    '2 milestones',
    'The relationship milestones that make the dashboard personal.',
    1,
    {
      visual: 'timeline',
      tone: 'success',
      timelineEntries: defaultTimelineEntries('2018-04-04', '2026-08-22'),
    },
  ),
  widget(
    'couple-paul-anna',
    'uptime',
    'Relationship Uptime',
    '8y 22d',
    'No known outages since launch.',
    2,
    {
      tone: 'success',
      visual: 'stat',
    },
  ),
  widget(
    'couple-paul-anna',
    'commitment',
    'Commitment Level',
    '100',
    'Permanent contract signed emotionally.',
    4,
    {
      unit: '%',
      visual: 'progress',
      numericValue: 100,
      max: 100,
      tone: 'success',
    },
  ),
  widget(
    'couple-paul-anna',
    'sla',
    'Love SLA',
    '99.999',
    'Measured over all couch deployments.',
    5,
    {
      unit: '%',
      visual: 'progress',
      numericValue: 99,
      max: 100,
      tone: 'success',
    },
  ),
  widget(
    'couple-paul-anna',
    'memories',
    'Shared Memories Indexed',
    '186',
    'Photos, trips, tiny jokes, and excellent meals.',
    6,
    {
      visual: 'stat',
      tone: 'info',
    },
  ),
  widget(
    'couple-paul-anna',
    'status',
    'Current Couple Status',
    'Production Stable',
    'All core services operational.',
    7,
    {
      visual: 'stat',
      tone: 'success',
    },
  ),
  widget(
    'couple-paul-anna',
    'forgiveness',
    'Time to Forgive After Fight',
    '14m',
    'Drops to 4m when dessert is involved.',
    8,
    {
      visual: 'progress',
      numericValue: 14,
      max: 60,
      tone: 'success',
    },
  ),
  widget(
    'couple-paul-anna',
    'dinner-latency',
    'Dinner Decision Latency',
    '47m',
    'Decision quorum remains complicated.',
    9,
    {
      visual: 'progress',
      numericValue: 47,
      max: 60,
      tone: 'warning',
    },
  ),
  widget(
    'couple-paul-anna',
    'hug-quota',
    'Daily Hug Quota',
    '8 / 12',
    'Four hugs remain before midnight.',
    10,
    {
      visual: 'progress',
      numericValue: 66,
      max: 100,
      tone: 'info',
    },
  ),
  widget(
    'couple-paul-anna',
    'cuddle-bandwidth',
    'Cuddle Bandwidth',
    'High',
    'Streaming available in 4K comfort.',
    11,
    {
      visual: 'stat',
      tone: 'success',
    },
  ),
  widget(
    'couple-paul-anna',
    'weekend',
    'Weekend Allocation',
    '40% sofa / 35% friends / 25% naps',
    'Balanced but nap capacity can scale.',
    12,
    {
      visual: 'bar',
      numericValue: 40,
      tone: 'info',
    },
  ),
  widget(
    'couple-paul-anna',
    'latest-memory',
    'Latest Shared Memory',
    'Tried a new ramen place and rated broth like engineers.',
    'Indexed 2 hours ago.',
    13,
    {
      visual: 'memory',
      tone: 'success',
    },
  ),
  widget(
    'couple-paul-anna',
    'relationship-mix',
    'Woraus die Beziehung besteht',
    '100%',
    'Liebe, Kaffee und Essensdiskussionen in einem wissenschaftlich fragwürdigen Mix.',
    14,
    {
      visual: 'donut',
      tone: 'success',
      chartData: [
        { label: 'Liebe', value: 40 },
        { label: 'Kaffee', value: 20 },
        { label: 'Diskussionen über Essen', value: 25 },
        { label: 'Gemeinsame Serien', value: 15 },
      ],
      chartOptions: {
        centralLabel: 'Beziehungs-Mix',
        centralSubLabel: 'wissenschaftlich fragwürdig',
      },
    },
  ),
  widget(
    'couple-paul-anna',
    'discussion-wins',
    'Gewonnene Diskussionen',
    '75%',
    'Beide tun so, als hätten sie gewonnen.',
    15,
    {
      visual: 'donut',
      tone: 'warning',
      chartData: [
        { label: 'Partner A', value: 12 },
        { label: 'Partner B', value: 13 },
        { label: 'Beide gewonnen', value: 75 },
      ],
      chartOptions: {
        centralLabel: '75%',
        centralSubLabel: 'diplomatischer Sieg',
      },
    },
  ),
  widget(
    'couple-paul-anna',
    'relationship-topics',
    'Top Beziehungsthemen',
    '87',
    'Ranking der wichtigsten Haushaltskonferenzen.',
    16,
    {
      visual: 'bar',
      tone: 'info',
      chartData: [
        { label: 'Was essen wir?', value: 87 },
        { label: 'Wo sind die Schlüssel?', value: 42 },
        { label: 'Noch eine Folge?', value: 64 },
      ],
    },
  ),
  widget(
    'couple-paul-anna',
    'romance-trend',
    'Romantik im Zeitverlauf',
    '100',
    'Fake Trend, echte Gefühle.',
    17,
    {
      visual: 'line',
      tone: 'success',
      chartData: [
        { label: 'Kennenlernen', value: 80 },
        { label: 'Erster Urlaub', value: 95 },
        { label: 'Umzug', value: 62 },
        { label: 'Hochzeit', value: 100 },
      ],
    },
  ),
  widget(
    'couple-lina-tom',
    'timeline',
    'Our Timeline',
    '2 milestones',
    'The relationship milestones that make the dashboard personal.',
    1,
    {
      visual: 'timeline',
      tone: 'success',
      timelineEntries: defaultTimelineEntries('2020-10-17', '2026-09-12'),
    },
  ),
  widget(
    'couple-lina-tom',
    'uptime',
    'Relationship Uptime',
    '5y 191d',
    'Healthy and passing checks.',
    2,
    {
      tone: 'success',
      visual: 'stat',
    },
  ),
  widget(
    'couple-lina-tom',
    'commitment',
    'Commitment Level',
    '100',
    'No rollback plan detected.',
    3,
    {
      unit: '%',
      visual: 'progress',
      numericValue: 100,
      max: 100,
      tone: 'success',
    },
  ),
  widget(
    'couple-lina-tom',
    'coffee',
    'Coffee Requirement',
    'Elevated',
    'One more cappuccino likely needed.',
    4,
    {
      visual: 'stat',
      tone: 'warning',
    },
  ),
  widget(
    'couple-lina-tom',
    'memory',
    'Latest Shared Memory',
    'Bought wedding shoes, celebrated with fries.',
    'Pinned by both partners.',
    5,
    {
      visual: 'memory',
      tone: 'success',
    },
  ),
  widget(
    'couple-lina-tom',
    'relationship-mix',
    'Woraus die Beziehung besteht',
    '100%',
    'Liebe, Kaffee und Essensdiskussionen in einem wissenschaftlich fragwürdigen Mix.',
    6,
    {
      visual: 'donut',
      tone: 'success',
      chartData: [
        { label: 'Liebe', value: 40 },
        { label: 'Kaffee', value: 20 },
        { label: 'Diskussionen über Essen', value: 25 },
        { label: 'Gemeinsame Serien', value: 15 },
      ],
      chartOptions: {
        centralLabel: 'Beziehungs-Mix',
        centralSubLabel: 'wissenschaftlich fragwürdig',
      },
    },
  ),
  widget(
    'couple-lina-tom',
    'relationship-topics',
    'Top Beziehungsthemen',
    '87',
    'Ranking der wichtigsten Haushaltskonferenzen.',
    7,
    {
      visual: 'bar',
      tone: 'info',
      chartData: [
        { label: 'Was essen wir?', value: 87 },
        { label: 'Wo sind die Schlüssel?', value: 42 },
        { label: 'Noch eine Folge?', value: 64 },
      ],
    },
  ),
  widget(
    'couple-lina-tom',
    'romance-trend',
    'Romantik im Zeitverlauf',
    '100',
    'Fake Trend, echte Gefühle.',
    8,
    {
      visual: 'line',
      tone: 'success',
      chartData: [
        { label: 'Kennenlernen', value: 80 },
        { label: 'Erster Urlaub', value: 95 },
        { label: 'Umzug', value: 62 },
        { label: 'Hochzeit', value: 100 },
      ],
    },
  ),
]

export const defaultAlerts: CoupleAlert[] = [
  {
    id: 'alert-snack-shortage',
    coupleId: 'couple-paul-anna',
    title: 'Snack shortage detected',
    detail: 'Pantry telemetry below acceptable movie-night threshold.',
    severity: 'warning',
    source: 'system',
    active: true,
    createdAt: now,
    expiresAt: nextMidnight,
  },
  {
    id: 'alert-cuddle',
    coupleId: 'couple-paul-anna',
    title: 'Cuddle maintenance overdue',
    detail: 'Recommended maintenance window: tonight after dishes.',
    severity: 'error',
    source: 'partner',
    active: true,
    createdAt: now,
    expiresAt: nextMidnight,
    triggeredBy: 'Anna',
  },
  {
    id: 'alert-dishwasher',
    coupleId: 'couple-paul-anna',
    title: 'Dishwasher loaded incorrectly',
    detail: 'Fork placement violates household architecture guidelines.',
    severity: 'warning',
    source: 'partner',
    active: true,
    createdAt: now,
    expiresAt: nextMidnight,
    triggeredBy: 'Paul',
  },
  {
    id: 'alert-nothing',
    coupleId: 'couple-paul-anna',
    title: 'One partner said "nothing"',
    detail: 'Semantic parser detected elevated "something" probability.',
    severity: 'error',
    source: 'system',
    active: true,
    createdAt: now,
    expiresAt: nextMidnight,
  },
]

export const defaultState: DashboardState = {
  couples: defaultCouples,
  widgets: defaultWidgets,
  alerts: defaultAlerts,
}

export interface AlertTemplate {
  id: string
  partnerName: string
  partnerIndex: number
  text: string
  severity: AlertSeverity
}

export const alertTemplates: AlertTemplate[] = [
  {
    id: 'tom-beer',
    partnerName: 'Tom',
    partnerIndex: 0,
    text: 'benötigt ein Bier 🍺',
    severity: 'info',
  },
  {
    id: 'lisa-going-out',
    partnerName: 'Lisa',
    partnerIndex: 1,
    text: 'Möchte mal wieder ausgehen 💃',
    severity: 'info',
  },
  {
    id: 'lisa-dinner',
    partnerName: 'Lisa',
    partnerIndex: 1,
    text: 'Möchte mal wieder Essen gehen 🍕',
    severity: 'info',
  },
  {
    id: 'tom-beach',
    partnerName: 'Tom',
    partnerIndex: 0,
    text: 'Braucht Strand 🏖️',
    severity: 'info',
  },
]
