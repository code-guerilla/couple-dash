import colors from 'tailwindcss/colors'
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useAppConfig } from '@nuxt/ui/runtime/vue/composables/useAppConfig.js'

type ColorMode = 'light' | 'dark' | 'system'

type ThemeState = {
  primary: string
  neutral: string
  radius: number
  font: string
  mode: ColorMode
}

const STORAGE_KEY = 'couple-dash-theme'

const neutralColors = [
  'slate',
  'gray',
  'zinc',
  'neutral',
  'stone',
  'taupe',
  'mauve',
  'mist',
  'olive',
]
const primaryColors = Object.keys(colors).filter((color) => {
  return !['inherit', 'current', 'transparent', 'black', 'white', ...neutralColors].includes(color)
})
const radiuses = [0, 0.125, 0.25, 0.375, 0.5]
const fonts = ['Public Sans', 'DM Sans', 'Geist', 'Inter', 'Poppins', 'Outfit', 'Raleway']

const defaultTheme: ThemeState = {
  primary: 'green',
  neutral: 'slate',
  radius: 0.25,
  font: 'Public Sans',
  mode: 'system',
}

const theme = ref<ThemeState>({ ...defaultTheme })
const systemDark = ref(false)
let initialized = false
let media: MediaQueryList | undefined

function readTheme() {
  try {
    const saved = window.localStorage.getItem(STORAGE_KEY)

    if (saved) {
      theme.value = { ...defaultTheme, ...JSON.parse(saved) }
    }
  } catch {
    theme.value = { ...defaultTheme }
  }
}

function setClass(name: string, active: boolean) {
  document.documentElement.classList.toggle(name, active)
}

function applyTheme() {
  const activeMode =
    theme.value.mode === 'system' ? (systemDark.value ? 'dark' : 'light') : theme.value.mode
  const root = document.documentElement
  const appConfig = useAppConfig()

  appConfig.ui.colors.primary = theme.value.primary
  appConfig.ui.colors.neutral = theme.value.neutral

  setClass('light', activeMode === 'light')
  setClass('dark', activeMode === 'dark')
  setClass('app-dark', activeMode === 'dark')
  root.style.setProperty('--ui-radius', `${theme.value.radius}rem`)
  root.style.setProperty('--font-sans', `"${theme.value.font}"`)
  root.style.colorScheme = activeMode
  loadFont(theme.value.font)

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(theme.value))
}

function loadFont(font: string) {
  let link = document.getElementById('couple-dash-font') as HTMLLinkElement | null

  if (!link) {
    link = document.createElement('link')
    link.id = 'couple-dash-font'
    link.rel = 'stylesheet'
    document.head.appendChild(link)
  }

  link.href = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(font)}:wght@400;500;600;700;800;900&display=swap`
}

function updateSystemMode() {
  systemDark.value = Boolean(media?.matches)
  applyTheme()
}

export function useThemeSettings() {
  if (!initialized && typeof window !== 'undefined') {
    initialized = true
    media = window.matchMedia('(prefers-color-scheme: dark)')
    readTheme()
    updateSystemMode()
    media.addEventListener('change', updateSystemMode)
  }

  onMounted(applyTheme)
  onUnmounted(() => {
    media?.removeEventListener('change', updateSystemMode)
  })

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

  const mode = computed({
    get: () => theme.value.mode,
    set: (value: ColorMode) => {
      theme.value.mode = value
    },
  })

  const modes = computed(() => [
    { label: 'Light', value: 'light' as const, icon: 'i-lucide-sun' },
    { label: 'Dark', value: 'dark' as const, icon: 'i-lucide-moon' },
    { label: 'System', value: 'system' as const, icon: 'i-lucide-monitor' },
  ])

  return {
    neutralColors,
    neutral,
    primaryColors,
    primary,
    radiuses,
    radius,
    fonts,
    font,
    modes,
    mode,
  }
}
