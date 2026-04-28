<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AlertFeed from '@/components/AlertFeed.vue'
import MetricTile from '@/components/MetricTile.vue'
import QrCodeCard from '@/components/QrCodeCard.vue'
import { useDashboardStore } from '@/composables/useDashboardStore'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'
import { supabase } from '@/services/supabase'

const route = useRoute()
const router = useRouter()
const coupleSlug = computed(() => String(route.params.coupleSlug))
const displayToken = ref(String(route.query.token ?? ''))
const claimError = ref<string | null>(null)
const claiming = ref(false)
const { ensureAnonymousSession, isSupabaseConfigured } = useSupabaseAuth()
const { couple, visibleWidgets, alerts, loading, error, loadCouple } = useDashboardStore(coupleSlug.value)

const sharedWidgets = computed(() => visibleWidgets.value.filter((widget) => widget.scope === 'shared'))
const personWidgets = computed(() => visibleWidgets.value.filter((widget) => widget.scope === 'person'))

const daysUntilWedding = computed(() => {
  if (!couple.value) {
    return 0
  }

  const today = new Date()
  const wedding = new Date(couple.value.weddingDate)
  return Math.max(0, Math.ceil((wedding.getTime() - today.getTime()) / 86_400_000))
})

const relationshipUptime = computed(() => {
  if (!couple.value) {
    return '0d'
  }

  const start = new Date(couple.value.relationshipStart)
  const days = Math.max(0, Math.floor((Date.now() - start.getTime()) / 86_400_000))
  const years = Math.floor(days / 365)
  const restDays = days % 365
  return `${years}y ${restDays}d`
})

function partnerName(personId?: string) {
  return couple.value?.partners.find((partner) => partner.id === personId)?.name
}

async function claimDisplay() {
  claimError.value = null

  if (!isSupabaseConfigured || !supabase) {
    await loadCouple()
    return
  }

  if (!displayToken.value) {
    claimError.value = 'Enter the private display token for this Raspberry Pi.'
    return
  }

  claiming.value = true
  await ensureAnonymousSession()
  const { error: claimDisplayError } = await supabase.rpc('claim_display_device', {
    p_slug: coupleSlug.value,
    p_display_token: displayToken.value,
  })
  claiming.value = false

  if (claimDisplayError) {
    claimError.value = claimDisplayError.message
    return
  }

  displayToken.value = ''
  await router.replace({ name: 'display', params: { coupleSlug: coupleSlug.value } })
  await loadCouple()
}

onMounted(async () => {
  if (!isSupabaseConfigured) {
    await loadCouple()
    return
  }

  await ensureAnonymousSession()

  if (displayToken.value) {
    await claimDisplay()
    return
  }

  await loadCouple()
})
</script>

<template>
  <section v-if="couple" class="relative space-y-8 pb-36 xl:pb-0">
    <div class="grid gap-4 xl:grid-cols-[1fr_21rem]">
      <div class="hero-panel">
        <div class="w-full justify-start p-6 sm:p-10">
          <div class="max-w-4xl">
            <div class="mb-5 flex flex-wrap gap-2">
              <UBadge color="success" variant="soft">Private display session</UBadge>
              <UBadge color="neutral" variant="soft">
                {{ isSupabaseConfigured ? 'RLS protected realtime' : 'Local demo' }}
              </UBadge>
            </div>
            <h1 class="text-5xl font-black leading-none sm:text-7xl">{{ couple.name }}</h1>
            <p class="mt-4 max-w-2xl text-lg muted">{{ couple.subtitle }}</p>

            <div class="stat-grid mt-8">
              <div class="stat-cell">
                <div class="stat-label">Relationship Uptime</div>
                <div class="stat-value text-green-500">{{ relationshipUptime }}</div>
                <div class="stat-note">Since {{ new Date(couple.relationshipStart).toLocaleDateString() }}</div>
              </div>
              <div class="stat-cell">
                <div class="stat-label">Days Until Wedding</div>
                <div class="stat-value text-primary-500">{{ daysUntilWedding }}</div>
                <div class="stat-note">{{ new Date(couple.weddingDate).toLocaleDateString() }}</div>
              </div>
              <div class="stat-cell">
                <div class="stat-label">Commitment Level</div>
                <div class="stat-value text-primary-400">100%</div>
                <div class="stat-note">No rollback configured</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <AlertFeed :alerts="alerts" />
    </div>

    <div v-if="loading" class="grid gap-4 md:grid-cols-3">
      <USkeleton v-for="item in 6" :key="item" class="h-44" />
    </div>

    <section class="space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-black">Core Couple Metrics</h2>
        <UBadge color="info" variant="soft">{{ sharedWidgets.length }} visible</UBadge>
      </div>
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <MetricTile v-for="widget in sharedWidgets" :key="widget.id" :widget="widget" />
      </div>
    </section>

    <section class="space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-black">Person Metrics</h2>
        <UBadge color="neutral" variant="soft">{{ personWidgets.length }} visible</UBadge>
      </div>
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <MetricTile
          v-for="widget in personWidgets"
          :key="widget.id"
          :owner-name="partnerName(widget.personId)"
          :widget="widget"
        />
      </div>
    </section>

    <div class="grid gap-4 sm:grid-cols-2 xl:hidden">
      <QrCodeCard
        v-for="partner in couple.partners"
        :key="partner.id"
        :label="`${partner.name} edit login`"
        :person="partner.name"
        :url="`/edit/${couple.slug}`"
      />
    </div>

    <div class="pointer-events-none fixed inset-x-4 bottom-4 z-10 hidden justify-between xl:flex">
      <QrCodeCard
        v-for="partner in couple.partners"
        :key="partner.id"
        class="pointer-events-auto"
        :label="`${partner.name} edit login`"
        :person="partner.name"
        :url="`/edit/${couple.slug}`"
      />
    </div>
  </section>

  <section v-else class="mx-auto max-w-xl space-y-4">
    <UCard>
      <form class="form-stack" @submit.prevent="claimDisplay">
        <div>
          <h1 class="text-2xl font-black">Claim Display</h1>
          <p class="text-sm muted">
            This screen needs an authenticated display session before it can read private dashboard data.
          </p>
        </div>

        <UAlert v-if="error || claimError" color="warning" variant="soft" :description="claimError ?? error ?? ''" />

        <UInput
          v-model="displayToken"
          autocomplete="off"
          class="w-full"
          placeholder="Private display token"
          type="password"
        />
        <UButton label="Claim Raspberry Pi display" :loading="claiming" type="submit" />
      </form>
    </UCard>
  </section>
</template>
