<script setup lang="ts">
import Message from 'primevue/message'
import Tag from 'primevue/tag'
import type { CoupleAlert } from '@/types'

defineProps<{
  alerts: CoupleAlert[]
}>()

const alertClasses: Record<CoupleAlert['severity'], string> = {
  info: 'info',
  success: 'success',
  warning: 'warn',
  error: 'error',
}
</script>

<template>
  <section class="space-y-3">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-black">Live Alerts</h2>
      <Tag severity="secondary" :value="`${alerts.length} active`" />
    </div>

    <Message v-if="alerts.length === 0" severity="success" :closable="false">No active household incidents.</Message>

    <Message
      v-for="alert in alerts"
      :key="alert.id"
      :severity="alertClasses[alert.severity]"
      :closable="false"
      variant="outlined"
    >
      <div class="min-w-0">
        <h3 class="font-bold">{{ alert.title }}</h3>
        <p class="text-sm">{{ alert.detail }}</p>
        <p class="mt-1 text-xs opacity-70">
          {{ alert.source === 'system' ? 'System generated' : `Triggered by ${alert.triggeredBy ?? 'partner'}` }}
        </p>
      </div>
    </Message>
  </section>
</template>
