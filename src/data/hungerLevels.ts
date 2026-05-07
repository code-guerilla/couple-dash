import type { HungerLevelValue, Partner } from '@/types'

type HungerPartner = Pick<Partner, 'name' | 'slug' | 'hungerLevel'>

interface HungerLevelOption {
  label: string
  value: HungerLevelValue
}

const hungerLevelValues: HungerLevelValue[] = [
  'Absolut vollgefressen',
  'Kleiner Snack wär nice',
  'Alles normal',
  'Hungrig',
  'Richtig hungrig',
  'Am Verhungern',
]

const genericOptions: HungerLevelOption[] = [
  { value: 'Absolut vollgefressen', label: 'Absolut vollgefressen' },
  { value: 'Kleiner Snack wär nice', label: 'Kleiner Snack wär nice' },
  { value: 'Alles normal', label: 'Alles normal' },
  { value: 'Hungrig', label: 'Hungrig' },
  { value: 'Richtig hungrig', label: 'Richtig hungrig' },
  { value: 'Am Verhungern', label: 'Am Verhungern' },
]
const fallbackHungerLevelLabel = 'Alles normal'

const legacyHungerLevelValues: Record<string, HungerLevelValue> = {
  'Voll motiviert - Lass uns Ausgehen': 'Alles normal',
  Kuschelbedürftig: 'Kleiner Snack wär nice',
  Hangry: 'Richtig hungrig',
  'Im Tunnel': 'Hungrig',
  'Pause benötigt - Sofazeit': 'Kleiner Snack wär nice',
  'Absolut ausgelaugt - alles absagen': 'Am Verhungern',
  'Kleiner Spaziergang wär super': 'Kleiner Snack wär nice',
  'Voll geladen und motiviert - Lass uns was starten': 'Alles normal',
}

export function normalizeHungerLevelValue(value: unknown): HungerLevelValue {
  if (hungerLevelValues.includes(value as HungerLevelValue)) {
    return value as HungerLevelValue
  }

  if (typeof value === 'string' && legacyHungerLevelValues[value]) {
    return legacyHungerLevelValues[value]
  }

  return fallbackHungerLevelLabel
}

export function isHungerLevelValue(value: unknown): value is HungerLevelValue {
  return hungerLevelValues.includes(value as HungerLevelValue)
}

export function hungerLevelOptionsForPartner() {
  return genericOptions
}

export function hungerLevelLabelForPartner(partner: HungerPartner) {
  return (
    hungerLevelOptionsForPartner().find(
      (option) => option.value === normalizeHungerLevelValue(partner.hungerLevel),
    )?.label ?? fallbackHungerLevelLabel
  )
}
