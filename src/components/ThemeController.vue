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
import { onMounted, reactive, ref, watch } from 'vue'

const STORAGE_KEY = 'couple-dash-prime-theme'

type PresetName = 'Aura' | 'Material' | 'Lara' | 'Nora'
type SurfaceStyle = 'solid' | 'liquid-glass'
type PaletteOption = {
  name: string
  color: string
}

const primevue = usePrimeVue()
const popover = ref<InstanceType<typeof Popover> | null>(null)

const presetMap = {
  Aura,
  Material,
  Lara,
  Nora,
} satisfies Record<PresetName, unknown>

const presetOptions = Object.keys(presetMap) as PresetName[]

const customPalettes: Record<string, Record<number, string>> = {
  brown: {
    50: '#f7f1eb',
    100: '#eadbcc',
    200: '#d8bea3',
    300: '#c49d77',
    400: '#a8794f',
    500: '#8b5e34',
    600: '#744a28',
    700: '#5d3a22',
    800: '#4c3020',
    900: '#40291d',
    950: '#24150d',
  },
  sage: {
    50: '#f1f5ef',
    100: '#dfe9dc',
    200: '#c3d4bf',
    300: '#9fb99c',
    400: '#7f9f7f',
    500: '#6b8f71',
    600: '#527058',
    700: '#415946',
    800: '#36483a',
    900: '#2d3c31',
    950: '#172219',
  },
  moss: {
    50: '#f3f6ea',
    100: '#e4ebcf',
    200: '#cad8a3',
    300: '#aabd70',
    400: '#849947',
    500: '#5f7a3a',
    600: '#4c642d',
    700: '#3c4e25',
    800: '#333f22',
    900: '#2c371f',
    950: '#151e0d',
  },
  clay: {
    50: '#fbf1ee',
    100: '#f5ded7',
    200: '#ebc0b5',
    300: '#dc9989',
    400: '#c97762',
    500: '#b46a55',
    600: '#964b39',
    700: '#7d3c2e',
    800: '#693329',
    900: '#592f28',
    950: '#321712',
  },
  terracotta: {
    50: '#fdf0eb',
    100: '#fadccc',
    200: '#f4b99d',
    300: '#ea8d68',
    400: '#dc704b',
    500: '#c65f3f',
    600: '#a5422b',
    700: '#853323',
    800: '#6f2d22',
    900: '#5f2a21',
    950: '#36140e',
  },
  olive: {
    50: '#f7f7e9',
    100: '#ebedc9',
    200: '#d7db97',
    300: '#bdc35f',
    400: '#989f3e',
    500: '#737a3c',
    600: '#5c622f',
    700: '#474c27',
    800: '#3b3f24',
    900: '#333721',
    950: '#1a1d0d',
  },
  sand: {
    50: '#faf5eb',
    100: '#f0e3c9',
    200: '#e2ca97',
    300: '#d3ad64',
    400: '#c7984c',
    500: '#c7a76c',
    600: '#9d7332',
    700: '#7d572b',
    800: '#684729',
    900: '#593d26',
    950: '#321f12',
  },
  ocean: {
    50: '#edf7f9',
    100: '#d5ebef',
    200: '#afd8df',
    300: '#7bbdca',
    400: '#519cae',
    500: '#3f7f92',
    600: '#386a7b',
    700: '#335766',
    800: '#304a55',
    900: '#2b3f49',
    950: '#182832',
  },
  warmgray: {
    50: '#f7f5f2',
    100: '#e8e2da',
    200: '#d1c8bd',
    300: '#b4a99a',
    400: '#978b7e',
    500: '#7a746b',
    600: '#625c55',
    700: '#4d4843',
    800: '#403c38',
    900: '#373330',
    950: '#1f1d1b',
  },
  taupe: {
    50: '#f6f3ef',
    100: '#e7ded5',
    200: '#d2c2b2',
    300: '#b8a089',
    400: '#9d8268',
    500: '#817568',
    600: '#6c5441',
    700: '#574233',
    800: '#4a392e',
    900: '#403229',
    950: '#241914',
  },
  mushroom: {
    50: '#f6f4f2',
    100: '#e8e2de',
    200: '#d4c8c0',
    300: '#b9a89c',
    400: '#9f8b7e',
    500: '#8a8178',
    600: '#6c5b50',
    700: '#574941',
    800: '#493f39',
    900: '#3f3732',
    950: '#241d1a',
  },
  sagegray: {
    50: '#f2f5f1',
    100: '#dfe7dd',
    200: '#c0d0bd',
    300: '#9caf99',
    400: '#81957d',
    500: '#758173',
    600: '#596356',
    700: '#464d43',
    800: '#3a4038',
    900: '#323730',
    950: '#1a1e18',
  },
  mist: {
    50: '#f1f5f6',
    100: '#dde7e9',
    200: '#bfD2d7',
    300: '#97b4bd',
    400: '#7798a2',
    500: '#7b8b8f',
    600: '#526a71',
    700: '#45575d',
    800: '#3c4a4f',
    900: '#354146',
    950: '#1d292d',
  },
  sandgray: {
    50: '#f6f3ee',
    100: '#e7dfd3',
    200: '#d1c3ad',
    300: '#b7a184',
    400: '#9b8464',
    500: '#8a806f',
    600: '#67583f',
    700: '#534634',
    800: '#473c30',
    900: '#3e352c',
    950: '#231c16',
  },
  mono: {
    50: '#f8fafc',
    100: '#f1f5f9',
    200: '#e2e8f0',
    300: '#cbd5e1',
    400: '#94a3b8',
    500: '#64748b',
    600: '#475569',
    700: '#334155',
    800: '#1e293b',
    900: '#0f172a',
    950: '#020617',
  },
  graphite: {
    50: '#f7f7f7',
    100: '#e7e7e7',
    200: '#d1d1d1',
    300: '#b0b0b0',
    400: '#888888',
    500: '#5f6368',
    600: '#4b4f54',
    700: '#3d4146',
    800: '#2f3338',
    900: '#25292e',
    950: '#14171a',
  },
  ink: {
    50: '#f6f7f8',
    100: '#e3e6ea',
    200: '#cbd1d8',
    300: '#a9b2bd',
    400: '#7f8a98',
    500: '#4b5563',
    600: '#3f4854',
    700: '#343b45',
    800: '#2b3139',
    900: '#242a31',
    950: '#11161d',
  },
}

const colorScale = (name: string) => customPalettes[name] ?? ({
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

const primaryPaletteSections = [
  {
    label: 'Simple',
    palettes: [
      { name: 'red', color: '#ef4444' },
      { name: 'orange', color: '#f97316' },
      { name: 'amber', color: '#f59e0b' },
      { name: 'yellow', color: '#eab308' },
      { name: 'lime', color: '#84cc16' },
      { name: 'green', color: '#22c55e' },
      { name: 'emerald', color: '#10b981' },
      { name: 'teal', color: '#14b8a6' },
      { name: 'cyan', color: '#06b6d4' },
      { name: 'sky', color: '#0ea5e9' },
      { name: 'blue', color: '#3b82f6' },
      { name: 'indigo', color: '#6366f1' },
      { name: 'violet', color: '#8b5cf6' },
      { name: 'purple', color: '#a855f7' },
      { name: 'pink', color: '#ec4899' },
      { name: 'rose', color: '#f43f5e' },
    ],
  },
  {
    label: 'Natural',
    palettes: [
      { name: 'brown', color: '#8b5e34' },
      { name: 'sage', color: '#6b8f71' },
      { name: 'moss', color: '#5f7a3a' },
      { name: 'clay', color: '#b46a55' },
      { name: 'terracotta', color: '#c65f3f' },
      { name: 'olive', color: '#737a3c' },
      { name: 'sand', color: '#c7a76c' },
      { name: 'ocean', color: '#3f7f92' },
    ],
  },
  {
    label: 'Monochrome',
    palettes: [
      { name: 'mono', color: '#64748b' },
      { name: 'graphite', color: '#5f6368' },
      { name: 'ink', color: '#4b5563' },
      { name: 'slate', color: '#64748b' },
      { name: 'gray', color: '#6b7280' },
      { name: 'zinc', color: '#71717a' },
      { name: 'neutral', color: '#737373' },
      { name: 'stone', color: '#78716c' },
    ],
  },
] satisfies { label: string; palettes: PaletteOption[] }[]

const surfacePaletteSections = [
  {
    label: 'Simple',
    palettes: [
      { name: 'slate', color: '#64748b' },
      { name: 'gray', color: '#6b7280' },
      { name: 'zinc', color: '#71717a' },
      { name: 'neutral', color: '#737373' },
      { name: 'stone', color: '#78716c' },
    ],
  },
  {
    label: 'Natural',
    palettes: [
      { name: 'warmgray', color: '#7a746b' },
      { name: 'taupe', color: '#817568' },
      { name: 'mushroom', color: '#8a8178' },
      { name: 'sagegray', color: '#758173' },
      { name: 'mist', color: '#7b8b8f' },
      { name: 'sandgray', color: '#8a806f' },
    ],
  },
  {
    label: 'Monochrome',
    palettes: [
      { name: 'mono', color: '#64748b' },
      { name: 'graphite', color: '#5f6368' },
      { name: 'ink', color: '#4b5563' },
    ],
  },
] satisfies { label: string; palettes: PaletteOption[] }[]

const modeOptions = [
  { label: 'Light', value: false },
  { label: 'Dark', value: true },
]

const surfaceStyleOptions = [
  { label: 'Solid', value: 'solid' },
  { label: 'Liquid Glass', value: 'liquid-glass' },
] satisfies { label: string; value: SurfaceStyle }[]

const settings = reactive({
  primary: 'indigo',
  surface: 'slate',
  preset: 'Aura' as PresetName,
  surfaceStyle: 'solid' as SurfaceStyle,
  dark: false,
})

function toggle(event: Event) {
  popover.value?.toggle(event)
}

function applySettings() {
  usePreset(presetMap[settings.preset])
  updatePrimaryPalette(colorScale(settings.primary))
  updateSurfacePalette(colorScale(settings.surface))

  primevue.config.ripple = true
  document.documentElement.classList.toggle('app-dark', settings.dark)
  document.documentElement.classList.toggle('app-liquid-glass', settings.surfaceStyle === 'liquid-glass')
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
  <Button aria-label="Theme settings" class="theme-trigger" outlined size="small" type="button" @click="toggle">
    <span class="material-icons theme-trigger-icon" aria-hidden="true">palette</span>
  </Button>

  <Popover ref="popover" class="theme-popover">
    <div class="theme-grid">
      <div>
        <div class="theme-label mb-2">Primary</div>
        <div class="palette-section-stack">
          <div v-for="section in primaryPaletteSections" :key="section.label" class="palette-section">
            <div class="palette-section-label">{{ section.label }}</div>
            <div class="swatch-row">
              <button
                v-for="palette in section.palettes"
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
        </div>
      </div>

      <div>
        <div class="theme-label mb-2">Surface</div>
        <div class="palette-section-stack">
          <div v-for="section in surfacePaletteSections" :key="section.label" class="palette-section">
            <div class="palette-section-label">{{ section.label }}</div>
            <div class="swatch-row">
              <button
                v-for="palette in section.palettes"
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
        </div>
      </div>

      <div>
        <div class="theme-label mb-2">Theme</div>
        <SelectButton v-model="settings.preset" :allow-empty="false" :options="presetOptions" size="small" />
      </div>

      <div>
        <div class="theme-label mb-2">Mode</div>
        <SelectButton
          v-model="settings.dark"
          :allow-empty="false"
          option-label="label"
          option-value="value"
          :options="modeOptions"
          size="small"
        />
      </div>

      <div>
        <div class="theme-label mb-2">Surface</div>
        <SelectButton
          v-model="settings.surfaceStyle"
          :allow-empty="false"
          option-label="label"
          option-value="value"
          :options="surfaceStyleOptions"
          size="small"
        />
      </div>
    </div>
  </Popover>
</template>
