<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  hungerLevelLabelForPartner,
  hungerLevelOptionsForPartner,
  isHungerLevelValue,
} from '@/data/hungerLevels'
import type { HungerLevelValue, Partner } from '@/types'

const props = defineProps<{
  partners: Partner[]
  updateHungerLevel: (partnerId: string, hungerLevel: HungerLevelValue) => Promise<void>
  title?: string
  description?: string
}>()

const { t } = useI18n()
const savingPartnerIds = ref<string[]>([])
const errorMessage = ref<string | null>(null)
const panelTitle = computed(() => props.title ?? t('hunger.title'))
const panelDescription = computed(() => props.description ?? t('hunger.description'))

function isSaving(partnerId: string) {
  return savingPartnerIds.value.includes(partnerId)
}

async function updatePartnerHungerLevel(partner: Partner, value: unknown) {
  if (!isHungerLevelValue(value) || value === partner.hungerLevel) {
    return
  }

  errorMessage.value = null
  savingPartnerIds.value = [...savingPartnerIds.value, partner.id]

  try {
    await props.updateHungerLevel(partner.id, value)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : t('hunger.saveFailed')
  } finally {
    savingPartnerIds.value = savingPartnerIds.value.filter((id) => id !== partner.id)
  }
}
</script>

<template>
  <UCard variant="subtle" :ui="{ body: 'p-4 sm:p-5' }">
    <div class="grid gap-4">
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 class="text-xl font-black">{{ panelTitle }}</h2>
          <p class="text-sm text-muted">{{ panelDescription }}</p>
        </div>
        <UBadge color="warning" variant="soft">{{ t('hunger.live') }}</UBadge>
      </div>

      <div class="grid gap-3 md:grid-cols-2">
        <div
          v-for="partner in partners"
          :key="partner.id"
          class="grid gap-3 rounded-md border border-default bg-muted/40 p-3"
        >
          <div class="flex items-center gap-3">
            <UAvatar
              :src="partner.avatarUrl"
              :text="partner.avatarUrl ? undefined : partner.avatarFallback"
              :alt="partner.name"
              size="lg"
              class="ring ring-default"
            />
            <div class="min-w-0">
              <div class="text-sm font-semibold text-muted">
                {{ partner.name }} - {{ t('hunger.level') }}
              </div>
              <div class="truncate text-base font-black text-highlighted">
                {{ hungerLevelLabelForPartner(partner) }}
              </div>
            </div>
          </div>

          <USelect
            class="w-full"
            label-key="label"
            value-key="value"
            :disabled="isSaving(partner.id)"
            :items="hungerLevelOptionsForPartner()"
            :loading="isSaving(partner.id)"
            :model-value="partner.hungerLevel"
            @update:model-value="updatePartnerHungerLevel(partner, $event)"
          />
        </div>
      </div>

      <UAlert v-if="errorMessage" color="warning" variant="soft" :description="errorMessage" />
    </div>
  </UCard>
</template>
