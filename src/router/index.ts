import { createRouter, createWebHistory } from 'vue-router'
import AdminView from '../views/AdminView.vue'
import DashboardView from '../views/DashboardView.vue'
import EditView from '../views/EditView.vue'
import HomeView from '../views/HomeView.vue'
import ImpressumView from '../views/ImpressumView.vue'
import InviteView from '../views/InviteView.vue'
import PrivacyView from '../views/PrivacyView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/display/:coupleSlug',
      name: 'display',
      component: DashboardView,
    },
    {
      path: '/couples/:coupleSlug',
      redirect: (to) => ({ name: 'display', params: { coupleSlug: to.params.coupleSlug } }),
    },
    {
      path: '/edit/:coupleSlug',
      name: 'edit',
      component: EditView,
    },
    {
      path: '/invite/:coupleSlug/:partnerSlug',
      name: 'invite',
      component: InviteView,
    },
    {
      path: '/admin',
      name: 'admin',
      component: AdminView,
    },
    {
      path: '/impressum',
      name: 'impressum',
      component: ImpressumView,
    },
    {
      path: '/datenschutz',
      name: 'privacy',
      component: PrivacyView,
    },
  ],
})

export default router
