import type { AlertSeverity } from '@/types'

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
