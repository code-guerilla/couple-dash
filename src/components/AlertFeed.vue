<script setup lang="ts">
import type { CoupleAlert } from '@/types'
import type { AlertProps } from '@nuxt/ui'
import { useI18n } from 'vue-i18n'

defineProps<{
  alerts: CoupleAlert[]
}>()

const alertClasses: Record<CoupleAlert['severity'], AlertProps['color']> = {
  info: 'primary',
  success: 'primary',
  warning: 'warning',
  error: 'error',
}

const { t } = useI18n()

function alertCreator(alert: CoupleAlert) {
  return alert.source === 'system' ? 'System' : (alert.triggeredBy ?? t('alerts.partnerFallback'))
}
</script>

<template>
  <section v-if="alerts.length" class="overflow-hidden border-y border-primary/15 bg-primary/5">
    <div
      class="alert-strip-track flex w-max min-w-full px-4 py-2 sm:px-6 lg:px-8"
      aria-label="Live alert feed"
    >
      <div
        v-for="loopIndex in 2"
        :key="loopIndex"
        class="flex min-w-max shrink-0 items-stretch gap-3 pr-3"
        :aria-hidden="loopIndex === 2"
      >
        <UAlert
          v-for="alert in alerts"
          :key="`${loopIndex}-${alert.id}`"
          :color="alertClasses[alert.severity]"
          variant="outline"
          class="w-fit min-w-64 max-w-[min(34rem,calc(100vw-3rem))] shrink-0"
        >
          <template #description>
            <div class="min-w-0">
              <h3 class="line-clamp-1 font-bold">{{ alert.title }}</h3>
              <p class="mt-2 line-clamp-1 text-xs font-semibold opacity-70">
                {{ alertCreator(alert) }}
              </p>
            </div>
          </template>
        </UAlert>
      </div>
    </div>
  </section>
</template>

<style scoped>
.alert-strip-track {
  animation: alert-strip-marquee 40s linear infinite;
}

.alert-strip-track:hover {
  animation-play-state: paused;
}

@keyframes alert-strip-marquee {
  from {
    transform: translateX(-50%);
  }

  to {
    transform: translateX(0);
  }
}
</style>
