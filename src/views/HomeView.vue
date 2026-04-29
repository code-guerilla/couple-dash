<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { isSupabaseConfigured } from '@/services/supabase'

const { couples } = useDashboardStore()
</script>

<template>
  <section class="mx-auto max-w-5xl space-y-8">
    <div class="space-y-4">
      <UBadge color="info" variant="soft">Multi tenant couple dashboards</UBadge>
      <h1 class="max-w-3xl text-4xl font-black leading-tight sm:text-6xl">
        A tiny always-on command center for wedding-grade household operations.
      </h1>
      <p class="max-w-2xl text-lg text-muted">
        Private couple dashboards are loaded only after a partner, display, or app admin session is
        authenticated.
      </p>
    </div>

    <div v-if="isSupabaseConfigured" class="grid gap-4 md:grid-cols-3">
      <UCard :as="RouterLink" to="/admin" class="transition-transform hover:-translate-y-0.5">
        <template #header><h2 class="font-black">Admin</h2></template>
        <p class="text-muted">Sign in and verify app_admin access.</p>
      </UCard>
      <UCard>
        <template #header><h2 class="font-black">Display</h2></template>
        <p class="text-muted">
          Open a private /display/:slug URL and claim it with the display token.
        </p>
      </UCard>
      <UCard>
        <template #header><h2 class="font-black">Partner</h2></template>
        <p class="text-muted">
          Partners use /invite links once, then /edit/:slug with Supabase Auth.
        </p>
      </UCard>
    </div>

    <div v-else class="grid gap-4 md:grid-cols-2">
      <UCard
        v-for="couple in couples"
        :key="couple.id"
        :as="RouterLink"
        class="transition-transform hover:-translate-y-0.5"
        :to="{ name: 'display', params: { coupleSlug: couple.slug } }"
      >
        <template #header>
          <div class="flex items-start justify-between gap-4">
            <div>
              <h2 class="text-3xl font-black">{{ couple.name }}</h2>
              <p class="mt-1 text-base font-normal text-muted">{{ couple.subtitle }}</p>
            </div>
            <UBadge color="success" variant="soft">Production</UBadge>
          </div>
        </template>

        <div class="mt-2 grid grid-cols-2 gap-3 text-sm">
          <div class="rounded-md bg-muted p-3 ring ring-default">
            <p class="text-muted">Wedding</p>
            <p class="font-bold">{{ new Date(couple.weddingDate).toLocaleDateString() }}</p>
          </div>
          <div class="rounded-md bg-muted p-3 ring ring-default">
            <p class="text-muted">Partners</p>
            <p class="font-bold">
              {{ couple.partners.map((partner) => partner.name).join(' + ') }}
            </p>
          </div>
        </div>
      </UCard>
    </div>
  </section>
</template>
