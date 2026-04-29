<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { alertTemplates } from '@/data/defaults'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'
import type { AlertSeverity, DashboardWidget, WidgetScope, WidgetVisual } from '@/types'

const route = useRoute()
const router = useRouter()
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

const visualOptions: WidgetVisual[] = [
  'stat',
  'progress',
  'radial',
  'doughnut',
  'bar',
  'line',
  'memory',
]
const toneOptions: AlertSeverity[] = ['info', 'success', 'warning', 'error']

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
    membershipError.value = 'Your account is not linked to a partner for this couple.'
    return
  }

  await addWidget({
    coupleId: couple.value.id,
    label: newWidget.label,
    value: newWidget.value,
    detail: newWidget.detail || 'Freshly added from the mobile console.',
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
    detail: `Raised from ${partner.value?.name ?? 'a partner'}'s phone console.`,
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
    <AuthPanel @signed-in="loadPrivateEditor" />
  </section>

  <section v-else-if="couple" class="mx-auto max-w-3xl space-y-6 pb-10">
    <div class="flex items-center justify-between gap-4">
      <div>
        <p class="text-sm font-semibold text-muted">{{ couple.name }}</p>
        <h1 class="text-3xl font-black">{{ partner?.name ?? 'Partner' }} console</h1>
      </div>
      <UButton
        label="Display"
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
        <div class="text-sm text-muted">Editable Metrics</div>
        <div class="mt-1 text-4xl font-black leading-none sm:text-5xl">
          {{ editableWidgets.length }}
        </div>
        <div class="mt-1 text-sm text-muted">Shared plus your own personal widgets</div>
      </UCard>
      <UCard variant="subtle">
        <div class="text-sm text-muted">Active Alerts</div>
        <div class="mt-1 text-4xl font-black leading-none text-amber-500 sm:text-5xl">
          {{ alerts.length }}
        </div>
        <div class="mt-1 text-sm text-muted">Visible on display</div>
      </UCard>
    </div>

    <UCard>
      <template #header><h2 class="text-xl font-black">Add Widget</h2></template>

      <form class="grid gap-4" @submit.prevent="createWidget">
        <UFormField label="Metric key" required>
          <UInput v-model="newWidget.label" class="w-full" placeholder="Blanket Ownership" />
        </UFormField>
        <UFormField label="Value" required>
          <UInput v-model="newWidget.value" class="w-full" placeholder="Disputed" />
        </UFormField>
        <UFormField label="Dashboard explanation">
          <UTextarea
            v-model="newWidget.detail"
            autoresize
            class="w-full"
            placeholder="Small dashboard explanation"
          />
        </UFormField>

        <div class="grid gap-3 sm:grid-cols-3">
          <UFormField label="Scope">
            <USelect
              v-model="newWidget.scope"
              class="w-full"
              label-key="label"
              value-key="value"
              :items="[
                { label: 'Shared', value: 'shared' },
                { label: 'Only mine', value: 'person', disabled: !currentPartnerId },
              ]"
            />
          </UFormField>
          <UFormField label="Visual">
            <USelect v-model="newWidget.visual" class="w-full" :items="visualOptions" />
          </UFormField>
          <UFormField label="Tone">
            <USelect v-model="newWidget.tone" class="w-full" :items="toneOptions" />
          </UFormField>
        </div>

        <UButton label="Add widget" type="submit" />
      </form>
    </UCard>

    <section class="space-y-3">
      <h2 class="text-xl font-black">Trigger Alert</h2>
      <div class="grid gap-2 sm:grid-cols-2">
        <UButton
          v-for="template in alertTemplates"
          :key="template"
          class="justify-start text-left"
          :label="template"
          variant="outline"
          type="button"
          @click="sendAlert(template)"
        />
      </div>
    </section>

    <section class="space-y-3">
      <h2 class="text-xl font-black">Edit Live Metrics</h2>
      <UCard v-for="widget in editableWidgets" :key="widget.id">
        <form class="grid gap-4" @submit.prevent="saveWidget(widget)">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div class="flex items-center gap-2">
              <UBadge :color="widget.scope === 'shared' ? 'info' : 'neutral'" variant="soft">{{
                widget.scope
              }}</UBadge>
              <UBadge :color="widget.visible ? 'success' : 'neutral'" variant="soft">
                {{ widget.visible ? 'visible' : 'hidden' }}
              </UBadge>
            </div>
            <div class="flex gap-2">
              <UButton
                :label="widget.visible ? 'Hide' : 'Show'"
                variant="outline"
                size="sm"
                type="button"
                @click="setWidgetVisible(widget.id, !widget.visible)"
              />
              <UButton label="Save" size="sm" type="submit" />
            </div>
          </div>

          <UFormField label="Metric key">
            <UInput v-model="widget.label" class="w-full font-semibold" />
          </UFormField>
          <UFormField label="Value">
            <UInput v-model="widget.value" class="w-full text-lg" />
          </UFormField>
          <UFormField label="Dashboard explanation">
            <UTextarea v-model="widget.detail" autoresize class="w-full" />
          </UFormField>

          <div class="grid gap-3 sm:grid-cols-3">
            <UFormField label="Visual">
              <USelect v-model="widget.visual" class="w-full" :items="visualOptions" />
            </UFormField>
            <UFormField label="Tone">
              <USelect v-model="widget.tone" class="w-full" :items="toneOptions" />
            </UFormField>
            <UFormField label="Numeric value">
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
      <h2 class="text-xl font-black">Alerts</h2>
      <UAlert
        v-for="alert in alerts"
        :key="alert.id"
        color="info"
        variant="outline"
        :description="alert.title"
      >
        <template #actions>
          <UButton
            label="Deactivate"
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
    <UAlert
      color="warning"
      variant="soft"
      description="No private couple dashboard is available for this account."
    />
  </section>
</template>
