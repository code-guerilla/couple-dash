<script setup lang="ts">
import type { CoupleAlert } from '@/types'
import type { AlertProps } from '@nuxt/ui'
import { useI18n } from 'vue-i18n'

defineProps<{
  alerts: CoupleAlert[]
}>()

const alertClasses: Record<CoupleAlert['severity'], AlertProps['color']> = {
  info: 'info',
  success: 'success',
  warning: 'warning',
  error: 'error',
}

const { t } = useI18n()

function alertCreator(alert: CoupleAlert) {
  return alert.source === 'system' ? 'System' : (alert.triggeredBy ?? t('alerts.partnerFallback'))
}
</script>

<template>
  <section v-if="alerts.length" class="overflow-hidden border-y border-default bg-default/70">
    <div
      v-if="alerts.length <= 2"
      class="alert-strip-track flex w-max min-w-full gap-3 px-4 py-2 sm:px-6 lg:px-8"
    >
      <UAlert
        v-for="alert in alerts"
        :key="alert.id"
        :color="alertClasses[alert.severity]"
        variant="outline"
        class="w-fit min-w-56 max-w-[min(32rem,calc(100vw-3rem))] shrink-0"
      >
        <template #description>
          <div class="min-w-0">
            <!-- Directly using alert.title here -->
            <h3 class="line-clamp-1 font-bold">{{ alert.title }}</h3>
            <p class="mt-2 line-clamp-1 text-xs font-semibold opacity-70">
              {{ alertCreator(alert) }}
            </p>
          </div>
        </template>
      </UAlert>
    </div>

    <UMarquee
      v-else
      pause-on-hover
      :overlay="false"
      :ui="{ root: '[--gap:--spacing(3)] [--duration:64s]', content: 'w-auto py-2' }"
    >
      <UAlert
        v-for="alert in alerts"
        :key="alert.id"
        :color="alertClasses[alert.severity]"
        variant="outline"
        class="w-64 shrink-0"
      >
        <template #description>
          <div class="min-w-0">
            <!-- Directly using alert.title here -->
            <h3 class="line-clamp-1 font-bold">{{ alert.title }}</h3>
            <p class="mt-2 line-clamp-1 text-xs font-semibold opacity-70">
              {{ alertCreator(alert) }}
            </p>
          </div>
        </template>
      </UAlert>
    </UMarquee>
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
    transform: translateX(100%);
  }

  to {
    transform: translateX(-100%);
  }
}
</style>
