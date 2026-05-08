<script setup lang="ts">
import { computed, ref } from 'vue'
import type { CoupleChoreTask, Partner } from '@/types'

const props = defineProps<{
  partners: (Partner | undefined)[]
  tasks: CoupleChoreTask[]
  updateTask?: (
    taskId: string,
    patch: { title: string; assignedPartnerId?: string },
  ) => Promise<void>
}>()

const savingTaskIds = ref<string[]>([])
const errorMessage = ref<string | null>(null)
const leftPartner = computed(() => props.partners[0])
const rightPartner = computed(() => props.partners[1])
const partnerTaskSummaries = computed(() => {
  const availablePartners = props.partners.filter((partner): partner is Partner => !!partner)
  const counts = availablePartners.map((partner) => ({
    partner,
    count: props.tasks.filter((task) => task.assignedPartnerId === partner.id).length,
  }))
  const maxCount = counts.reduce((max, item) => Math.max(max, item.count), 0)
  const hasLeader = counts.length > 1 && counts.some((item) => item.count !== maxCount)

  return counts.map((item) => ({
    ...item,
    isWinner: hasLeader && item.count === maxCount,
    isLazy: hasLeader && item.count < maxCount,
  }))
})

function isSaving(taskId: string) {
  return savingTaskIds.value.includes(taskId)
}

function isAssignedTo(task: CoupleChoreTask, partner?: Partner) {
  return !!partner && task.assignedPartnerId === partner.id
}

function activePartner(task: CoupleChoreTask) {
  return props.partners.find((partner) => partner?.id === task.assignedPartnerId)
}

async function setTaskPartner(task: CoupleChoreTask, partner?: Partner) {
  if (!props.updateTask || !partner || isAssignedTo(task, partner) || isSaving(task.id)) {
    return
  }

  errorMessage.value = null
  savingTaskIds.value = [...savingTaskIds.value, task.id]

  try {
    await props.updateTask(task.id, {
      title: task.title,
      assignedPartnerId: partner.id,
    })
  } catch (error) {
    errorMessage.value =
      error instanceof Error ? error.message : 'Aufgabe konnte nicht gespeichert werden.'
  } finally {
    savingTaskIds.value = savingTaskIds.value.filter((id) => id !== task.id)
  }
}

async function toggleTask(task: CoupleChoreTask) {
  const nextPartner = isAssignedTo(task, leftPartner.value) ? rightPartner.value : leftPartner.value
  await setTaskPartner(task, nextPartner)
}
</script>

<template>
  <UCard
    class="border-primary/15 bg-white/[0.075] shadow-2xl shadow-primary/10 backdrop-blur-xl"
    :ui="{ body: 'h-full p-5 sm:p-6' }"
  >
    <div class="flex items-start justify-between gap-3">
      <div>
        <p class="mb-2 text-xs font-extrabold uppercase text-primary">Haushalt & Kaffee</p>
        <h2 class="text-2xl font-black leading-none">Wer ist dran?</h2>
      </div>
      <UIcon name="i-lucide-list-checks" class="mt-1 size-7 text-primary" />
    </div>

    <div class="mt-5 grid gap-2 sm:grid-cols-2">
      <article
        v-for="summary in partnerTaskSummaries"
        :key="summary.partner.id"
        :class="[
          'flex min-w-0 items-center justify-between gap-3 rounded-md border px-3 py-2',
          summary.isWinner
            ? 'border-primary/60 bg-primary/20 text-white shadow-lg shadow-primary/10'
            : 'border-primary/15 bg-black/15 text-white/70',
        ]"
      >
        <div class="flex min-w-0 items-center gap-2">
          <UAvatar
            :src="summary.partner.avatarUrl"
            :text="summary.partner.avatarUrl ? undefined : summary.partner.avatarFallback"
            :alt="summary.partner.name"
            size="sm"
            class="ring-1 ring-primary/40"
            loading="lazy"
          />
          <span class="truncate text-sm font-black">{{ summary.partner.name }}</span>
        </div>
        <div class="flex shrink-0 items-center gap-1.5 text-sm font-black">
          <span>{{ summary.count }}</span>
          <UIcon v-if="summary.isWinner" name="i-lucide-hammer" class="size-4 text-primary" />
          <UIcon v-else-if="summary.isLazy" name="i-lucide-bed" class="size-4 text-white/55" />
          <span
            :class="
              summary.isWinner ? 'text-primary' : summary.isLazy ? 'text-white/55' : 'text-white/45'
            "
          >
            {{ summary.isWinner ? 'Arbeitstier' : summary.isLazy ? 'Faultier' : 'Tasks' }}
          </span>
        </div>
      </article>
    </div>

    <div class="mt-5 grid gap-3">
      <article
        v-for="task in tasks"
        :key="task.id"
        class="rounded-md border border-primary/15 bg-black/15 p-3"
      >
        <div class="mb-3 flex items-center gap-2">
          <UIcon :name="task.icon" class="size-5 shrink-0 text-primary" />
          <p class="min-w-0 flex-1 truncate text-sm font-black text-white/90">{{ task.title }}</p>
          <UBadge v-if="activePartner(task)" color="primary" variant="soft">
            {{ activePartner(task)?.name }}
          </UBadge>
        </div>

        <div class="grid grid-cols-[minmax(0,1fr)_4rem_minmax(0,1fr)] items-center gap-2">
          <button
            type="button"
            :disabled="!props.updateTask || isSaving(task.id)"
            :class="[
              'grid min-h-24 min-w-0 place-items-center gap-1 rounded-md border p-2 text-center transition',
              isAssignedTo(task, leftPartner)
                ? 'border-primary/70 bg-primary/20 shadow-lg shadow-primary/15'
                : 'border-primary/15 bg-black/15 opacity-65',
              props.updateTask ? 'cursor-pointer hover:border-primary/45' : 'cursor-default',
            ]"
            @click="setTaskPartner(task, leftPartner)"
          >
            <UAvatar
              :src="leftPartner?.avatarUrl"
              :text="leftPartner?.avatarUrl ? undefined : leftPartner?.avatarFallback"
              :alt="leftPartner?.name ?? 'Partner 1'"
              size="lg"
              :class="[
                'ring-2',
                isAssignedTo(task, leftPartner) ? 'ring-primary/70' : 'ring-white/15',
              ]"
              loading="lazy"
            />
            <span class="max-w-full truncate text-sm font-black">
              {{ leftPartner?.name ?? 'Partner 1' }}
            </span>
          </button>

          <button
            type="button"
            :disabled="!props.updateTask || !leftPartner || !rightPartner || isSaving(task.id)"
            class="relative h-9 rounded-full border border-primary/25 bg-black/30 p-1 shadow-inner shadow-primary/10 transition enabled:hover:border-primary/60"
            :aria-label="`Turn wechseln: ${task.title}`"
            @click="toggleTask(task)"
          >
            <span
              :class="[
                'grid size-7 place-items-center rounded-full bg-primary text-black transition-transform',
                isAssignedTo(task, rightPartner) ? 'translate-x-7' : 'translate-x-0',
              ]"
            >
              <UIcon
                :name="isSaving(task.id) ? 'i-lucide-loader-2' : 'i-lucide-repeat-2'"
                :class="['size-4', isSaving(task.id) ? 'animate-spin' : '']"
              />
            </span>
          </button>

          <button
            type="button"
            :disabled="!props.updateTask || isSaving(task.id)"
            :class="[
              'grid min-h-24 min-w-0 place-items-center gap-1 rounded-md border p-2 text-center transition',
              isAssignedTo(task, rightPartner)
                ? 'border-primary/70 bg-primary/20 shadow-lg shadow-primary/15'
                : 'border-primary/15 bg-black/15 opacity-65',
              props.updateTask ? 'cursor-pointer hover:border-primary/45' : 'cursor-default',
            ]"
            @click="setTaskPartner(task, rightPartner)"
          >
            <UAvatar
              :src="rightPartner?.avatarUrl"
              :text="rightPartner?.avatarUrl ? undefined : rightPartner?.avatarFallback"
              :alt="rightPartner?.name ?? 'Partner 2'"
              size="lg"
              :class="[
                'ring-2',
                isAssignedTo(task, rightPartner) ? 'ring-primary/70' : 'ring-white/15',
              ]"
              loading="lazy"
            />
            <span class="max-w-full truncate text-sm font-black">
              {{ rightPartner?.name ?? 'Partner 2' }}
            </span>
          </button>
        </div>
      </article>
    </div>

    <UAlert
      v-if="errorMessage"
      class="mt-4"
      color="warning"
      variant="soft"
      :description="errorMessage"
    />
  </UCard>
</template>
