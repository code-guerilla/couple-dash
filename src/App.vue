<script setup lang="ts">
import type { NavigationMenuItem } from '@nuxt/ui'
import { computed, onMounted, ref, watch, watchEffect } from 'vue'
import { useI18n } from 'vue-i18n'
import { RouterView, useRoute } from 'vue-router'
import { de, en } from '@nuxt/ui/locale'
import AppFooter from '@/components/AppFooter.vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'
import StorageConsentBanner from '@/components/StorageConsentBanner.vue'
import ThemeController from '@/components/ThemeController.vue'

const route = useRoute()
const { locale, t } = useI18n()
const { initialized, isAuthenticated, isSupabaseConfigured, userEmail, signOut } = useSupabaseAuth()
const isAdmin = ref(false)

const uiLocale = computed(() => (locale.value === 'de' ? de : en))

watchEffect(() => {
  document.title = 'CoupleDash'
})

const items = computed<NavigationMenuItem[]>(() => {
  const navItems: NavigationMenuItem[] = [
    {
      label: t('nav.home'),
      icon: 'i-lucide-house',
      to: '/',
      active: route.name === 'home',
    },
  ]

  if (isAdmin.value) {
    navItems.push({
      label: t('nav.admin'),
      icon: 'i-lucide-shield',
      to: '/admin',
      active: route.path.startsWith('/admin'),
    })
  }

  return navItems
})

async function checkAdmin() {
  if (!supabase || !initialized.value || !isAuthenticated.value) {
    isAdmin.value = false
    return
  }

  const { data, error } = await supabase.rpc('is_app_admin')
  isAdmin.value = error ? false : Boolean(data)
}

onMounted(() => void checkAdmin())
watch([initialized, isAuthenticated], () => void checkAdmin())
</script>

<template>
  <UApp :locale="uiLocale">
    <UHeader :title="'CoupleDash'" to="/" :toggle="{ color: 'neutral', variant: 'ghost' }">
      <template #title>
        <span>Couple<span class="text-primary">Dash</span></span>
      </template>

      <UNavigationMenu :items="items" />

      <template #right>
        <UBadge
          v-if="isSupabaseConfigured && initialized && isAuthenticated && userEmail"
          color="neutral"
          variant="soft"
          class="hidden sm:inline-flex"
        >
          {{ userEmail }}
        </UBadge>
        <UButton
          v-if="isSupabaseConfigured && initialized && isAuthenticated"
          icon="i-lucide-log-out"
          color="neutral"
          variant="ghost"
          aria-label="Sign out"
          title="Sign out"
          type="button"
          @click="signOut"
        />
        <ThemeController />
        <UColorModeButton />
      </template>

      <template #body>
        <div class="space-y-4">
          <UNavigationMenu :items="items" orientation="vertical" class="-mx-2.5" />
          <div
            v-if="isSupabaseConfigured && initialized && isAuthenticated"
            class="flex items-center justify-between gap-3 border-t border-default pt-4"
          >
            <UBadge v-if="userEmail" color="neutral" variant="soft">{{ userEmail }}</UBadge>
            <UButton
              icon="i-lucide-log-out"
              label="Sign out"
              color="neutral"
              variant="ghost"
              size="sm"
              type="button"
              @click="signOut"
            />
          </div>
        </div>
      </template>
    </UHeader>

    <UMain>
      <UContainer class="max-w-7xl py-8 sm:py-10">
        <RouterView />
      </UContainer>
    </UMain>
    <AppFooter />
    <StorageConsentBanner />
  </UApp>
</template>
