import { computed, onMounted, ref, watch } from 'vue'
import { useAppConfig } from '@nuxt/ui/runtime/vue/composables/useAppConfig.js'
import { canStorePreferences } from '@/composables/usePrivacyConsent'

type ThemeState = {
  primary: string
  neutral: string
  radius: number
  font: string
}

const STORAGE_KEY = 'couple-dash-theme'

const primaryColors = [
  'red',
  'orange',
  'amber',
  'yellow',
  'lime',
  'green',
  'emerald',
  'teal',
  'cyan',
  'sky',
  'blue',
  'indigo',
  'violet',
  'purple',
  'fuchsia',
  'pink',
  'rose',
]
const neutralColors = ['slate', 'gray', 'zinc', 'neutral', 'stone']
const radiuses = [0, 0.125, 0.25, 0.375, 0.5]
const fontStacks = {
  Inter: '"Inter", system-ui, sans-serif',
  'Atkinson Hyperlegible': '"Atkinson Hyperlegible", system-ui, sans-serif',
  Merriweather: '"Merriweather", Georgia, serif',
  'JetBrains Mono': '"JetBrains Mono", ui-monospace, monospace',
  'Playfair Display': '"Playfair Display", Georgia, serif',
} as const
const fonts = Object.keys(fontStacks)

const defaultTheme: ThemeState = {
  primary: 'green',
  neutral: 'slate',
  radius: 0.25,
  font: 'Inter',
}

const theme = ref<ThemeState>({ ...defaultTheme })
let hasReadSavedTheme = false

function normalizeTheme(value: Partial<ThemeState>): ThemeState {
  return {
    ...defaultTheme,
    ...value,
    font: value.font && value.font in fontStacks ? value.font : defaultTheme.font,
  }
}

function readTheme() {
  if (hasReadSavedTheme || typeof window === 'undefined') {
    return
  }

  hasReadSavedTheme = true

  if (!canStorePreferences()) {
    return
  }

  try {
    const saved = window.localStorage.getItem(STORAGE_KEY)

    if (saved) {
      theme.value = normalizeTheme(JSON.parse(saved))
    }
  } catch {
    theme.value = { ...defaultTheme }
  }
}

function getFontStack(font: string) {
  return fontStacks[font as keyof typeof fontStacks] ?? fontStacks.Inter
}

export function useThemeSettings() {
  const appConfig = useAppConfig()

  function applyTheme() {
    appConfig.ui.colors.primary = theme.value.primary
    appConfig.ui.colors.neutral = theme.value.neutral

    if (typeof document !== 'undefined') {
      document.documentElement.style.setProperty('--ui-radius', `${theme.value.radius}rem`)
      document.documentElement.style.setProperty('--font-sans', getFontStack(theme.value.font))
    }

    if (typeof window !== 'undefined') {
      if (canStorePreferences()) {
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(theme.value))
      } else {
        window.localStorage.removeItem(STORAGE_KEY)
      }
    }
  }

  readTheme()
  onMounted(applyTheme)
  watch(theme, applyTheme, { deep: true })

  const primary = computed({
    get: () => theme.value.primary,
    set: (value: string) => {
      theme.value.primary = value
    },
  })

  const neutral = computed({
    get: () => theme.value.neutral,
    set: (value: string) => {
      theme.value.neutral = value
    },
  })

  const radius = computed({
    get: () => theme.value.radius,
    set: (value: number) => {
      theme.value.radius = value
    },
  })

  const font = computed({
    get: () => theme.value.font,
    set: (value: string) => {
      theme.value.font = value in fontStacks ? value : defaultTheme.font
    },
  })

  return {
    neutralColors,
    neutral,
    primaryColors,
    primary,
    radiuses,
    radius,
    fonts,
    font,
  }
}
