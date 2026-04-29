import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined

export interface AdminTenantRow {
  couple_id: string
  slug: string
  name: string
  subtitle: string
  relationship_start: string
  wedding_date: string
  anniversary_date: string
  theme: string
  partner_count: number | string
  accepted_partner_count: number | string
  widget_count: number | string
  active_alert_count: number | string
  created_at: string
}

export interface CreatedTenant {
  couple_id: string
  slug: string
  display_token: string
  partner_a_slug: string
  partner_a_invite_token: string
  partner_b_slug: string
  partner_b_invite_token: string
}

export interface AdminTenantPartner {
  id: string
  slug: string
  name: string
  role: string
  accent: string
  accepted: boolean
}

export interface AdminTenantDetail {
  couple_id: string
  slug: string
  name: string
  subtitle: string
  relationship_start: string
  wedding_date: string
  anniversary_date: string
  theme: string
  partners: AdminTenantPartner[]
}

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseKey)

export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(supabaseUrl!, supabaseKey!, {
      realtime: {
        params: {
          eventsPerSecond: 8,
        },
      },
    })
  : null
