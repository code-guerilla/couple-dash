import type { HungerLevelValue, Partner } from '@/types'

type HungerPartner = Pick<Partner, 'name' | 'slug' | 'hungerLevel'>

interface HungerLevelOption {
  label: string
  value: HungerLevelValue
}

const hungerLevelValues: HungerLevelValue[] = [
  'Voll motiviert - Lass uns Ausgehen',
  'Kuschelbedürftig',
  'Hangry',
  'Im Tunnel',
  'Pause benötigt - Sofazeit',
]

const genericOptions: HungerLevelOption[] = [
  {
    value: 'Voll motiviert - Lass uns Ausgehen',
    label: 'Voll motiviert - Lass uns Ausgehen',
  },
  { value: 'Kuschelbedürftig', label: 'Kuschelbedürftig' },
  { value: 'Hangry', label: 'Hangry' },
  { value: 'Im Tunnel', label: 'Im Tunnel' },
  { value: 'Pause benötigt - Sofazeit', label: 'Pause benötigt - Sofazeit' },
]
const fallbackHungerLevelLabel = 'Voll motiviert - Lass uns Ausgehen'

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
