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
  partner_count: number | string
  accepted_partner_count: number | string
  widget_count: number | string
  active_alert_count: number | string
  created_at: string
}

export interface CreatedTenant {
  couple_id: string
  slug: string
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
  avatar_path: string | null
  accepted: boolean
}

export interface AdminTenantDetail {
  couple_id: string
  slug: string
  name: string
  subtitle: string
  relationship_start: string
  wedding_date: string
  partners: AdminTenantPartner[]
}

export interface MyCoupleRow {
  couple_id: string
  slug: string
  name: string
  subtitle: string
  relationship_start: string
  wedding_date: string
  partner_count: number | string
  accepted_partner_count: number | string
}

export interface CoupleInviteStatus {
  partner_count: number | string
  accepted_partner_count: number | string
  pending_partner_id: string | null
  pending_partner_name: string | null
}

export interface PendingPartnerInvite {
  couple_slug: string
  partner_slug: string
  partner_name: string
  invite_token: string
}

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseKey)

export const partnerAvatarBucket = 'partner-avatars'
export const partnerAvatarMaxSize = 2 * 1024 * 1024
export const partnerAvatarMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']

export function partnerAvatarExtension(mimeType: string) {
  if (mimeType === 'image/png') {
    return 'png'
  }

  if (mimeType === 'image/webp') {
    return 'webp'
  }

  return 'jpg'
}

export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(supabaseUrl!, supabaseKey!, {
      realtime: {
        params: {
          eventsPerSecond: 8,
        },
      },
    })
  : null
