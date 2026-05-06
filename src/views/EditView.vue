<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AuthPanel from '@/components/AuthPanel.vue'
import PartnerHungerLevelPanel from '@/components/PartnerHungerLevelPanel.vue'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { alertTemplates } from '@/data/alertTemplates'
import {
  partnerAvatarBucket,
  partnerAvatarExtension,
  partnerAvatarMaxSize,
  partnerAvatarMimeTypes,
  supabase,
  type CoupleInviteStatus,
  type PendingPartnerInvite,
} from '@/services/supabase'
import type { AlertSeverity, DashboardWidget, TimelineEntry } from '@/types'

interface AlertTemplateDraft {
  id: string
  title: string
  severity: AlertSeverity
}

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
  updateCoupleSettings,
  updateWidget,
  updatePartnerHungerLevel,
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
const customAlertDraft = ref('')
const avatarFile = ref<File | null>(null)
const avatarError = ref<string | null>(null)
const uploadingAvatar = ref(false)
const alertTemplateDrafts = ref<AlertTemplateDraft[]>([])
const editingAlertTemplateId = ref<string | null>(null)
const alertTemplateEditTitle = ref('')
const settingsForm = ref({
  relationshipStart: '',
  weddingDate: '',
  choreTurnPartnerId: null as string | null,
})
const savingSettings = ref(false)
const settingsError = ref<string | null>(null)
const partner = computed(() =>
  couple.value?.partners.find((item) => item.id === currentPartnerId.value),
)
const selectedChorePartner = computed(() =>
  couple.value?.partners.find((item) => item.id === settingsForm.value.choreTurnPartnerId),
)
const pendingPartnerName = computed(() => inviteStatus.value?.pending_partner_name ?? null)
const pendingInviteUrl = computed(() => {
  if (!pendingInvite.value || typeof window === 'undefined') {
    return ''
  }

  const origin = window.location.origin.replace(/\/$/, '')
  return `${origin}/invite/${pendingInvite.value.couple_slug}/${pendingInvite.value.partner_slug}?token=${pendingInvite.value.invite_token}`
})
const editableWidgets = computed(() => widgets.value)
const editableMetricWidgets = computed(() =>
  editableWidgets.value.filter((widget) => widget.visual !== 'timeline'),
)
const editableTimelineWidgets = computed(() =>
  editableWidgets.value.filter((widget) => widget.visual === 'timeline'),
)
const today = new Date().toISOString().slice(0, 10)
const avatarAccept = partnerAvatarMimeTypes.join(',')

const toneOptionValues: AlertSeverity[] = ['info', 'success', 'warning', 'error']
const alertTemplateOwnerKey = computed(() => currentPartnerId.value ?? 'unlinked')
const alertTemplateStorageKey = computed(
  () => `couple-dash-alert-templates:${coupleSlug.value}:${alertTemplateOwnerKey.value}`,
)
const seededAlertTemplates = computed<AlertTemplateDraft[]>(() =>
  alertTemplates.map((template) => ({
    id: template.id,
    title: template.text,
    severity: template.severity,
  })),
)
const alertTemplateCount = computed(() => alertTemplateDrafts.value.length)
const editAccordionItems = computed(() => [
  ...(editableTimelineWidgets.value.length
    ? [
        {
          label: `${t('edit.relationshipTimeline')} (${editableTimelineWidgets.value.length})`,
          icon: 'i-lucide-milestone',
          value: 'relationship-timeline',
        },
      ]
    : []),
  {
    label: `${t('edit.editLiveMetrics')} (${editableMetricWidgets.value.length})`,
    icon: 'i-lucide-list-checks',
    value: 'live-metrics',
  },
  {
    label: `${t('edit.alerts')} (${alerts.value.length}/${alertTemplateCount.value})`,
    icon: 'i-lucide-message-circle-warning',
    value: 'alerts',
  },
])

function dateInputValue(value: string) {
  return value.slice(0, 10)
}

function syncSettingsForm() {
  if (!couple.value) {
    return
  }

  settingsForm.value = {
    relationshipStart: dateInputValue(couple.value.relationshipStart),
    weddingDate: dateInputValue(couple.value.weddingDate),
    choreTurnPartnerId: couple.value.choreTurnPartnerId ?? null,
  }
}

async function saveSettings() {
  settingsError.value = null

  if (!settingsForm.value.relationshipStart || !settingsForm.value.weddingDate) {
    settingsError.value = t('edit.settingsDateRequired')
    return
  }

  savingSettings.value = true

  try {
    await updateCoupleSettings(settingsForm.value)
  } catch (error) {
    settingsError.value = error instanceof Error ? error.message : t('edit.settingsSaveFailed')
  } finally {
    savingSettings.value = false
  }
}

async function toggleChorePartner(partnerId: string) {
  settingsForm.value.choreTurnPartnerId =
    settingsForm.value.choreTurnPartnerId === partnerId ? null : partnerId
  await saveSettings()
}
async function loadMembership() {
  currentPartnerId.value = null
  membershipError.value = null

  if (!isSupabaseConfigured || !supabase || !couple.value || !userId.value) {
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
  if (!isSupabaseConfigured || !isAuthenticated.value) {
    return
  }

  await loadCouple()
  await loadMembership()
  await loadInviteStatus()
}

function formatBytes(bytes: number) {
  return `${Math.round((bytes / 1024 / 1024) * 10) / 10} MB`
}

function validateAvatarFile(file: File) {
  if (!partnerAvatarMimeTypes.includes(file.type)) {
    return t('edit.avatarInvalidType')
  }

  if (file.size > partnerAvatarMaxSize) {
    return t('edit.avatarTooLarge', { size: formatBytes(partnerAvatarMaxSize) })
  }

  return null
}

async function uploadPartnerAvatar() {
  avatarError.value = null

  if (!supabase || !couple.value || !partner.value || !avatarFile.value) {
    return
  }

  const file = avatarFile.value
  const validationError = validateAvatarFile(file)
  if (validationError) {
    avatarError.value = validationError
    return
  }

  uploadingAvatar.value = true
  const previousAvatarPath = partner.value.avatarPath
  const avatarPath = `${couple.value.id}/${partner.value.id}/${crypto.randomUUID()}.${partnerAvatarExtension(file.type)}`

  const { error: uploadError } = await supabase.storage
    .from(partnerAvatarBucket)
    .upload(avatarPath, file, {
      cacheControl: '3600',
      contentType: file.type,
      upsert: false,
    })

  if (uploadError) {
    avatarError.value = uploadError.message
    uploadingAvatar.value = false
    return
  }

  const { error: updateError } = await supabase.rpc('update_partner_avatar', {
    p_partner_id: partner.value.id,
    p_avatar_path: avatarPath,
  })

  if (updateError) {
    await supabase.storage.from(partnerAvatarBucket).remove([avatarPath])
    avatarError.value = updateError.message
    uploadingAvatar.value = false
    return
  }

  avatarFile.value = null
  await loadCouple()

  if (previousAvatarPath && previousAvatarPath !== avatarPath) {
    await supabase.storage.from(partnerAvatarBucket).remove([previousAvatarPath])
  }

  uploadingAvatar.value = false
}

async function saveWidget(widget: DashboardWidget) {
  await updateWidget(widget.id, {
    label: widget.label,
    value: widget.value,
    detail: widget.detail,
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
      description: '',
      icon: entry.icon || 'i-lucide-heart',
    })),
  })
}

function loadAlertTemplates() {
  if (typeof localStorage === 'undefined') {
    alertTemplateDrafts.value = seededAlertTemplates.value
    return
  }

  const stored =
    localStorage.getItem(alertTemplateStorageKey.value) ??
    localStorage.getItem(`couple-dash-alert-templates:${coupleSlug.value}`)
  if (!stored) {
    alertTemplateDrafts.value = seededAlertTemplates.value
    return
  }

  try {
    const parsed = JSON.parse(stored) as Partial<AlertTemplateDraft>[]
    alertTemplateDrafts.value = parsed
      .filter((item) => item.id && item.title)
      .map((item) => ({
        id: String(item.id),
        title: normalizeAlertTitle(String(item.title)),
        severity: toneOptionValues.includes(item.severity as AlertSeverity)
          ? (item.severity as AlertSeverity)
          : 'info',
      }))
  } catch {
    alertTemplateDrafts.value = seededAlertTemplates.value
  }
}

function persistAlertTemplates() {
  if (typeof localStorage === 'undefined') {
    return
  }

  localStorage.setItem(alertTemplateStorageKey.value, JSON.stringify(alertTemplateDrafts.value))
}

function normalizeAlertTitle(text: string) {
  return text.trim()
}

function addCustomAlertTemplate() {
  const title = normalizeAlertTitle(customAlertDraft.value)
  if (!title) {
    return
  }

  const exists = alertTemplateDrafts.value.some(
    (template) => template.title.toLowerCase() === title.toLowerCase(),
  )
  if (!exists) {
    alertTemplateDrafts.value = [
      ...alertTemplateDrafts.value,
      {
        id: crypto.randomUUID(),
        title,
        severity: 'info',
      },
    ]
    persistAlertTemplates()
  }

  customAlertDraft.value = ''
}

async function removeAlertTemplate(template: AlertTemplateDraft) {
  const activeAlert = activeAlertForTitle(template.title)
  if (activeAlert) {
    await setAlertActive(activeAlert.id, false)
  }

  alertTemplateDrafts.value = alertTemplateDrafts.value.filter((item) => item.id !== template.id)
  if (editingAlertTemplateId.value === template.id) {
    editingAlertTemplateId.value = null
    alertTemplateEditTitle.value = ''
  }
  persistAlertTemplates()
}

function editAlertTemplate(template: AlertTemplateDraft) {
  editingAlertTemplateId.value = template.id
  alertTemplateEditTitle.value = template.title
}

function cancelAlertTemplateEdit() {
  editingAlertTemplateId.value = null
  alertTemplateEditTitle.value = ''
}

async function saveAlertTemplate(template: AlertTemplateDraft) {
  const previousTitle = template.title
  const title = normalizeAlertTitle(alertTemplateEditTitle.value)
  if (!title) {
    await removeAlertTemplate(template)
    return
  }

  const activeAlert = activeAlertForTitle(previousTitle)
  alertTemplateDrafts.value = alertTemplateDrafts.value.map((item) =>
    item.id === template.id ? { ...item, title } : item,
  )
  persistAlertTemplates()

  if (activeAlert && previousTitle !== title) {
    await setAlertActive(activeAlert.id, false)
    await sendAlert({ ...template, title })
  }

  cancelAlertTemplateEdit()
}

async function sendAlert(alert: Pick<AlertTemplateDraft, 'title' | 'severity'>) {
  if (!couple.value) {
    return
  }

  await triggerAlert({
    coupleId: couple.value.id,
    title: alert.title,
    detail: t('edit.raisedFrom', { name: partner.value?.name ?? t('alerts.partnerFallback') }),
    severity: alert.severity,
    source: 'partner',
    triggeredByPartnerId: currentPartnerId.value ?? undefined,
    triggeredBy: partner.value?.name,
  })
}

function activeAlertForTitle(title: string) {
  return alerts.value.find((alert) => {
    if (normalizeAlertTitle(alert.title) !== title || alert.source !== 'partner') {
      return false
    }

    if (alert.triggeredByPartnerId) {
      return alert.triggeredByPartnerId === currentPartnerId.value
    }

    return !!partner.value?.name && alert.triggeredBy === partner.value.name
  })
}

async function toggleAlert(alert: Pick<AlertTemplateDraft, 'title' | 'severity'>) {
  const activeAlert = activeAlertForTitle(alert.title)

  if (activeAlert) {
    await setAlertActive(activeAlert.id, false)
    return
  }

  await sendAlert(alert)
}

function alertButtonColor(alert: Pick<AlertTemplateDraft, 'title' | 'severity'>) {
  return activeAlertForTitle(alert.title) ? alert.severity : 'neutral'
}

function alertButtonVariant(alert: Pick<AlertTemplateDraft, 'title'>) {
  return activeAlertForTitle(alert.title) ? 'soft' : 'ghost'
}

function alertButtonIcon(alert: Pick<AlertTemplateDraft, 'title'>) {
  return activeAlertForTitle(alert.title) ? 'i-lucide-toggle-right' : 'i-lucide-toggle-left'
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
watch([coupleSlug, alertTemplateOwnerKey], loadAlertTemplates)
watch(couple, syncSettingsForm)

onMounted(() => {
  void loadPrivateEditor().then(loadAlertTemplates)
})
</script>

<template>
  <section v-if="isSupabaseConfigured && initialized && !isAuthenticated" class="mx-auto max-w-md">
    <AuthPanel />
  </section>

  <section v-else-if="!isSupabaseConfigured" class="mx-auto max-w-md">
    <UAlert color="warning" variant="soft" :description="t('dashboard.supabaseRequired')" />
  </section>

  <section v-else-if="couple" class="mx-auto max-w-5xl space-y-6 pb-10">
    <div class="flex items-center justify-between gap-4">
      <div>
        <p class="text-sm font-semibold text-muted">{{ couple.name }}</p>
        <h1 class="text-3xl font-black">
          {{ t('edit.sharedDashboardEditor') }}
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

    <UCard v-if="partner" variant="subtle" :ui="{ body: 'p-4 sm:p-5' }">
      <div class="grid gap-4 sm:grid-cols-[auto_1fr] sm:items-center">
        <UAvatar
          :src="partner.avatarUrl"
          :text="partner.avatarUrl ? undefined : partner.avatarFallback"
          :alt="partner.name"
          size="3xl"
          class="ring ring-default"
        />
        <div class="min-w-0">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-xl font-black">{{ t('edit.personalPhoto') }}</h2>
            <UBadge color="neutral" variant="soft">{{ partner.name }}</UBadge>
          </div>
          <p class="mt-1 text-sm text-muted">{{ t('edit.personalPhotoDescription') }}</p>

          <form
            class="mt-4 grid gap-3 sm:grid-cols-[1fr_auto] sm:items-end"
            @submit.prevent="uploadPartnerAvatar"
          >
            <UFormField
              :label="t('edit.avatarUpload')"
              :description="t('edit.avatarFileHelp', { size: formatBytes(partnerAvatarMaxSize) })"
              :error="avatarError ?? undefined"
            >
              <UFileUpload
                v-model="avatarFile"
                :accept="avatarAccept"
                :label="t('edit.choosePhoto')"
                variant="button"
                color="neutral"
              />
            </UFormField>
            <UButton
              icon="i-lucide-upload"
              :label="t('edit.savePhoto')"
              :disabled="!avatarFile"
              :loading="uploadingAvatar"
              type="submit"
            />
          </form>
        </div>
      </div>
    </UCard>

    <UCard variant="subtle" :ui="{ body: 'p-4 sm:p-5' }">
      <form class="grid gap-4" @submit.prevent="saveSettings">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 class="text-xl font-black">{{ t('edit.remoteSettings') }}</h2>
            <p class="text-sm text-muted">{{ t('edit.remoteSettingsDescription') }}</p>
          </div>
          <UButton
            icon="i-lucide-save"
            :label="t('edit.save')"
            :loading="savingSettings"
            type="submit"
          />
        </div>

        <div class="grid gap-3 md:grid-cols-2">
          <UFormField :label="t('edit.weddingDate')" required>
            <UInput v-model="settingsForm.weddingDate" class="w-full" required type="date" />
          </UFormField>
          <UFormField :label="t('edit.sharedMemoryStart')" required>
            <UInput
              v-model="settingsForm.relationshipStart"
              class="w-full"
              required
              type="date"
            />
          </UFormField>
        </div>

        <div class="grid gap-3">
          <div>
            <h3 class="text-base font-black">{{ t('edit.coffeeTurnTitle') }}</h3>
            <p class="text-sm text-muted">
              {{ selectedChorePartner?.name ?? t('edit.noCoffeePartner') }}
            </p>
          </div>
          <div class="grid gap-2 sm:grid-cols-2">
            <UButton
              v-for="item in couple.partners"
              :key="item.id"
              class="justify-center"
              :color="settingsForm.choreTurnPartnerId === item.id ? 'primary' : 'neutral'"
              :icon="
                settingsForm.choreTurnPartnerId === item.id
                  ? 'i-lucide-toggle-right'
                  : 'i-lucide-toggle-left'
              "
              :label="item.name"
              :variant="settingsForm.choreTurnPartnerId === item.id ? 'solid' : 'outline'"
              type="button"
              @click="toggleChorePartner(item.id)"
            />
          </div>
        </div>

        <UAlert v-if="settingsError" color="warning" variant="soft" :description="settingsError" />
      </form>
    </UCard>

    <PartnerHungerLevelPanel
      :partners="couple.partners"
      :update-hunger-level="updatePartnerHungerLevel"
      :title="t('hunger.title')"
      :description="t('hunger.description')"
    />

    <div class="grid gap-3 sm:grid-cols-2">
      <UCard variant="subtle" :ui="{ body: 'p-4 sm:p-4' }">
        <div class="flex items-center justify-between gap-3">
          <div>
            <div class="text-sm text-muted">{{ t('edit.editableMetrics') }}</div>
            <div class="text-sm text-muted">{{ t('edit.editableMetricsDescription') }}</div>
          </div>
          <div class="text-3xl font-black leading-none">{{ editableMetricWidgets.length }}</div>
        </div>
      </UCard>
      <UCard variant="subtle" :ui="{ body: 'p-4 sm:p-4' }">
        <div class="flex items-center justify-between gap-3">
          <div>
            <div class="text-sm text-muted">{{ t('edit.alerts') }}</div>
            <div class="text-sm text-muted">{{ t('edit.customAlert') }}</div>
          </div>
          <div class="text-3xl font-black leading-none text-amber-500">
            {{ alertTemplateCount }}
          </div>
        </div>
      </UCard>
    </div>

    <UAccordion
      :items="editAccordionItems"
      :unmount-on-hide="false"
      type="multiple"
      class="rounded-xl border border-default px-4"
    >
      <template #body="{ item }">
        <section v-if="item.value === 'relationship-timeline'" class="space-y-3">
          <UCard
            v-for="widget in editableTimelineWidgets"
            :key="widget.id"
            variant="subtle"
            :ui="{ body: 'p-4 sm:p-4' }"
          >
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

              <div class="grid gap-2">
                <div
                  v-for="entry in widget.timelineEntries"
                  :key="entry.id"
                  class="grid gap-3 rounded-md border border-default p-3 lg:grid-cols-[1fr_10rem_10rem_auto] lg:items-end"
                >
                  <UFormField :label="t('edit.milestoneTitle')">
                    <UInput v-model="entry.title" class="w-full" />
                  </UFormField>
                  <UFormField :label="t('edit.milestoneDate')">
                    <UInput v-model="entry.date" class="w-full" type="date" />
                  </UFormField>
                  <UFormField :label="t('edit.icon')">
                    <UInput v-model="entry.icon" class="w-full" placeholder="i-lucide-heart" />
                  </UFormField>
                  <UButton
                    :label="t('edit.delete')"
                    color="error"
                    variant="ghost"
                    size="sm"
                    type="button"
                    @click="removeTimelineEntry(widget, entry.id)"
                  />
                </div>
              </div>
            </form>
          </UCard>
        </section>

        <section v-else-if="item.value === 'live-metrics'" class="space-y-4">
          <div class="space-y-3">
            <UCard
              v-for="widget in editableMetricWidgets"
              :key="widget.id"
              variant="subtle"
              :ui="{ body: 'p-4 sm:p-4' }"
            >
              <form class="grid gap-4" @submit.prevent="saveWidget(widget)">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div class="flex items-center gap-2">
                    <UBadge color="info" variant="soft">{{ t('edit.sharedDashboard') }}</UBadge>
                  </div>
                  <div class="flex gap-2">
                    <UButton :label="t('edit.save')" size="sm" type="submit" />
                  </div>
                </div>

                <div class="grid gap-3 sm:grid-cols-2">
                  <UFormField :label="t('edit.metricKey')">
                    <UInput v-model="widget.label" class="w-full font-semibold" />
                  </UFormField>
                  <UFormField :label="t('edit.value')">
                    <UInput v-model="widget.value" class="w-full text-lg" />
                  </UFormField>
                </div>

                <UFormField :label="t('edit.explanation')">
                  <UTextarea v-model="widget.detail" autoresize class="w-full" />
                </UFormField>
              </form>
            </UCard>
          </div>
        </section>

        <section v-else class="space-y-3">
          <div class="grid gap-2 lg:grid-cols-2">
            <div
              v-for="template in alertTemplateDrafts"
              :key="template.id"
              class="grid min-h-10 grid-cols-[1fr_auto] items-center gap-2 rounded-md border border-default bg-muted/40 p-2"
            >
              <template v-if="editingAlertTemplateId === template.id">
                <UInput
                  v-model="alertTemplateEditTitle"
                  :aria-label="t('edit.customAlert')"
                  class="min-w-0"
                  size="sm"
                  @keyup.enter="saveAlertTemplate(template)"
                  @keyup.esc="cancelAlertTemplateEdit"
                />
                <div class="flex gap-1">
                  <UButton
                    :aria-label="t('edit.save')"
                    color="neutral"
                    icon="i-lucide-check"
                    size="sm"
                    variant="ghost"
                    type="button"
                    @click="saveAlertTemplate(template)"
                  />
                  <UButton
                    :aria-label="t('edit.cancel')"
                    color="neutral"
                    icon="i-lucide-x"
                    size="sm"
                    variant="ghost"
                    type="button"
                    @click="cancelAlertTemplateEdit"
                  />
                  <UButton
                    :aria-label="t('edit.delete')"
                    color="neutral"
                    icon="i-lucide-trash-2"
                    size="sm"
                    variant="ghost"
                    type="button"
                    @click="removeAlertTemplate(template)"
                  />
                </div>
              </template>
              <template v-else>
                <UButton
                  class="min-w-0 justify-start text-left"
                  :color="alertButtonColor(template)"
                  :icon="alertButtonIcon(template)"
                  :label="template.title"
                  :variant="alertButtonVariant(template)"
                  type="button"
                  @click="toggleAlert(template)"
                />
                <UButton
                  :aria-label="t('edit.edit')"
                  color="neutral"
                  icon="i-lucide-pencil"
                  size="sm"
                  variant="ghost"
                  type="button"
                  @click="editAlertTemplate(template)"
                />
              </template>
            </div>
          </div>

          <form
            class="grid gap-2 rounded-md border border-default bg-muted/40 p-2 sm:grid-cols-[1fr_auto]"
            @submit.prevent="addCustomAlertTemplate"
          >
            <UInput
              v-model="customAlertDraft"
              :aria-label="t('edit.customAlert')"
              class="w-full"
              :placeholder="t('edit.customAlertPlaceholder')"
            />
            <UButton
              class="justify-center"
              :label="t('edit.saveCustomAlert')"
              icon="i-lucide-plus"
              type="submit"
            />
          </form>
        </section>
      </template>
    </UAccordion>
  </section>

  <section v-else class="mx-auto max-w-md">
    <UAlert color="warning" variant="soft" :description="t('edit.noDashboard')" />
  </section>
</template>
