import { computed, onMounted, ref, watch } from 'vue'
import { useAppConfig } from '@nuxt/ui/runtime/vue/composables/useAppConfig.js'

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
const fonts = ['Public Sans', 'DM Sans', 'Geist', 'Inter', 'Poppins', 'Outfit', 'Raleway']

const defaultTheme: ThemeState = {
  primary: 'green',
  neutral: 'slate',
  radius: 0.25,
  font: 'Public Sans',
}

const theme = ref<ThemeState>({ ...defaultTheme })
let hasReadSavedTheme = false

function readTheme() {
  if (hasReadSavedTheme || typeof window === 'undefined') {
    return
  }

  hasReadSavedTheme = true

  try {
    const saved = window.localStorage.getItem(STORAGE_KEY)

    if (saved) {
      theme.value = { ...defaultTheme, ...JSON.parse(saved) }
    }
  } catch {
    theme.value = { ...defaultTheme }
  }
}

function loadFont(font: string) {
  if (typeof document === 'undefined') {
    return
  }

  let link = document.getElementById('couple-dash-font') as HTMLLinkElement | null

  if (!link) {
    link = document.createElement('link')
    link.id = 'couple-dash-font'
    link.rel = 'stylesheet'
    document.head.appendChild(link)
  }

  link.href = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(font)}:wght@400;500;600;700;800;900&display=swap`
}

export function useThemeSettings() {
  const appConfig = useAppConfig()

  function applyTheme() {
    appConfig.ui.colors.primary = theme.value.primary
    appConfig.ui.colors.neutral = theme.value.neutral

    if (typeof document !== 'undefined') {
      document.documentElement.style.setProperty('--ui-radius', `${theme.value.radius}rem`)
      document.documentElement.style.setProperty('--font-sans', `"${theme.value.font}"`)
    }

    loadFont(theme.value.font)

    if (typeof window !== 'undefined') {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(theme.value))
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
      theme.value.font = value
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
