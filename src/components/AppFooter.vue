<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<template>
  <footer class="border-t border-default bg-muted/40">
    <UContainer
      class="flex flex-col gap-3 py-5 text-sm text-muted sm:flex-row sm:items-center sm:justify-between"
    >
      <p>{{ t('footer.copyright') }}</p>
      <nav class="flex flex-wrap gap-x-4 gap-y-2">
        <ULink to="/impressum" class="font-medium text-default hover:text-primary">
          {{ t('footer.impressum') }}
        </ULink>
        <ULink to="/datenschutz" class="font-medium text-default hover:text-primary">
          {{ t('footer.privacy') }}
        </ULink>
      </nav>
    </UContainer>
  </footer>
</template>
