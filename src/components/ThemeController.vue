<script setup lang="ts">
import colors from 'tailwindcss/colors'
import { ref } from 'vue'
import { useThemeSettings } from '@/composables/useThemeSettings'

const open = ref(false)

const { neutralColors, neutral, primaryColors, primary, radiuses, radius, fonts, font } =
  useThemeSettings()

function chipColor(chip: string) {
  const palette = colors[chip as keyof typeof colors]

  return typeof palette === 'object' && palette && '500' in palette
    ? (palette as Record<string, string>)['500']
    : chip
}
</script>

<template>
  <UPopover
    v-model:open="open"
    :ui="{ content: 'w-72 px-6 py-4 flex flex-col gap-4 overflow-y-auto max-h-[calc(100vh-5rem)]' }"
  >
    <UTooltip text="Theme settings">
      <UButton
        icon="i-lucide-swatch-book"
        color="neutral"
        :variant="open ? 'soft' : 'ghost'"
        square
        aria-label="Theme settings"
        :ui="{ leadingIcon: 'text-primary' }"
      />
    </UTooltip>

    <template #content>
      <fieldset>
        <legend class="mb-2 text-xs font-semibold text-muted">Primary</legend>

        <div class="-mx-2 grid grid-cols-3 gap-1">
          <UButton
            v-for="color in primaryColors"
            :key="color"
            color="neutral"
            size="sm"
            :variant="primary === color ? 'soft' : 'outline'"
            class="min-w-0 justify-start gap-1 px-2 text-xs capitalize"
            :ui="{ label: 'truncate text-xs leading-none' }"
            @click="primary = color"
          >
            <span class="flex min-w-0 items-center gap-1">
              <span
                class="inline-block size-2 shrink-0 rounded-full ring-1 ring-default"
                :style="{ backgroundColor: chipColor(color) }"
              />
              <span class="min-w-0 truncate text-xs leading-none">{{ color }}</span>
            </span>
          </UButton>
        </div>
      </fieldset>

      <fieldset>
        <legend class="mb-2 text-xs font-semibold text-muted">Neutral</legend>

        <div class="-mx-2 grid grid-cols-3 gap-1">
          <UButton
            v-for="color in neutralColors"
            :key="color"
            color="neutral"
            size="sm"
            :variant="neutral === color ? 'soft' : 'outline'"
            class="min-w-0 justify-start gap-1 px-2 text-xs capitalize"
            :ui="{ label: 'truncate text-xs leading-none' }"
            @click="neutral = color"
          >
            <span class="flex min-w-0 items-center gap-1">
              <span
                class="inline-block size-2 shrink-0 rounded-full ring-1 ring-default"
                :style="{ backgroundColor: chipColor(color) }"
              />
              <span class="min-w-0 truncate text-xs leading-none">{{ color }}</span>
            </span>
          </UButton>
        </div>
      </fieldset>

      <fieldset>
        <legend class="mb-2 text-xs font-semibold text-muted">Radius</legend>

        <div class="-mx-2 grid grid-cols-5 gap-1">
          <UButton
            v-for="r in radiuses"
            :key="r"
            :label="String(r)"
            color="neutral"
            size="sm"
            :variant="radius === r ? 'soft' : 'outline'"
            class="justify-center px-0 text-xs"
            :ui="{ label: 'truncate text-xs leading-none' }"
            @click="radius = r"
          />
        </div>
      </fieldset>

      <fieldset>
        <legend class="mb-2 text-xs font-semibold text-muted">Font</legend>

        <USelect
          v-model="font"
          size="sm"
          color="neutral"
          icon="i-lucide-type"
          :items="fonts"
          class="-mx-2 w-[calc(100%+1rem)]"
          :ui="{
            trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200',
          }"
        />
      </fieldset>
    </template>
  </UPopover>
</template>
