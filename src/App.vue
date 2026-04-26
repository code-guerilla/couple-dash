<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="min-h-screen bg-base-200">
    <div class="navbar border-b border-base-300 bg-base-100 px-4 shadow-sm sm:px-6">
      <div class="navbar-start">
        <RouterLink class="btn btn-ghost text-xl" to="/">Couple Dash</RouterLink>
      </div>

      <div class="navbar-end">
        <RouterLink class="btn btn-primary btn-sm" to="/">Dashboard</RouterLink>
      </div>
    </div>

    <main class="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:py-10">
      <RouterView />
    </main>
  </div>
</template>
