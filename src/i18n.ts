import { createI18n } from 'vue-i18n'
import { canStorePreferences } from '@/composables/usePrivacyConsent'

export type LocaleCode = 'en' | 'de'

const storageKey = 'couple-dash-locale'

export const messages = {
  en: {
    nav: {
      home: 'Home',
      admin: 'Admin',
      language: 'Language',
    },
    footer: {
      copyright: '© 2026 Marcel Park - All rights reserved.',
      impressum: 'Legal Notice',
      privacy: 'Privacy Policy',
    },
    consent: {
      title: 'Storage preferences',
      description:
        'This app can store your language and theme settings on this device. No analytics or advertising cookies are used.',
      accept: 'Save preferences',
      reject: 'Use necessary storage only',
    },
    legal: {
      impressumTitle: 'Legal Notice',
      provider: 'Provider',
      contact: 'Contact',
      phone: 'Phone',
      email: 'Email',
      privacyTitle: 'Privacy Policy',
      privacyIntro:
        'This page describes which data is processed when using CoupleDash. It is a technical baseline for a privacy-friendly setup and should be reviewed legally before public launch.',
      controllerTitle: 'Controller',
      accessDataTitle: 'Access data',
      accessDataText:
        'When the site is hosted, the hosting provider may process technical access data such as IP address, time, requested URL, user agent, and status code to deliver and secure the site.',
      authTitle: 'Authentication and dashboard data',
      home: {
        badge: 'Multi-Tenant Dashboards für Paare',
        description:
          'Private Paar-Dashboards werden erst geladen, wenn ein verknüpftes Partner- oder Admin-Konto angemeldet ist.',
        adminDescription: 'Alle Paar-Tenants, Einladungen und Dashboard-Einstellungen verwalten.',
        displayDescription: 'Öffne dein privates Display mit einem verknüpften Partnerkonto.',
        partnerDescription:
          'Partner nutzen /invite-Links einmalig und danach /edit/:slug mit Supabase Auth.',
        accountTitle: 'Dein Paar-Dashboard',
        accountDescription:
          'Hier erscheinen nur Paar-Dashboards, die mit diesem Konto verknüpft sind.',
        openDisplay: 'Display öffnen',
        editDashboard: 'Dashboard bearbeiten',
        loadingCouples: 'Dein Paar-Dashboard wird geladen...',
        noCouples:
          'Mit diesem Konto ist noch kein Paar-Dashboard verknüpft. Nutze zuerst deinen Einladungslink.',
        noSubtitle: 'Kein Untertitel',
        production: 'Produktion',
        wedding: 'Hochzeit',
        partners: 'Partner',
      },
      accountTitle: 'Your couple dashboard',
      accountDescription: 'Only couple dashboards linked to this account appear here.',
      openDisplay: 'Open display',
      editDashboard: 'Edit dashboard',
      loadingCouples: 'Loading your couple dashboard...',
      noCouples: 'No couple dashboard is linked to this account yet. Use your invite link first.',
      noSubtitle: 'No subtitle',
      production: 'Production',
      wedding: 'Wedding',
      partners: 'Partners',
    },
    dashboard: {
      unavailable: 'No private dashboard is available for this authenticated session',
      supabaseRequired:
        'Supabase must be configured with VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY.',
      supabaseLoadFailed: 'Supabase load failed',
      privateSession: 'Private display session',
      protectedRealtime: 'RLS protected realtime',
      relationshipUptime: 'Relationship Uptime',
      since: 'Since {date}',
      daysUntilWedding: 'Days Until Wedding',
      commitmentLevel: 'Commitment Level',
      noRollback: 'No rollback configured',
      coreMetrics: 'Dashboard',
      personMetrics: 'Person Metrics',
      visible: '{count} visible',
      milestone: '{count} milestone',
      milestones: '{count} milestones',
      editLogin: 'Edit dashboard',
      claimTitle: 'Dashboard unavailable',
      claimDescription: 'Sign in with a linked partner or admin account to view this display.',
    },
    alerts: {
      title: 'Live Alerts',
      active: '{count} active',
      none: 'No active household incidents.',
      systemGenerated: 'System generated',
      triggeredBy: 'Triggered by {name}',
      partnerFallback: 'partner',
    },
    metric: {
      shared: 'Shared',
      reserve: 'Reserve',
      updated: 'Updated {time}',
    },
    qr: {
      scanToEdit: 'Scan to edit live',
    },
    theme: {
      settings: 'Theme settings',
      primary: 'Primary',
      neutral: 'Neutral',
      radius: 'Radius',
      font: 'Font',
    },
    edit: {
      console: '{name} console',
      sharedDashboardEditor: 'Shared dashboard editor',
      sharedDashboard: 'Shared dashboard',
      partnerFallback: 'Partner',
      display: 'Display',
      editableMetrics: 'Editable Metrics',
      editableMetricsDescription: 'Fixed widgets you can edit, hide, or show',
      sharedDashboardDescription:
        'Both partners can create, edit, hide, show, or delete these widgets',
      activeAlerts: 'Active Alerts',
      activeAlertsDescription: 'Visible on display',
      addWidget: 'Add Widget',
      metricKey: 'Metric key',
      metricPlaceholder: 'Blanket Ownership',
      value: 'Value',
      valuePlaceholder: 'Disputed',
      explanation: 'Dashboard explanation',
      explanationPlaceholder: 'Small dashboard explanation',
      scope: 'Scope',
      shared: 'Shared',
      onlyMine: 'Only mine',
      visual: 'Visual',
      visuals: {
        stat: 'Stat',
        progress: 'Progress',
        radial: 'Radial',
        donut: 'Donut',
        bar: 'Bar',
        line: 'Line',
        memory: 'Memory',
      },
      tone: 'Tone',
      tones: {
        info: 'Info',
        success: 'Success',
        warning: 'Warning',
        error: 'Error',
      },
      triggerAlert: 'Trigger Alert',
      customAlert: 'Custom alert',
      customAlertPlaceholder: 'needs a beer 🍺',
      saveCustomAlert: 'Save custom alert',
      alertTemplates: {
        snackShortage: 'Snack shortage detected',
        cuddle: 'Cuddle maintenance overdue',
        dishwasher: 'Dishwasher loaded incorrectly',
        nothing: 'One partner said "nothing" but meant "something"',
        dinnerTimeout: 'Dinner decision timeout',
        blanketDispute: 'Blanket ownership dispute',
        remoteFailover: 'Remote control failover requested',
      },
      editLiveMetrics: 'Edit Live Metrics',
      relationshipTimeline: 'Relationship Timeline',
      staticWidget: 'Static widget',
      timelineTitle: 'Timeline title',
      timelineSummary: 'Timeline summary',
      addMilestone: 'Add milestone',
      newMilestone: 'New milestone',
      milestoneTitle: 'Milestone title',
      milestoneDate: 'Milestone date',
      milestoneDescription: 'Milestone description',
      icon: 'Icon',
      edit: 'Edit',
      delete: 'Delete',
      cancel: 'Cancel',
      hide: 'Hide',
      show: 'Show',
      visible: 'visible',
      hidden: 'hidden',
      save: 'Save',
      numericValue: 'Numeric value',
      chartDesigner: 'Chart builder',
      chartDesignerDescription: 'Create one chart. Both partners can edit it later.',
      createChart: 'Create chart',
      addChartRow: 'Add chart row',
      chartLabel: 'Label',
      chartNewLabel: 'New category',
      chartCentralLabel: 'Center label',
      chartCentralSubLabel: 'Center subtitle',
      alerts: 'Alerts',
      deactivate: 'Deactivate',
      pendingInviteTitle: 'Invite missing partner',
      pendingInviteDescription:
        '{name} has not linked an account yet. Generate a fresh invite link and send it to them.',
      generateInvite: 'Generate invite link',
      copyInvite: 'Copy invite',
      noDashboard: 'No private couple dashboard is available for this account.',
      noPartner: 'Your account is not linked to a partner for this couple.',
      freshDetail: 'Freshly added from the mobile console.',
      raisedFrom: "Raised from {name}'s phone console.",
    },
    invite: {
      required: 'Supabase is required for private partner invites.',
      missingToken: 'This invite link is missing its private token.',
      title: 'Partner Invite',
      description: 'Accepting this invite links your Supabase account to this partner profile.',
      accepted: 'Invite accepted. Opening the private edit console.',
      accept: 'Accept invite',
    },
  },
  de: {
    nav: {
      home: 'Start',
      language: 'Sprache',
    },
    footer: {
      copyright: '© 2026 Marcel Park - Alle Rechte vorbehalten.',
      impressum: 'Impressum',
      privacy: 'Datenschutz',
    },
    consent: {
      title: 'Speichereinstellungen',
      description:
        'Diese App kann Sprache und Theme-Einstellungen auf diesem Gerät speichern. Es werden keine Analyse- oder Werbe-Cookies verwendet.',
      accept: 'Einstellungen speichern',
      reject: 'Nur notwendige Speicherung',
    },
    legal: {
      impressumTitle: 'Impressum',
      provider: 'Anbieter',
      contact: 'Kontakt',
      phone: 'Telefon',
      email: 'E-Mail',
      privacyTitle: 'Datenschutzerklärung',
      privacyIntro:
        'Diese Seite beschreibt, welche Daten bei der Nutzung von CoupleDash verarbeitet werden. Sie ist eine technische Grundlage für einen datenschutzfreundlichen Betrieb und sollte vor einem öffentlichen Launch rechtlich geprüft werden.',
      controllerTitle: 'Verantwortlicher',
      accessDataTitle: 'Zugriffsdaten',
      accessDataText:
        'Beim Hosting der Website kann der Hosting-Anbieter technische Zugriffsdaten wie IP-Adresse, Zeitpunkt, aufgerufene URL, User-Agent und Statuscode verarbeiten, um die Website auszuliefern und abzusichern.',
      authTitle: 'Authentifizierung und Dashboard-Daten',
      authText:
        'Wenn Supabase konfiguriert ist, werden Login-, Einladungs-, Tenant-, Dashboard-, Widget- und Warnungsdaten verarbeitet, um die privaten Dashboard-Funktionen bereitzustellen. Authentifizierungs-Speicherung ist für angemeldete Sitzungen erforderlich.',
      storageTitle: 'Cookies und lokale Speicherung',
      storageText:
        'Die App verwendet keine Analyse- oder Werbe-Cookies. Mit deiner Einwilligung speichert sie Sprache und Theme-Einstellungen im localStorage. Wenn du optionale Speicherung ablehnst, werden diese Einstellungen nicht dauerhaft gespeichert.',
      thirdPartyTitle: 'Drittanbieter',
      thirdPartyText:
        'Die App lädt keine externen Schriftarten. Wenn Supabase konfiguriert ist, dient Supabase als Backend-Dienstleister für Authentifizierung und Datenbankfunktionen.',
      rightsTitle: 'Deine Rechte',
      rightsText:
        'Nach der DSGVO kannst du Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch verlangen, soweit dies gesetzlich anwendbar ist. Außerdem kannst du dich bei einer zuständigen Aufsichtsbehörde beschweren.',
      noLegalAdvice:
        'Dieser Text ist keine Rechtsberatung. Lass die finale öffentliche Version von einem qualifizierten Rechtsanwalt oder Datenschutzexperten prüfen.',
    },
    home: {
      badge: 'Multi-Tenant Dashboards für Paare',
      title: 'CoupleDash',
      description:
        'Private Paar-Dashboards werden erst geladen, wenn ein verknüpftes Partner- oder Admin-Konto angemeldet ist.',
      adminTitle: 'Admin',
      adminDescription: 'Alle Paar-Tenants, Einladungen und Dashboard-Einstellungen verwalten.',
      displayTitle: 'Display',
      displayDescription: 'Öffne dein privates Display mit einem verknüpften Partnerkonto.',
      partnerTitle: 'Partner',
      partnerDescription:
        'Partner nutzen /invite-Links einmalig und danach /edit/:slug mit Supabase Auth.',
      accountTitle: 'Dein Paar-Dashboard',
      accountDescription:
        'Hier erscheinen nur Paar-Dashboards, die mit diesem Konto verknüpft sind.',
      openDisplay: 'Display öffnen',
      editDashboard: 'Dashboard bearbeiten',
      loadingCouples: 'Dein Paar-Dashboard wird geladen...',
      noCouples:
        'Mit diesem Konto ist noch kein Paar-Dashboard verknüpft. Nutze zuerst deinen Einladungslink.',
      noSubtitle: 'Kein Untertitel',
      production: 'Produktion',
      wedding: 'Hochzeit',
      partners: 'Partner',
    },
    dashboard: {
      unavailable: 'Für diese authentifizierte Session ist kein privates Dashboard verfügbar',
      supabaseRequired:
        'Supabase muss mit VITE_SUPABASE_URL und VITE_SUPABASE_PUBLISHABLE_KEY konfiguriert sein.',
      privateSession: 'Private Display-Session',
      protectedRealtime: 'RLS-protected Realtime',
      since: 'Seit {date}',
      daysUntilWedding: 'Days until Wedding',
      commitmentLevel: 'Commitment-Level',
      noRollback: 'Kein Rollback konfiguriert',
      visible: '{count} sichtbar',
      milestone: '{count} Meilenstein',
      milestones: '{count} Meilensteine',
      editLogin: 'Dashboard bearbeiten',
      claimTitle: 'Dashboard nicht verfügbar',
      claimDescription:
        'Melde dich mit einem verknüpften Partner- oder Admin-Konto an, um dieses Display zu sehen.',
    },
    alerts: {
      active: '{count} aktiv',
      none: 'Keine aktiven Household Incidents.',
      triggeredBy: 'Ausgelöst von {name}',
      partnerFallback: 'Partner',
    },
    metric: {
      shared: 'Gemeinsam',
      updated: 'Aktualisiert {time}',
    },
    theme: {
      settings: 'Theme Settings',
      primary: 'Primär',
    },
    edit: {
      console: '{name} Console',
      sharedDashboardEditor: 'Dashboard-Editor',
      sharedDashboard: 'Dashboard',
      editableMetricsDescription:
        'Feste Widgets, die du bearbeiten, ausblenden oder anzeigen kannst',
      sharedDashboardDescription:
        'Beide Partner können diese Widgets erstellen, bearbeiten, ausblenden, anzeigen oder löschen',
      activeAlertsDescription: 'Auf dem Display sichtbar',
      addWidget: 'Widget hinzufügen',
      metricKey: 'Metric Key',
      metricPlaceholder: 'Deckenbesitz',
      value: 'Wert',
      valuePlaceholder: 'Umstritten',
      explanation: 'Dashboard Explanation',
      explanationPlaceholder: 'Kurze Dashboard Explanation',
      shared: 'Gemeinsam',
      onlyMine: 'Nur meine',
      triggerAlert: 'Alert auslösen',
      customAlert: 'Custom Alert',
      customAlertPlaceholder: 'braucht ein Bier 🍺',
      saveCustomAlert: 'Custom Alert speichern',
      alertTemplates: {
        snackShortage: 'Snackmangel erkannt',
        cuddle: 'Kuschelwartung überfällig',
        dishwasher: 'Spülmaschine falsch eingeräumt',
        nothing: 'Ein Partner sagte "nichts", meinte aber "etwas"',
        dinnerTimeout: 'Timeout bei der Essensentscheidung',
        blanketDispute: 'Deckenbesitz umstritten',
        remoteFailover: 'Fernbedienungs-Failover angefordert',
      },
      editLiveMetrics: 'Live Metrics bearbeiten',
      relationshipTimeline: 'Beziehungs-Timeline',
      staticWidget: 'Festes Widget',
      timelineTitle: 'Timeline-Titel',
      timelineSummary: 'Timeline-Zusammenfassung',
      addMilestone: 'Meilenstein hinzufügen',
      newMilestone: 'Neuer Meilenstein',
      milestoneTitle: 'Meilenstein-Titel',
      milestoneDate: 'Meilenstein-Datum',
      milestoneDescription: 'Meilenstein-Beschreibung',
      edit: 'Bearbeiten',
      delete: 'Löschen',
      cancel: 'Abbrechen',
      hide: 'Ausblenden',
      show: 'Anzeigen',
      visible: 'sichtbar',
      hidden: 'ausgeblendet',
      save: 'Speichern',
      numericValue: 'Numeric Value',
      chartDesigner: 'Chart Builder',
      chartDesignerDescription: 'Erstelle einen Chart. Beide Partner können ihn später bearbeiten.',
      createChart: 'Chart erstellen',
      addChartRow: 'Chart-Zeile hinzufügen',
      chartNewLabel: 'Neue Kategorie',
      chartCentralLabel: 'Center Label',
      chartCentralSubLabel: 'Center Subtitle',
      deactivate: 'Deaktivieren',
      pendingInviteTitle: 'Fehlenden Partner einladen',
      pendingInviteDescription:
        '{name} hat noch kein Konto verknüpft. Erstelle einen frischen Einladungslink und sende ihn weiter.',
      generateInvite: 'Einladungslink erstellen',
      copyInvite: 'Einladung kopieren',
      noDashboard: 'Für dieses Konto ist kein privates Paar-Dashboard verfügbar.',
      noPartner: 'Dein Konto ist für dieses Paar nicht mit einem Partner verknüpft.',
      freshDetail: 'Neu aus der Mobile Console hinzugefügt.',
      raisedFrom: 'Ausgelöst von {name}s Phone Console.',
    },
    invite: {
      required: 'Supabase ist für private Partner-Einladungen erforderlich.',
      missingToken: 'In diesem Einladungslink fehlt der private Token.',
      title: 'Partner-Einladung',
      description: 'Diese Einladung verknüpft dein Supabase-Konto mit diesem Partnerprofil.',
      accepted: 'Einladung akzeptiert. Die private Edit Console wird geöffnet.',
      accept: 'Einladung akzeptieren',
    },
  },
} as const

function initialLocale(): LocaleCode {
  if (typeof window === 'undefined') {
    return 'en'
  }

  const saved = canStorePreferences() ? window.localStorage.getItem(storageKey) : null
  if (saved === 'en' || saved === 'de') {
    return saved
  }

  return window.navigator.language.toLowerCase().startsWith('de') ? 'de' : 'en'
}

export const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: initialLocale(),
  fallbackLocale: 'en',
  messages,
})

export function persistLocale(locale: LocaleCode) {
  if (typeof window === 'undefined') {
    return
  }

  if (canStorePreferences()) {
    window.localStorage.setItem(storageKey, locale)
  } else {
    window.localStorage.removeItem(storageKey)
  }
  document.documentElement.lang = locale
}

export function currentLocaleCode(): LocaleCode {
  return i18n.global.locale.value as LocaleCode
}
