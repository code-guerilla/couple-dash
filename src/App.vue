<script setup lang="ts">
import Button from 'primevue/button'
import { RouterLink, RouterView } from 'vue-router'
import ThemeController from '@/components/ThemeController.vue'
</script>

<template>
  <div class="app-shell">
    <div class="app-topbar px-4 py-3 sm:px-6">
      <div class="mx-auto flex max-w-7xl items-center justify-between gap-3">
        <RouterLink class="brand-link" to="/">Couple Dash</RouterLink>

        <div class="flex items-center gap-2">
          <ThemeController />
          <RouterLink v-slot="{ navigate }" custom to="/">
            <Button label="Tenants" size="small" @click="navigate" />
          </RouterLink>
        </div>
      </div>
    </div>

    <main class="page-shell">
      <RouterView />
    </main>
  </div>
</template>
