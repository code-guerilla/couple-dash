import './assets/main.css'

import { createApp } from 'vue'
import ui from '@nuxt/ui/vue-plugin'
import App from './App.vue'
import { currentLocaleCode, i18n, persistLocale } from './i18n'
import router from './router'

const app = createApp(App)
app.use(router)
app.use(ui)
app.use(i18n)

persistLocale(currentLocaleCode())

app.mount('#app')
