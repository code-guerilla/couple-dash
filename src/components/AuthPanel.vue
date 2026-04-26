<script setup lang="ts">
import Button from 'primevue/button'
import Card from 'primevue/card'
import InputText from 'primevue/inputtext'
import Message from 'primevue/message'
import Password from 'primevue/password'
import { ref } from 'vue'
import { useSupabaseAuth } from '@/composables/useSupabaseAuth'

const emit = defineEmits<{
  signedIn: []
}>()

const { loading, error, signIn, signUp } = useSupabaseAuth()
const email = ref('')
const password = ref('')
const mode = ref<'sign-in' | 'sign-up'>('sign-in')

async function submit() {
  if (mode.value === 'sign-in') {
    await signIn(email.value, password.value)
  } else {
    await signUp(email.value, password.value)
  }

  emit('signedIn')
}
</script>

<template>
  <Card>
    <template #title>{{ mode === 'sign-in' ? 'Sign in' : 'Create account' }}</template>
    <template #subtitle>Dashboard access uses Supabase Auth.</template>
    <template #content>
      <form class="form-stack" @submit.prevent="submit">
        <Message v-if="error" severity="error" :closable="false">{{ error }}</Message>

        <label class="field-stack">
          <span class="field-label">Email</span>
          <InputText v-model="email" autocomplete="email" fluid required type="email" />
        </label>

        <label class="field-stack">
          <span class="field-label">Password</span>
          <Password
            v-model="password"
            autocomplete="current-password"
            fluid
            :feedback="false"
            input-class="w-full"
            minlength="6"
            required
            toggle-mask
          />
        </label>

        <Button :label="mode === 'sign-in' ? 'Sign in' : 'Create account'" :loading="loading" type="submit" />

        <Button
          :label="mode === 'sign-in' ? 'Need an account?' : 'Already have an account?'"
          size="small"
          text
          type="button"
          @click="mode = mode === 'sign-in' ? 'sign-up' : 'sign-in'"
        />
      </form>
    </template>
  </Card>
</template>
