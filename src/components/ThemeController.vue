<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'

const STORAGE_KEY = 'couple-dash-theme'

const dark = ref(false)

function applyTheme() {
  document.documentElement.classList.toggle('app-dark', dark.value)
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ dark: dark.value }))
}

onMounted(() => {
  const saved = localStorage.getItem(STORAGE_KEY)

  if (saved) {
    const parsed = JSON.parse(saved) as { dark?: boolean }
    dark.value = Boolean(parsed.dark)
  }

  applyTheme()
})

watch(dark, applyTheme)
</script>

<template>
  <UButton
    :aria-label="dark ? 'Use light mode' : 'Use dark mode'"
    :icon="dark ? 'i-lucide-moon' : 'i-lucide-sun'"
    size="sm"
    square
    variant="ghost"
    type="button"
    @click="dark = !dark"
  />
</template>
