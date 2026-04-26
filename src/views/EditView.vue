<script setup lang="ts">
import Button from 'primevue/button'
import Card from 'primevue/card'
import InputNumber from 'primevue/inputnumber'
import InputText from 'primevue/inputtext'
import Message from 'primevue/message'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import Textarea from 'primevue/textarea'
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
const partner = computed(() => couple.value?.partners.find((item) => item.id === currentPartnerId.value))
const editableWidgets = computed(() =>
  widgets.value.filter((widget) => widget.scope === 'shared' || widget.personId === currentPartnerId.value),
)

const newWidget = reactive({
  label: '',
  value: '',
  detail: '',
  scope: 'shared' as WidgetScope,
  visual: 'stat' as WidgetVisual,
  tone: 'info' as AlertSeverity,
})

const visualOptions: WidgetVisual[] = ['stat', 'progress', 'radial', 'doughnut', 'bar', 'line', 'memory']
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
    personId: newWidget.scope === 'person' ? currentPartnerId.value ?? undefined : undefined,
    visual: newWidget.visual,
    tone: newWidget.tone,
    numericValue: ['progress', 'radial', 'doughnut', 'line'].includes(newWidget.visual) ? 50 : undefined,
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
        <p class="text-sm font-semibold muted">{{ couple.name }}</p>
        <h1 class="text-3xl font-black">{{ partner?.name ?? 'Partner' }} console</h1>
      </div>
      <Button
        label="Display"
        size="small"
        text
        type="button"
        @click="router.push({ name: 'display', params: { coupleSlug: couple.slug } })"
      />
    </div>

    <Message v-if="error || membershipError" severity="warn" :closable="false">
      {{ membershipError ?? error }}
    </Message>

    <div class="stat-grid">
      <div class="stat-cell">
        <div class="stat-label">Editable Metrics</div>
        <div class="stat-value">{{ editableWidgets.length }}</div>
        <div class="stat-note">Shared plus your own personal widgets</div>
      </div>
      <div class="stat-cell">
        <div class="stat-label">Active Alerts</div>
        <div class="stat-value text-amber-500">{{ alerts.length }}</div>
        <div class="stat-note">Visible on display</div>
      </div>
    </div>

    <Card>
      <template #title>Add Widget</template>
      <template #content>
        <form class="form-stack" @submit.prevent="createWidget">
          <InputText v-model="newWidget.label" fluid placeholder="Metric key, e.g. Blanket Ownership" />
          <InputText v-model="newWidget.value" fluid placeholder="Value, e.g. Disputed" />
          <Textarea v-model="newWidget.detail" auto-resize fluid placeholder="Small dashboard explanation" />

          <div class="grid gap-3 sm:grid-cols-3">
            <Select
              v-model="newWidget.scope"
              fluid
              option-disabled="disabled"
              option-label="label"
              option-value="value"
              :options="[
                { label: 'Shared', value: 'shared' },
                { label: 'Only mine', value: 'person', disabled: !currentPartnerId },
              ]"
            />
            <Select v-model="newWidget.visual" fluid :options="visualOptions" />
            <Select v-model="newWidget.tone" fluid :options="toneOptions" />
          </div>

          <Button label="Add widget" type="submit" />
        </form>
      </template>
    </Card>

    <section class="space-y-3">
      <h2 class="text-xl font-black">Trigger Alert</h2>
      <div class="grid gap-2 sm:grid-cols-2">
        <Button
          v-for="template in alertTemplates"
          :key="template"
          class="justify-start text-left"
          :label="template"
          outlined
          type="button"
          @click="sendAlert(template)"
        />
      </div>
    </section>

    <section class="space-y-3">
      <h2 class="text-xl font-black">Edit Live Metrics</h2>
      <Card
        v-for="widget in editableWidgets"
        :key="widget.id"
      >
        <template #content>
        <form class="form-stack" @submit.prevent="saveWidget(widget)">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div class="flex items-center gap-2">
              <Tag :severity="widget.scope === 'shared' ? 'info' : 'secondary'" :value="widget.scope" />
              <Tag :severity="widget.visible ? 'success' : 'secondary'" :value="widget.visible ? 'visible' : 'hidden'" />
            </div>
            <div class="flex gap-2">
              <Button
                :label="widget.visible ? 'Hide' : 'Show'"
                outlined
                size="small"
                type="button"
                @click="setWidgetVisible(widget.id, !widget.visible)"
              />
              <Button label="Save" size="small" type="submit" />
            </div>
          </div>

          <InputText v-model="widget.label" fluid class="font-semibold" />
          <InputText v-model="widget.value" fluid class="text-lg" />
          <Textarea v-model="widget.detail" auto-resize fluid />

          <div class="grid gap-3 sm:grid-cols-3">
            <Select v-model="widget.visual" fluid :options="visualOptions" />
            <Select v-model="widget.tone" fluid :options="toneOptions" />
            <InputNumber
              fluid
              :max="100"
              :min="0"
              :model-value="widget.numericValue ?? 0"
              @update:model-value="widget.numericValue = $event ?? 0"
            />
          </div>
        </form>
        </template>
      </Card>
    </section>

    <section class="space-y-3">
      <h2 class="text-xl font-black">Alerts</h2>
      <Message v-for="alert in alerts" :key="alert.id" severity="info" :closable="false" variant="outlined">
        <span>{{ alert.title }}</span>
        <Button class="ml-auto" label="Deactivate" size="small" text type="button" @click="setAlertActive(alert.id, false)" />
      </Message>
    </section>
  </section>

  <section v-else class="mx-auto max-w-md">
    <Message severity="warn" :closable="false">No private couple dashboard is available for this account.</Message>
  </section>
</template>

