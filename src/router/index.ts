import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
    },
    {
      path: '/display/:coupleSlug',
      name: 'display',
      component: () => import('../views/DashboardView.vue'),
    },
    {
      path: '/couples/:coupleSlug',
      redirect: (to) => ({ name: 'display', params: { coupleSlug: to.params.coupleSlug } }),
    },
    {
      path: '/edit/:coupleSlug',
      name: 'edit',
      component: () => import('../views/EditView.vue'),
    },
    {
      path: '/invite/:coupleSlug/:partnerSlug',
      name: 'invite',
      component: () => import('../views/InviteView.vue'),
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('../views/AdminView.vue'),
    },
    {
      path: '/admin/new',
      name: 'admin-new',
      component: () => import('../views/AdminTenantNewView.vue'),
    },
    {
      path: '/admin/tenants/:tenantId',
      name: 'admin-tenant',
      component: () => import('../views/AdminTenantManageView.vue'),
    },
    {
      path: '/impressum',
      name: 'impressum',
      component: () => import('../views/ImpressumView.vue'),
    },
    {
      path: '/datenschutz',
      name: 'privacy',
      component: () => import('../views/PrivacyView.vue'),
    },
  ],
})

export default router
