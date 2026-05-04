<script setup lang="ts">
import type { NavigationMenuItem } from '@nuxt/ui'
import { computed, watchEffect } from 'vue'
import { useI18n } from 'vue-i18n'
import { RouterView, useRoute } from 'vue-router'
import { de, en } from '@nuxt/ui/locale'
import AppFooter from '@/components/AppFooter.vue'
import LocaleSwitcher from '@/components/LocaleSwitcher.vue'
import StorageConsentBanner from '@/components/StorageConsentBanner.vue'
import ThemeController from '@/components/ThemeController.vue'

const route = useRoute()
const { locale, t } = useI18n()

const uiLocale = computed(() => (locale.value === 'de' ? de : en))

watchEffect(() => {
  document.title = t('app.brand')
})

const items = computed<NavigationMenuItem[]>(() => [
  {
    label: t('nav.home'),
    icon: 'i-lucide-house',
    to: '/',
    active: route.name === 'home',
  },
  {
    label: t('nav.admin'),
    icon: 'i-lucide-shield',
    to: '/admin',
    active: route.path.startsWith('/admin'),
  },
])
</script>

<template>
  <UApp :locale="uiLocale">
    <UHeader :title="t('app.brand')" to="/" :toggle="{ color: 'neutral', variant: 'ghost' }">
      <template #title>
        <span class="text-primary">{{ t('app.brandPrefix') }}</span>
        <span>{{ t('app.brandSuffix') }}</span>
      </template>

      <UNavigationMenu :items="items" />

      <template #right>
        <LocaleSwitcher />
        <ThemeController />
        <UColorModeButton />
      </template>

      <template #body>
        <UNavigationMenu :items="items" orientation="vertical" class="-mx-2.5" />
      </template>
    </UHeader>

    <UMain>
      <UContainer class="py-8 sm:py-10">
        <RouterView />
      </UContainer>
    </UMain>
    <AppFooter />
    <StorageConsentBanner />
  </UApp>
</template>
