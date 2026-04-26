<script setup lang="ts">
import Card from 'primevue/card'
import Tag from 'primevue/tag'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { isSupabaseConfigured } from '@/services/supabase'

const { couples } = useDashboardStore()
</script>

<template>
  <section class="mx-auto max-w-5xl space-y-8">
    <div class="space-y-4">
      <Tag severity="info" value="Multi tenant couple dashboards" />
      <h1 class="max-w-3xl text-4xl font-black leading-tight sm:text-6xl">
        A tiny always-on command center for wedding-grade household operations.
      </h1>
      <p class="max-w-2xl text-lg muted">
        Private couple dashboards are loaded only after a partner, display, or app admin session is authenticated.
      </p>
    </div>

    <div v-if="isSupabaseConfigured" class="grid gap-4 md:grid-cols-3">
      <RouterLink class="link-card" to="/admin">
        <Card>
          <template #title>Admin</template>
          <template #content><p class="muted">Sign in and verify app_admin access.</p></template>
        </Card>
      </RouterLink>
      <Card>
        <template #title>Display</template>
        <template #content><p class="muted">Open a private /display/:slug URL and claim it with the display token.</p></template>
      </Card>
      <Card>
        <template #title>Partner</template>
        <template #content><p class="muted">Partners use /invite links once, then /edit/:slug with Supabase Auth.</p></template>
      </Card>
    </div>

    <div v-else class="grid gap-4 md:grid-cols-2">
      <RouterLink
        v-for="couple in couples"
        :key="couple.id"
        class="link-card"
        :to="{ name: 'display', params: { coupleSlug: couple.slug } }"
      >
        <Card>
          <template #title>
            <div class="flex items-start justify-between gap-4">
              <div>
                <h2 class="text-3xl font-black">{{ couple.name }}</h2>
                <p class="mt-1 text-base font-normal muted">{{ couple.subtitle }}</p>
              </div>
              <Tag severity="success" value="Production" />
            </div>
          </template>
          <template #content>
            <div class="mt-2 grid grid-cols-2 gap-3 text-sm">
              <div class="soft-panel p-3">
                <p class="muted">Wedding</p>
                <p class="font-bold">{{ new Date(couple.weddingDate).toLocaleDateString() }}</p>
              </div>
              <div class="soft-panel p-3">
                <p class="muted">Partners</p>
                <p class="font-bold">{{ couple.partners.map((partner) => partner.name).join(' + ') }}</p>
              </div>
            </div>
          </template>
        </Card>
      </RouterLink>
    </div>
  </section>
</template>

