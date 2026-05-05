import type { HungerLevelValue, Partner } from '@/types'

type HungerPartner = Pick<Partner, 'name' | 'slug' | 'hungerLevel'>

interface HungerLevelOption {
  label: string
  value: HungerLevelValue
}

const hungerLevelValues: HungerLevelValue[] = [
  'full',
  'snack',
  'getting-hungry',
  'need-food',
  'starving',
  'critical',
]

const genericOptions: HungerLevelOption[] = [
  { value: 'full', label: '😊 satt & friedlich' },
  { value: 'snack', label: '🍪 hätte nichts gegen einen Snack' },
  { value: 'getting-hungry', label: '🥪 Hunger meldet sich' },
  { value: 'need-food', label: '🍕 bitte sofort etwas zum Essen' },
  { value: 'starving', label: '😵 verhungert gerade' },
  { value: 'critical', label: '🔥 kritischer Zustand: Essen sofort finden' },
]
const fallbackHungerLevelLabel = '😊 satt & friedlich'

export function isHungerLevelValue(value: unknown): value is HungerLevelValue {
  return hungerLevelValues.includes(value as HungerLevelValue)
}

export function hungerLevelOptionsForPartner() {
  return genericOptions
}

export function hungerLevelLabelForPartner(partner: HungerPartner) {
  return (
    hungerLevelOptionsForPartner().find((option) => option.value === partner.hungerLevel)?.label ??
    fallbackHungerLevelLabel
  )
}
