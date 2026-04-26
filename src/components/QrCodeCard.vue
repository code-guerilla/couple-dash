<script setup lang="ts">
import QRCode from 'qrcode'
import { computed, ref, watchEffect } from 'vue'

const props = defineProps<{
  label: string
  person: string
  url: string
}>()

const dataUrl = ref('')
const absoluteUrl = computed(() => new URL(props.url, window.location.origin).toString())

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
  <RouterLink
    class="qr-card group"
    :to="url"
  >
    <img class="qr-image" :src="dataUrl" :alt="label" />
    <span class="min-w-0">
      <span class="block text-xs font-semibold uppercase muted">
        {{ person }}
      </span>
      <span class="block text-sm font-bold leading-tight">{{ label }}</span>
      <span class="mt-1 block truncate-line text-xs muted">Scan to edit live</span>
    </span>
  </RouterLink>
</template>
