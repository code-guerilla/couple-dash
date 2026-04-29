<script setup lang="ts">
import type { NavigationMenuItem } from '@nuxt/ui'
import { computed } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import ThemeController from '@/components/ThemeController.vue'

const route = useRoute()

const items = computed<NavigationMenuItem[]>(() => [
  {
    label: 'Home',
    icon: 'i-lucide-house',
    to: '/',
    active: route.name === 'home',
  },
  {
    label: 'Admin',
    icon: 'i-lucide-shield',
    to: '/admin',
    active: route.path.startsWith('/admin'),
  },
])
</script>

<template>
  <UApp>
    <UHeader title="CoupleDash" to="/" :toggle="{ color: 'neutral', variant: 'ghost' }">
      <template #title>
        <span class="text-primary">Couple</span>
        <span>Dash</span>
      </template>

      <UNavigationMenu :items="items" />

      <template #right>
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
  </UApp>
</template>
