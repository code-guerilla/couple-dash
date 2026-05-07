<script setup lang="ts">
import QRCode from 'qrcode'
import { computed, ref, watchEffect } from 'vue'
import { useI18n } from 'vue-i18n'
import { RouterLink } from 'vue-router'

const props = defineProps<{
  label: string
  person: string
  url: string
}>()

const dataUrl = ref('')
const absoluteUrl = computed(() => new URL(props.url, window.location.origin).toString())
const { t } = useI18n()

watchEffect(async () => {
  dataUrl.value = await QRCode.toDataURL(absoluteUrl.value, {
    margin: 1,
    scale: 5,
    color: {
      dark: '#111827',
      light: '#ffffff',
    },
  })
})
</script>

<template>
  <UCard
    :as="RouterLink"
    class="border-primary/15 bg-primary/5 transition-transform hover:-translate-y-0.5 hover:border-primary/30"
    :to="url"
    :ui="{ body: 'flex items-center gap-3 p-3 sm:p-3' }"
  >
    <img
      class="h-20 w-20 shrink-0 rounded-md border border-default bg-white p-1"
      :src="dataUrl"
      :alt="label"
    />
    <span class="min-w-0">
      <span class="block text-xs font-semibold uppercase text-muted">
        {{ person }}
      </span>
      <span class="block text-sm font-bold leading-tight">{{ label }}</span>
      <span class="mt-1 block overflow-hidden text-ellipsis whitespace-nowrap text-xs text-muted">
        {{ t('qr.scanToEdit') }}
      </span>
    </span>
  </UCard>
</template>
