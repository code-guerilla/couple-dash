<script setup lang="ts">
import Aura from '@primeuix/themes/aura'
import Lara from '@primeuix/themes/lara'
import Material from '@primeuix/themes/material'
import Nora from '@primeuix/themes/nora'
import { updatePrimaryPalette, updateSurfacePalette, usePreset } from '@primeuix/themes'
import Button from 'primevue/button'
import { usePrimeVue } from 'primevue/config'
import Popover from 'primevue/popover'
import SelectButton from 'primevue/selectbutton'
import ToggleSwitch from 'primevue/toggleswitch'
import { onMounted, reactive, ref, watch } from 'vue'

const STORAGE_KEY = 'couple-dash-prime-theme'

type PresetName = 'Aura' | 'Material' | 'Lara' | 'Nora'

const primevue = usePrimeVue()
const popover = ref<InstanceType<typeof Popover> | null>(null)

const presetMap = {
  Aura,
  Material,
  Lara,
  Nora,
} satisfies Record<PresetName, unknown>

const presetOptions = Object.keys(presetMap) as PresetName[]

const colorScale = (name: string) => ({
  50: `{${name}.50}`,
  100: `{${name}.100}`,
  200: `{${name}.200}`,
  300: `{${name}.300}`,
  400: `{${name}.400}`,
  500: `{${name}.500}`,
  600: `{${name}.600}`,
  700: `{${name}.700}`,
  800: `{${name}.800}`,
  900: `{${name}.900}`,
  950: `{${name}.950}`,
})

const primaryPalettes = [
  { name: 'emerald', color: '#10b981' },
  { name: 'green', color: '#22c55e' },
  { name: 'lime', color: '#84cc16' },
  { name: 'orange', color: '#f97316' },
  { name: 'amber', color: '#f59e0b' },
  { name: 'yellow', color: '#eab308' },
  { name: 'teal', color: '#14b8a6' },
  { name: 'cyan', color: '#06b6d4' },
  { name: 'sky', color: '#0ea5e9' },
  { name: 'blue', color: '#3b82f6' },
  { name: 'indigo', color: '#6366f1' },
  { name: 'violet', color: '#8b5cf6' },
  { name: 'purple', color: '#a855f7' },
  { name: 'fuchsia', color: '#d946ef' },
  { name: 'pink', color: '#ec4899' },
  { name: 'rose', color: '#f43f5e' },
]

const surfacePalettes = [
  { name: 'slate', color: '#64748b' },
  { name: 'gray', color: '#6b7280' },
  { name: 'zinc', color: '#71717a' },
  { name: 'neutral', color: '#737373' },
  { name: 'stone', color: '#78716c' },
]

const settings = reactive({
  primary: 'indigo',
  surface: 'slate',
  preset: 'Aura' as PresetName,
  ripple: true,
  dark: false,
})

function toggle(event: Event) {
  popover.value?.toggle(event)
}

function applySettings() {
  usePreset(presetMap[settings.preset])
  updatePrimaryPalette(colorScale(settings.primary))
  updateSurfacePalette(colorScale(settings.surface))

  primevue.config.ripple = settings.ripple
  document.documentElement.classList.toggle('app-dark', settings.dark)
  localStorage.setItem(STORAGE_KEY, JSON.stringify(settings))
}

onMounted(() => {
  const saved = localStorage.getItem(STORAGE_KEY)

  if (saved) {
    Object.assign(settings, JSON.parse(saved))
  }

  applySettings()
})

watch(settings, applySettings, { deep: true })
</script>

<template>
  <Button aria-label="Theme settings" outlined size="small" type="button" @click="toggle">
    <span class="inline-block h-3 w-3 rounded-full" :style="{ background: `var(--p-${settings.primary}-500)` }" />
  </Button>

  <Popover ref="popover" class="theme-popover">
    <div class="theme-grid">
      <div>
        <div class="theme-label mb-2">Primary</div>
        <div class="swatch-row">
          <button
            v-for="palette in primaryPalettes"
            :key="palette.name"
            :aria-label="`Use ${palette.name} primary`"
            class="theme-swatch"
            :data-active="settings.primary === palette.name"
            :style="{ '--swatch-color': palette.color }"
            type="button"
            @click="settings.primary = palette.name"
          />
        </div>
      </div>

      <div>
        <div class="theme-label mb-2">Surface</div>
        <div class="swatch-row">
          <button
            v-for="palette in surfacePalettes"
            :key="palette.name"
            :aria-label="`Use ${palette.name} surface`"
            class="theme-swatch"
            :data-active="settings.surface === palette.name"
            :style="{ '--swatch-color': palette.color }"
            type="button"
            @click="settings.surface = palette.name"
          />
        </div>
      </div>

      <div>
        <div class="theme-label mb-2">Theme</div>
        <SelectButton v-model="settings.preset" :allow-empty="false" :options="presetOptions" size="small" />
      </div>

      <div class="theme-row">
        <span class="theme-label">Ripple</span>
        <ToggleSwitch v-model="settings.ripple" />
      </div>
      <div class="theme-row">
        <span class="theme-label">Dark</span>
        <ToggleSwitch v-model="settings.dark" />
      </div>
    </div>
  </Popover>
</template>
