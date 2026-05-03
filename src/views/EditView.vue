<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { alertTemplates } from '@/data/defaults'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'
import type { AlertSeverity, DashboardWidget, WidgetScope, WidgetVisual } from '@/types'

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const coupleSlug = computed(() => String(route.params.coupleSlug))
const { initialized, isAuthenticated, isSupabaseConfigured, userId } = useSupabaseAuth()
const {
  couple,
  widgets,
  alerts,
  error,
  loadCouple,
  updateWidget,
  addWidget,
  setWidgetVisible,
  triggerAlert,
  setAlertActive,
} = useDashboardStore(coupleSlug.value)

const currentPartnerId = ref<string | null>(null)
const membershipError = ref<string | null>(null)
const partner = computed(() =>
  couple.value?.partners.find((item) => item.id === currentPartnerId.value),
)
const editableWidgets = computed(() =>
  widgets.value.filter(
    (widget) => widget.scope === 'shared' || widget.personId === currentPartnerId.value,
  ),
)

const newWidget = reactive({
  label: '',
  value: '',
  detail: '',
  scope: 'shared' as WidgetScope,
  visual: 'stat' as WidgetVisual,
  tone: 'info' as AlertSeverity,
})

const visualOptionValues: WidgetVisual[] = [
  'stat',
  'progress',
  'radial',
  'doughnut',
  'bar',
  'line',
  'memory',
]
const toneOptionValues: AlertSeverity[] = ['info', 'success', 'warning', 'error']
const alertTemplateKeys = [
  'snackShortage',
  'anniversary',
  'cuddle',
  'dishwasher',
  'nothing',
  'dinnerTimeout',
  'blanketDispute',
  'remoteFailover',
] as const
const visualOptions = computed(() =>
  visualOptionValues.map((value) => ({ label: t(`edit.visuals.${value}`), value })),
)
const toneOptions = computed(() =>
  toneOptionValues.map((value) => ({ label: t(`edit.tones.${value}`), value })),
)
const alertTemplateOptions = computed(() =>
  alertTemplates.map((value, index) => ({
    label: t(`edit.alertTemplates.${alertTemplateKeys[index]}`),
    value,
  })),
)

async function loadMembership() {
  currentPartnerId.value = null
  membershipError.value = null

  if (!isSupabaseConfigured || !supabase || !couple.value || !userId.value) {
    currentPartnerId.value = couple.value?.partners[0]?.id ?? null
    return
  }

  const { data, error: memberError } = await supabase
    .from('couple_member')
    .select('partner_id')
    .eq('couple_id', couple.value.id)
    .eq('user_id', userId.value)
    .maybeSingle()

  if (memberError) {
    membershipError.value = memberError.message
    return
  }

  currentPartnerId.value = data?.partner_id ? String(data.partner_id) : null
}

async function loadPrivateEditor() {
  if (!isSupabaseConfigured || isAuthenticated.value) {
    await loadCouple()
    await loadMembership()
  }
}

async function saveWidget(widget: DashboardWidget) {
  await updateWidget(widget.id, {
    label: widget.label,
    value: widget.value,
    detail: widget.detail,
    visual: widget.visual,
    tone: widget.tone,
    numericValue: widget.numericValue,
  })
}

async function createWidget() {
  if (!couple.value || !newWidget.label || !newWidget.value) {
    return
  }

  if (newWidget.scope === 'person' && !currentPartnerId.value) {
    membershipError.value = t('edit.noPartner')
    return
  }

  await addWidget({
    coupleId: couple.value.id,
    label: newWidget.label,
    value: newWidget.value,
    detail: newWidget.detail || t('edit.freshDetail'),
    scope: newWidget.scope,
    personId: newWidget.scope === 'person' ? (currentPartnerId.value ?? undefined) : undefined,
    visual: newWidget.visual,
    tone: newWidget.tone,
    numericValue: ['progress', 'radial', 'doughnut', 'line'].includes(newWidget.visual)
      ? 50
      : undefined,
    max: 100,
    visible: true,
  })

  newWidget.label = ''
  newWidget.value = ''
  newWidget.detail = ''
  newWidget.scope = 'shared'
  newWidget.visual = 'stat'
  newWidget.tone = 'info'
}

async function sendAlert(title: string) {
  if (!couple.value) {
    return
  }

  await triggerAlert({
    coupleId: couple.value.id,
    title,
    detail: t('edit.raisedFrom', { name: partner.value?.name ?? t('alerts.partnerFallback') }),
    severity: title.includes('incorrectly') || title.includes('nothing') ? 'warning' : 'info',
    source: 'partner',
    triggeredBy: partner.value?.name,
  })
}

watch(userId, () => void loadPrivateEditor())

onMounted(() => void loadPrivateEditor())
</script>

<template>
  <section v-if="isSupabaseConfigured && initialized && !isAuthenticated" class="mx-auto max-w-md">
    <AuthPanel />
  </section>

  <section v-else-if="couple" class="mx-auto max-w-3xl space-y-6 pb-10">
    <div class="flex items-center justify-between gap-4">
      <div>
        <p class="text-sm font-semibold text-muted">{{ couple.name }}</p>
        <h1 class="text-3xl font-black">
          {{ t('edit.console', { name: partner?.name ?? t('edit.partnerFallback') }) }}
        </h1>
      </div>
      <UButton
        :label="t('edit.display')"
        size="sm"
        variant="ghost"
        type="button"
        @click="router.push({ name: 'display', params: { coupleSlug: couple.slug } })"
      />
    </div>

    <UAlert
      v-if="error || membershipError"
      color="warning"
      variant="soft"
      :description="membershipError ?? error ?? ''"
    />

    <div class="grid gap-4 sm:grid-cols-2">
      <UCard variant="subtle">
        <div class="text-sm text-muted">{{ t('edit.editableMetrics') }}</div>
        <div class="mt-1 text-4xl font-black leading-none sm:text-5xl">
          {{ editableWidgets.length }}
        </div>
        <div class="mt-1 text-sm text-muted">{{ t('edit.editableMetricsDescription') }}</div>
      </UCard>
      <UCard variant="subtle">
        <div class="text-sm text-muted">{{ t('edit.activeAlerts') }}</div>
        <div class="mt-1 text-4xl font-black leading-none text-amber-500 sm:text-5xl">
          {{ alerts.length }}
        </div>
        <div class="mt-1 text-sm text-muted">{{ t('edit.activeAlertsDescription') }}</div>
      </UCard>
    </div>

    <UCard>
      <template #header
        ><h2 class="text-xl font-black">{{ t('edit.addWidget') }}</h2></template
      >

      <form class="grid gap-4" @submit.prevent="createWidget">
        <UFormField :label="t('edit.metricKey')" required>
          <UInput
            v-model="newWidget.label"
            class="w-full"
            :placeholder="t('edit.metricPlaceholder')"
          />
        </UFormField>
        <UFormField :label="t('edit.value')" required>
          <UInput
            v-model="newWidget.value"
            class="w-full"
            :placeholder="t('edit.valuePlaceholder')"
          />
        </UFormField>
        <UFormField :label="t('edit.explanation')">
          <UTextarea
            v-model="newWidget.detail"
            autoresize
            class="w-full"
            :placeholder="t('edit.explanationPlaceholder')"
          />
        </UFormField>

        <div class="grid gap-3 sm:grid-cols-3">
          <UFormField :label="t('edit.scope')">
            <USelect
              v-model="newWidget.scope"
              class="w-full"
              label-key="label"
              value-key="value"
              :items="[
                { label: t('edit.shared'), value: 'shared' },
                { label: t('edit.onlyMine'), value: 'person', disabled: !currentPartnerId },
              ]"
            />
          </UFormField>
          <UFormField :label="t('edit.visual')">
            <USelect
              v-model="newWidget.visual"
              class="w-full"
              label-key="label"
              value-key="value"
              :items="visualOptions"
            />
          </UFormField>
          <UFormField :label="t('edit.tone')">
            <USelect
              v-model="newWidget.tone"
              class="w-full"
              label-key="label"
              value-key="value"
              :items="toneOptions"
            />
          </UFormField>
        </div>

        <UButton :label="t('edit.addWidget')" type="submit" />
      </form>
    </UCard>

    <section class="space-y-3">
      <h2 class="text-xl font-black">{{ t('edit.triggerAlert') }}</h2>
      <div class="grid gap-2 sm:grid-cols-2">
        <UButton
          v-for="template in alertTemplateOptions"
          :key="template.value"
          class="justify-start text-left"
          :label="template.label"
          variant="outline"
          type="button"
          @click="sendAlert(template.value)"
        />
      </div>
    </section>

    <section class="space-y-3">
      <h2 class="text-xl font-black">{{ t('edit.editLiveMetrics') }}</h2>
      <UCard v-for="widget in editableWidgets" :key="widget.id">
        <form class="grid gap-4" @submit.prevent="saveWidget(widget)">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div class="flex items-center gap-2">
              <UBadge :color="widget.scope === 'shared' ? 'info' : 'neutral'" variant="soft">{{
                widget.scope
              }}</UBadge>
              <UBadge :color="widget.visible ? 'success' : 'neutral'" variant="soft">
                {{ widget.visible ? t('edit.visible') : t('edit.hidden') }}
              </UBadge>
            </div>
            <div class="flex gap-2">
              <UButton
                :label="widget.visible ? t('edit.hide') : t('edit.show')"
                variant="outline"
                size="sm"
                type="button"
                @click="setWidgetVisible(widget.id, !widget.visible)"
              />
              <UButton :label="t('edit.save')" size="sm" type="submit" />
            </div>
          </div>

          <UFormField :label="t('edit.metricKey')">
            <UInput v-model="widget.label" class="w-full font-semibold" />
          </UFormField>
          <UFormField :label="t('edit.value')">
            <UInput v-model="widget.value" class="w-full text-lg" />
          </UFormField>
          <UFormField :label="t('edit.explanation')">
            <UTextarea v-model="widget.detail" autoresize class="w-full" />
          </UFormField>

          <div class="grid gap-3 sm:grid-cols-3">
            <UFormField :label="t('edit.visual')">
              <USelect
                v-model="widget.visual"
                class="w-full"
                label-key="label"
                value-key="value"
                :items="visualOptions"
              />
            </UFormField>
            <UFormField :label="t('edit.tone')">
              <USelect
                v-model="widget.tone"
                class="w-full"
                label-key="label"
                value-key="value"
                :items="toneOptions"
              />
            </UFormField>
            <UFormField :label="t('edit.numericValue')">
              <UInputNumber
                class="w-full"
                :max="100"
                :min="0"
                :model-value="widget.numericValue ?? 0"
                @update:model-value="widget.numericValue = $event ?? 0"
              />
            </UFormField>
          </div>
        </form>
      </UCard>
    </section>

    <section class="space-y-3">
      <h2 class="text-xl font-black">{{ t('edit.alerts') }}</h2>
      <UAlert
        v-for="alert in alerts"
        :key="alert.id"
        color="info"
        variant="outline"
        :description="alert.title"
      >
        <template #actions>
          <UButton
            :label="t('edit.deactivate')"
            size="sm"
            variant="ghost"
            type="button"
            @click="setAlertActive(alert.id, false)"
          />
        </template>
      </UAlert>
    </section>
  </section>

  <section v-else class="mx-auto max-w-md">
    <UAlert color="warning" variant="soft" :description="t('edit.noDashboard')" />
  </section>
</template>
