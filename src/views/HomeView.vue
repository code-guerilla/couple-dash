<template>
  <section class="space-y-6">
    <div class="hero rounded-box bg-base-100 shadow-sm">
      <div class="hero-content w-full justify-start p-8">
        <div class="max-w-2xl">
          <p class="badge badge-primary badge-soft mb-4">Fresh start</p>
          <h1 class="text-4xl font-bold tracking-tight">Build your shared dashboard here</h1>
          <p class="mt-4 text-base-content/70">
            The Vue starter template is gone. This page is ready for your couple dashboard features,
            using Tailwind CSS and DaisyUI components from the start.
          </p>
          <div class="mt-6 flex flex-wrap gap-3">
            <button class="btn btn-primary">Add first widget</button>
            <button class="btn btn-outline">Plan layout</button>
          </div>
        </div>
      </div>
    </div>

    <div class="grid gap-4 md:grid-cols-3">
      <article class="card bg-base-100 shadow-sm">
        <div class="card-body">
          <h2 class="card-title">Shared Tasks</h2>
          <p class="text-base-content/70">Track recurring chores, errands, and household todos.</p>
        </div>
      </article>

      <article class="card bg-base-100 shadow-sm">
        <div class="card-body">
          <h2 class="card-title">Calendar</h2>
          <p class="text-base-content/70">Keep upcoming dates and plans visible in one place.</p>
        </div>
      </article>

      <article class="card bg-base-100 shadow-sm">
        <div class="card-body">
          <h2 class="card-title">Budget</h2>
          <p class="text-base-content/70">
            Add shared expenses, savings goals, or monthly summaries.
          </p>
        </div>
      </article>
    </div>
  </section>
</template>
