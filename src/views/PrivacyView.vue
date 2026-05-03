<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<template>
  <section class="mx-auto max-w-3xl space-y-6">
    <div>
      <h1 class="text-3xl font-black">{{ t('legal.privacyTitle') }}</h1>
      <p class="mt-2 text-muted">{{ t('legal.privacyIntro') }}</p>
    </div>

    <UCard>
      <div class="space-y-6 leading-relaxed">
        <section>
          <h2 class="text-xl font-black">{{ t('legal.controllerTitle') }}</h2>
          <p class="mt-2 text-muted">
            Marcel Park<br />
            Amselstr. 16<br />
            90439 Nürnberg<br />
            <a class="hover:text-primary" href="mailto:marcel_park@gmx.de">marcel_park@gmx.de</a>
          </p>
        </section>

        <section>
          <h2 class="text-xl font-black">{{ t('legal.accessDataTitle') }}</h2>
          <p class="mt-2 text-muted">{{ t('legal.accessDataText') }}</p>
        </section>

        <section>
          <h2 class="text-xl font-black">{{ t('legal.authTitle') }}</h2>
          <p class="mt-2 text-muted">{{ t('legal.authText') }}</p>
        </section>

        <section>
          <h2 class="text-xl font-black">{{ t('legal.storageTitle') }}</h2>
          <p class="mt-2 text-muted">{{ t('legal.storageText') }}</p>
        </section>

        <section>
          <h2 class="text-xl font-black">{{ t('legal.thirdPartyTitle') }}</h2>
          <p class="mt-2 text-muted">{{ t('legal.thirdPartyText') }}</p>
        </section>

        <section>
          <h2 class="text-xl font-black">{{ t('legal.rightsTitle') }}</h2>
          <p class="mt-2 text-muted">{{ t('legal.rightsText') }}</p>
        </section>
      </div>
    </UCard>

    <UAlert color="warning" variant="soft" :description="t('legal.noLegalAdvice')" />
  </section>
</template>
