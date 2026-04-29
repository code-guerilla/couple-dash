<script setup lang="ts">
import type { CoupleAlert } from '@/types'
import type { AlertProps } from '@nuxt/ui'

defineProps<{
  alerts: CoupleAlert[]
}>()

const alertClasses: Record<CoupleAlert['severity'], AlertProps['color']> = {
  info: 'info',
  success: 'success',
  warning: 'warning',
  error: 'error',
}
</script>

<template>
  <section class="space-y-3">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-black">Live Alerts</h2>
      <UBadge color="neutral" variant="soft">{{ alerts.length }} active</UBadge>
    </div>

    <UAlert
      v-if="alerts.length === 0"
      color="success"
      variant="soft"
      description="No active household incidents."
    />

    <UAlert
      v-for="alert in alerts"
      :key="alert.id"
      :color="alertClasses[alert.severity]"
      variant="outline"
    >
      <template #description>
        <div class="min-w-0">
          <h3 class="font-bold">{{ alert.title }}</h3>
          <p class="text-sm">{{ alert.detail }}</p>
          <p class="mt-1 text-xs opacity-70">
            {{
              alert.source === 'system'
                ? 'System generated'
                : `Triggered by ${alert.triggeredBy ?? 'partner'}`
            }}
          </p>
        </div>
      </template>
    </UAlert>
  </section>
</template>
