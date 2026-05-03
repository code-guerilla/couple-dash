<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { de, en } from '@nuxt/ui/locale'
import { persistLocale, type LocaleCode } from '@/i18n'

const { locale, t } = useI18n()

const locales = [en, de]
const selectedLocale = computed({
  get: () => locale.value,
  set: (value: string) => {
    locale.value = value as LocaleCode
    persistLocale(value as LocaleCode)
  },
})
</script>

<template>
  <UTooltip :text="t('nav.language')">
    <ULocaleSelect
      v-model="selectedLocale"
      :aria-label="t('nav.language')"
      :locales="locales"
      :ui="{ content: 'z-50' }"
      class="w-36 sm:w-40"
      color="neutral"
      size="sm"
      variant="ghost"
    />
  </UTooltip>
</template>
