<script setup lang="ts">
import colors from 'tailwindcss/colors'
import { ref } from 'vue'
import { useThemeSettings } from '@/composables/useThemeSettings'

const open = ref(false)

const {
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
} = useThemeSettings()

function chipColor(chip: string) {
  const color = chip === 'neutral' ? 'zinc' : chip
  const palette = colors[color as keyof typeof colors]

  return typeof palette === 'object' && palette && '500' in palette
    ? (palette as Record<string, string>)['500']
    : color
}
</script>

<template>
  <UPopover
    v-model:open="open"
    :ui="{ content: 'w-72 px-6 py-4 flex flex-col gap-4 overflow-y-auto max-h-[calc(100vh-5rem)]' }"
  >
    <UButton
      icon="i-lucide-swatch-book"
      color="neutral"
      :variant="open ? 'soft' : 'ghost'"
      square
      aria-label="Color picker"
      :ui="{ leadingIcon: 'text-primary' }"
    />

    <template #content>
      <fieldset>
        <legend class="theme-picker-legend">Primary</legend>

        <div class="theme-picker-grid theme-picker-grid-primary">
          <UButton
            v-for="color in primaryColors"
            :key="color"
            color="neutral"
            size="sm"
            :variant="primary === color ? 'soft' : 'outline'"
            class="theme-picker-button"
            :ui="{ label: 'truncate text-[11px] leading-none' }"
            @click="primary = color"
          >
            <span class="theme-picker-button-content">
              <span class="theme-picker-chip" :style="{ backgroundColor: chipColor(color) }" />
              <span class="theme-picker-label">{{ color }}</span>
            </span>
          </UButton>
        </div>
      </fieldset>

      <fieldset>
        <legend class="theme-picker-legend">Neutral</legend>

        <div class="theme-picker-grid theme-picker-grid-primary">
          <UButton
            v-for="color in neutralColors"
            :key="color"
            color="neutral"
            size="sm"
            :variant="neutral === color ? 'soft' : 'outline'"
            class="theme-picker-button"
            :ui="{ label: 'truncate text-[11px] leading-none' }"
            @click="neutral = color"
          >
            <span class="theme-picker-button-content">
              <span class="theme-picker-chip" :style="{ backgroundColor: chipColor(color) }" />
              <span class="theme-picker-label">{{ color }}</span>
            </span>
          </UButton>
        </div>
      </fieldset>

      <fieldset>
        <legend class="theme-picker-legend">Radius</legend>

        <div class="theme-picker-grid theme-picker-grid-radius">
          <UButton
            v-for="r in radiuses"
            :key="r"
            :label="String(r)"
            color="neutral"
            size="sm"
            :variant="radius === r ? 'soft' : 'outline'"
            class="theme-picker-button justify-center px-0"
            :ui="{ label: 'truncate text-[11px] leading-none' }"
            @click="radius = r"
          />
        </div>
      </fieldset>

      <fieldset>
        <legend class="theme-picker-legend">Font</legend>

        <div class="-mx-2">
          <USelect
            v-model="font"
            size="sm"
            color="neutral"
            icon="i-lucide-type"
            :items="fonts"
            class="w-full rounded-sm text-[11px] ring-default hover:bg-elevated/50 data-[state=open]:bg-elevated/50"
            :ui="{
              trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200',
            }"
          />
        </div>
      </fieldset>

      <fieldset>
        <legend class="theme-picker-legend">Color Mode</legend>

        <div class="theme-picker-grid theme-picker-grid-primary">
          <UButton
            v-for="m in modes"
            :key="m.value"
            :label="m.label"
            :icon="m.icon"
            color="neutral"
            size="sm"
            :variant="mode === m.value ? 'soft' : 'outline'"
            class="theme-picker-button"
            :ui="{ leadingIcon: 'size-3.5 shrink-0', label: 'truncate text-[11px] leading-none' }"
            @click="mode = m.value"
          />
        </div>
      </fieldset>
    </template>
  </UPopover>
</template>
