import { readonly, ref } from 'vue'

export type StorageConsent = 'accepted' | 'rejected'

const consentStorageKey = 'couple-dash-storage-consent'
const preferenceStorageKeys = ['couple-dash-locale', 'couple-dash-theme', 'couple-dash-state-v1']

function readConsent(): StorageConsent | null {
  if (typeof window === 'undefined') {
    return null
  }

  const saved = window.localStorage.getItem(consentStorageKey)
  return saved === 'accepted' || saved === 'rejected' ? saved : null
}

const storageConsent = ref<StorageConsent | null>(readConsent())

export function canStorePreferences() {
  return storageConsent.value === 'accepted'
}

export function setStorageConsent(consent: StorageConsent) {
  storageConsent.value = consent

  if (typeof window === 'undefined') {
    return
  }

  window.localStorage.setItem(consentStorageKey, consent)

  if (consent === 'rejected') {
    for (const key of preferenceStorageKeys) {
      window.localStorage.removeItem(key)
    }
  }
}

export function usePrivacyConsent() {
  return {
    storageConsent: readonly(storageConsent),
    canStorePreferences,
    setStorageConsent,
  }
}
