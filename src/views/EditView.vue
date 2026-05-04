<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import { alertTemplates } from '@/data/defaults'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase, type CoupleInviteStatus, type PendingPartnerInvite } from '@/services/supabase'
import type { AlertSeverity, DashboardWidget, TimelineEntry, WidgetVisual } from '@/types'

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
  setWidgetVisible,
  triggerAlert,
  setAlertActive,
} = useDashboardStore(coupleSlug.value)

const currentPartnerId = ref<string | null>(null)
const membershipError = ref<string | null>(null)
const inviteStatus = ref<CoupleInviteStatus | null>(null)
const pendingInvite = ref<PendingPartnerInvite | null>(null)
const inviteError = ref<string | null>(null)
const generatingInvite = ref(false)
const partner = computed(() =>
  couple.value?.partners.find((item) => item.id === currentPartnerId.value),
)
const pendingPartnerName = computed(() => inviteStatus.value?.pending_partner_name ?? null)
const pendingInviteUrl = computed(() => {
  if (!pendingInvite.value || typeof window === 'undefined') {
    return ''
  }

  const origin = window.location.origin.replace(/\/$/, '')
  return `${origin}/invite/${pendingInvite.value.couple_slug}/${pendingInvite.value.partner_slug}?token=${pendingInvite.value.invite_token}`
})
const editableWidgets = computed(() =>
  widgets.value.filter(
    (widget) => widget.scope === 'shared' || widget.personId === currentPartnerId.value,
  ),
)
const editableMetricWidgets = computed(() =>
  editableWidgets.value.filter((widget) => widget.visual !== 'timeline'),
)
const editableTimelineWidgets = computed(() =>
  editableWidgets.value.filter((widget) => widget.visual === 'timeline'),
)
const today = new Date().toISOString().slice(0, 10)

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

async function loadInviteStatus() {
  inviteStatus.value = null
  inviteError.value = null

  if (!isSupabaseConfigured || !supabase || !couple.value || !currentPartnerId.value) {
    return
  }

  const { data, error: statusError } = await supabase
    .rpc('get_couple_invite_status', {
      p_couple_id: couple.value.id,
    })
    .single()

  if (statusError) {
    inviteError.value = statusError.message
    return
  }

  inviteStatus.value = data as CoupleInviteStatus
}

async function loadPrivateEditor() {
  if (!isSupabaseConfigured || isAuthenticated.value) {
    await loadCouple()
    await loadMembership()
    await loadInviteStatus()
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

function addTimelineEntry(widget: DashboardWidget) {
  widget.timelineEntries = [
    ...(widget.timelineEntries ?? []),
    {
      id: crypto.randomUUID(),
      date: today,
      title: t('edit.newMilestone'),
      description: '',
      icon: 'i-lucide-heart',
    },
  ]
}

function removeTimelineEntry(widget: DashboardWidget, entryId: string) {
  widget.timelineEntries = (widget.timelineEntries ?? []).filter((entry) => entry.id !== entryId)
}

async function saveTimelineWidget(widget: DashboardWidget) {
  await updateWidget(widget.id, {
    label: widget.label,
    value: widget.value,
    detail: widget.detail,
    tone: widget.tone,
    timelineEntries: (widget.timelineEntries ?? []).map((entry: TimelineEntry) => ({
      ...entry,
      icon: entry.icon || 'i-lucide-heart',
    })),
  })
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

async function createPartnerInvite() {
  if (!supabase || !couple.value) {
    return
  }

  generatingInvite.value = true
  inviteError.value = null
  pendingInvite.value = null

  const { data, error: createError } = await supabase
    .rpc('create_pending_partner_invite', {
      p_couple_id: couple.value.id,
    })
    .single()

  generatingInvite.value = false

  if (createError) {
    inviteError.value = createError.message
    return
  }

  pendingInvite.value = data as PendingPartnerInvite
  await loadInviteStatus()
}

async function copyPendingInvite() {
  if (!pendingInviteUrl.value) {
    return
  }

  await navigator.clipboard.writeText(pendingInviteUrl.value)
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

    <UCard v-if="pendingPartnerName || pendingInviteUrl" variant="subtle">
      <div class="grid gap-4 md:grid-cols-[1fr_auto] md:items-center">
        <div>
          <h2 class="text-xl font-black">{{ t('edit.pendingInviteTitle') }}</h2>
          <p class="text-sm text-muted">
            {{ t('edit.pendingInviteDescription', { name: pendingPartnerName }) }}
          </p>
          <p v-if="pendingInviteUrl" class="mt-2 break-all text-sm text-muted">
            {{ pendingInviteUrl }}
          </p>
          <UAlert
            v-if="inviteError"
            class="mt-3"
            color="warning"
            variant="soft"
            :description="inviteError"
          />
        </div>
        <div class="flex flex-wrap gap-2 md:justify-end">
          <UButton
            icon="i-lucide-link"
            :label="t('edit.generateInvite')"
            :loading="generatingInvite"
            type="button"
            @click="createPartnerInvite"
          />
          <UButton
            v-if="pendingInviteUrl"
            icon="i-lucide-copy"
            :label="t('edit.copyInvite')"
            variant="outline"
            type="button"
            @click="copyPendingInvite"
          />
        </div>
      </div>
    </UCard>

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

    <section v-if="editableTimelineWidgets.length" class="space-y-3">
      <h2 class="text-xl font-black">{{ t('edit.relationshipTimeline') }}</h2>
      <UCard v-for="widget in editableTimelineWidgets" :key="widget.id">
        <form class="grid gap-4" @submit.prevent="saveTimelineWidget(widget)">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div class="flex items-center gap-2">
              <UBadge color="success" variant="soft">{{ t('edit.staticWidget') }}</UBadge>
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
              <UButton
                :label="t('edit.addMilestone')"
                variant="outline"
                size="sm"
                type="button"
                @click="addTimelineEntry(widget)"
              />
              <UButton :label="t('edit.save')" size="sm" type="submit" />
            </div>
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <UFormField :label="t('edit.timelineTitle')">
              <UInput v-model="widget.label" class="w-full font-semibold" />
            </UFormField>
            <UFormField :label="t('edit.timelineSummary')">
              <UInput v-model="widget.value" class="w-full" />
            </UFormField>
          </div>

          <div class="grid gap-3">
            <div
              v-for="entry in widget.timelineEntries"
              :key="entry.id"
              class="grid gap-3 rounded-md border border-default p-3"
            >
              <div class="flex items-center justify-between gap-3">
                <UBadge color="neutral" variant="soft">{{ entry.title }}</UBadge>
                <UButton
                  :label="t('edit.delete')"
                  color="error"
                  variant="ghost"
                  size="sm"
                  type="button"
                  @click="removeTimelineEntry(widget, entry.id)"
                />
              </div>
              <div class="grid gap-3 sm:grid-cols-2">
                <UFormField :label="t('edit.milestoneTitle')">
                  <UInput v-model="entry.title" class="w-full" />
                </UFormField>
                <UFormField :label="t('edit.milestoneDate')">
                  <UInput v-model="entry.date" class="w-full" type="date" />
                </UFormField>
              </div>
              <UFormField :label="t('edit.milestoneDescription')">
                <UTextarea v-model="entry.description" autoresize class="w-full" />
              </UFormField>
              <UFormField :label="t('edit.icon')">
                <UInput v-model="entry.icon" class="w-full" placeholder="i-lucide-heart" />
              </UFormField>
            </div>
          </div>
        </form>
      </UCard>
    </section>

    <section class="space-y-3">
      <h2 class="text-xl font-black">{{ t('edit.editLiveMetrics') }}</h2>
      <UCard v-for="widget in editableMetricWidgets" :key="widget.id">
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
