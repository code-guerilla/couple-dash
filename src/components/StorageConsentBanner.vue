<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { usePrivacyConsent } from '@/composables/usePrivacyConsent'

const { t } = useI18n()
const { storageConsent, setStorageConsent } = usePrivacyConsent()
</script>

<template>
  <div
    v-if="!storageConsent"
    class="fixed inset-x-4 bottom-4 z-50 mx-auto max-w-3xl rounded-md border border-default bg-default p-4 shadow-xl"
  >
    <div class="grid gap-3 sm:grid-cols-[1fr_auto] sm:items-center">
      <div>
        <h2 class="font-bold text-highlighted">{{ t('consent.title') }}</h2>
        <p class="mt-1 text-sm text-muted">{{ t('consent.description') }}</p>
      </div>
      <div class="flex flex-wrap gap-2 sm:justify-end">
        <UButton
          color="neutral"
          variant="outline"
          type="button"
          @click="setStorageConsent('rejected')"
        >
          {{ t('consent.reject') }}
        </UButton>
        <UButton type="button" @click="setStorageConsent('accepted')">
          {{ t('consent.accept') }}
        </UButton>
      </div>
    </div>
  </div>
</template>
