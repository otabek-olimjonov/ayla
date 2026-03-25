import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in .env')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export type Profile = {
  id: string
  created_at: string
  birth_year: number | null
  cycle_length: number
  period_length: number
  language: string
  plan_expires_at: string | null
  mode: string
  partner_code: string | null
}

export type PaymentRequest = {
  id: string
  user_id: string
  email: string
  status: 'pending' | 'approved' | 'rejected'
  created_at: string
  plan_expires_at?: string | null
}

export type Article = {
  id: string
  title_uz: string
  title_ru: string | null
  body_uz: string
  body_ru: string | null
  category: string
  is_paid: boolean
  published_at: string
  cover_url: string | null
}

export type CommunityPost = {
  id: string
  user_id: string
  body: string
  category: string
  is_anonymous: boolean
  likes_count: number
  created_at: string
}
