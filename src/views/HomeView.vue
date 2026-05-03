<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { RouterLink } from 'vue-router'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { isSupabaseConfigured } from '@/services/supabase'

const { couples } = useDashboardStore()
const { locale, t } = useI18n()
</script>

<template>
  <section class="mx-auto max-w-5xl space-y-8">
    <div class="space-y-4">
      <UBadge color="info" variant="soft">{{ t('home.badge') }}</UBadge>
      <h1 class="max-w-3xl text-4xl font-black leading-tight sm:text-6xl">
        {{ t('home.title') }}
      </h1>
      <p class="max-w-2xl text-lg text-muted">
        {{ t('home.description') }}
      </p>
    </div>

    <div v-if="isSupabaseConfigured" class="grid gap-4 md:grid-cols-3">
      <UCard :as="RouterLink" to="/admin" class="transition-transform hover:-translate-y-0.5">
        <template #header
          ><h2 class="font-black">{{ t('home.adminTitle') }}</h2></template
        >
        <p class="text-muted">{{ t('home.adminDescription') }}</p>
      </UCard>
      <UCard>
        <template #header
          ><h2 class="font-black">{{ t('home.displayTitle') }}</h2></template
        >
        <p class="text-muted">
          {{ t('home.displayDescription') }}
        </p>
      </UCard>
      <UCard>
        <template #header
          ><h2 class="font-black">{{ t('home.partnerTitle') }}</h2></template
        >
        <p class="text-muted">
          {{ t('home.partnerDescription') }}
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
            <UBadge color="success" variant="soft">{{ t('home.production') }}</UBadge>
          </div>
        </template>

        <div class="mt-2 grid grid-cols-2 gap-3 text-sm">
          <div class="rounded-md bg-muted p-3 ring ring-default">
            <p class="text-muted">{{ t('home.wedding') }}</p>
            <p class="font-bold">
              {{ new Date(couple.weddingDate).toLocaleDateString(locale) }}
            </p>
          </div>
          <div class="rounded-md bg-muted p-3 ring ring-default">
            <p class="text-muted">{{ t('home.partners') }}</p>
            <p class="font-bold">
              {{ couple.partners.map((partner) => partner.name).join(' + ') }}
            </p>
          </div>
        </div>
      </UCard>
    </div>
  </section>
</template>
