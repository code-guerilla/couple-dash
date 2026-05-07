import type { BatteryLevelValue, Partner } from '@/types'

type BatteryPartner = Pick<Partner, 'name' | 'slug' | 'batteryLevel'>

interface BatteryLevelOption {
  label: string
  value: BatteryLevelValue
}

const batteryLevelValues: BatteryLevelValue[] = [
  'Absolut ausgelaugt - alles absagen',
  'Pause benötigt - Sofazeit',
  'Kleiner Spaziergang wär super',
  'Voll geladen und motiviert - Lass uns was starten',
]

const genericOptions: BatteryLevelOption[] = [
  {
    value: 'Absolut ausgelaugt - alles absagen',
    label: 'Absolut ausgelaugt - alles absagen',
  },
  { value: 'Pause benötigt - Sofazeit', label: 'Pause benötigt - Sofazeit' },
  { value: 'Kleiner Spaziergang wär super', label: 'Kleiner Spaziergang wär super' },
  {
    value: 'Voll geladen und motiviert - Lass uns was starten',
    label: 'Voll geladen und motiviert - Lass uns was starten',
  },
]
const fallbackBatteryLevelLabel = 'Voll geladen und motiviert - Lass uns was starten'

const legacyBatteryLevelValues: Record<string, BatteryLevelValue> = {
  'Voll motiviert - Lass uns Ausgehen': 'Voll geladen und motiviert - Lass uns was starten',
  Kuschelbedürftig: 'Kleiner Spaziergang wär super',
  Hangry: 'Absolut ausgelaugt - alles absagen',
  'Im Tunnel': 'Pause benötigt - Sofazeit',
}

export function normalizeBatteryLevelValue(value: unknown): BatteryLevelValue {
  if (batteryLevelValues.includes(value as BatteryLevelValue)) {
    return value as BatteryLevelValue
  }

  if (typeof value === 'string' && legacyBatteryLevelValues[value]) {
    return legacyBatteryLevelValues[value]
  }

  return fallbackBatteryLevelLabel
}

export function isBatteryLevelValue(value: unknown): value is BatteryLevelValue {
  return batteryLevelValues.includes(value as BatteryLevelValue)
}

export function batteryLevelOptionsForPartner() {
  return genericOptions
}

export function batteryLevelLabelForPartner(partner: BatteryPartner) {
  return (
    batteryLevelOptionsForPartner().find(
      (option) => option.value === normalizeBatteryLevelValue(partner.batteryLevel),
    )?.label ?? fallbackBatteryLevelLabel
  )
}
