<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<template>
  <section class="mx-auto max-w-3xl space-y-6">
    <div>
      <h1 class="text-3xl font-black">{{ t('legal.impressumTitle') }}</h1>
    </div>

    <UCard>
      <div class="space-y-5">
        <section>
          <h2 class="font-bold">{{ t('legal.provider') }}</h2>
          <address class="mt-2 not-italic leading-relaxed text-muted">
            Marcel Park<br />
            Amselstr. 16<br />
            90439 Nürnberg
          </address>
        </section>

        <section>
          <h2 class="font-bold">{{ t('legal.contact') }}</h2>
          <dl class="mt-2 grid gap-2 text-muted">
            <div>
              <dt class="font-medium text-default">{{ t('legal.phone') }}</dt>
              <dd><a class="hover:text-primary" href="tel:+491731356466">+49 173 1356466</a></dd>
            </div>
            <div>
              <dt class="font-medium text-default">{{ t('legal.email') }}</dt>
              <dd>
                <a class="hover:text-primary" href="mailto:marcel_park@gmx.de">
                  marcel_park@gmx.de
                </a>
              </dd>
            </div>
          </dl>
        </section>
      </div>
    </UCard>
  </section>
</template>
