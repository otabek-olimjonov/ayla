import { useEffect, useState } from 'react'
import { Users, CreditCard, BookOpen, MessageSquare, TrendingUp, Crown } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { format, subDays } from 'date-fns'

type Stats = {
  totalUsers: number
  paidUsers: number
  pendingPayments: number
  totalArticles: number
  totalPosts: number
}

type DailySignup = { date: string; count: number }

const STAT_CARDS = [
  {
    key: 'totalUsers' as keyof Stats,
    label: 'Total Users',
    icon: Users,
    gradient: 'from-violet-500 to-purple-600',
    bg: 'bg-violet-50',
    text: 'text-violet-600',
    sub: 'Registered accounts',
  },
  {
    key: 'paidUsers' as keyof Stats,
    label: 'Paid Users',
    icon: Crown,
    gradient: 'from-emerald-400 to-green-600',
    bg: 'bg-emerald-50',
    text: 'text-emerald-600',
    sub: 'Active subscriptions',
  },
  {
    key: 'pendingPayments' as keyof Stats,
    label: 'Pending Payments',
    icon: CreditCard,
    gradient: 'from-amber-400 to-orange-500',
    bg: 'bg-amber-50',
    text: 'text-amber-600',
    sub: 'Awaiting approval',
  },
  {
    key: 'totalArticles' as keyof Stats,
    label: 'Articles',
    icon: BookOpen,
    gradient: 'from-blue-400 to-indigo-600',
    bg: 'bg-blue-50',
    text: 'text-blue-600',
    sub: 'Published content',
  },
  {
    key: 'totalPosts' as keyof Stats,
    label: 'Community Posts',
    icon: MessageSquare,
    gradient: 'from-pink-400 to-rose-500',
    bg: 'bg-pink-50',
    text: 'text-pink-600',
    sub: 'Forum discussions',
  },
]

function CustomTooltip({ active, payload, label }: { active?: boolean; payload?: Array<{ value: number }>; label?: string }) {
  if (active && payload?.length) {
    return (
      <div className="bg-white border border-gray-100 shadow-lg rounded-xl px-4 py-3 text-sm">
        <p className="text-gray-500 mb-0.5">{label}</p>
        <p className="font-semibold text-violet-700">{payload[0].value} signups</p>
      </div>
    )
  }
  return null
}

export default function Overview() {
  const [stats, setStats] = useState<Stats>({ totalUsers: 0, paidUsers: 0, pendingPayments: 0, totalArticles: 0, totalPosts: 0 })
  const [signups, setSignups] = useState<DailySignup[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      const [profiles, payments, articles, posts] = await Promise.all([
        supabase.from('profiles').select('id, plan_expires_at, created_at'),
        supabase.from('payment_requests').select('id, status').eq('status', 'pending'),
        supabase.from('articles').select('id', { count: 'exact', head: true }),
        supabase.from('community_posts').select('id', { count: 'exact', head: true }),
      ])

      const allProfiles = profiles.data ?? []
      const now = new Date()
      const paid = allProfiles.filter(p => p.plan_expires_at && new Date(p.plan_expires_at) > now)

      setStats({
        totalUsers: allProfiles.length,
        paidUsers: paid.length,
        pendingPayments: payments.data?.length ?? 0,
        totalArticles: articles.count ?? 0,
        totalPosts: posts.count ?? 0,
      })

      const days: DailySignup[] = []
      for (let i = 13; i >= 0; i--) {
        const d = subDays(now, i)
        const dateStr = format(d, 'yyyy-MM-dd')
        const count = allProfiles.filter(p => p.created_at?.startsWith(dateStr)).length
        days.push({ date: format(d, 'MMM d'), count })
      }
      setSignups(days)
      setLoading(false)
    }
    load()
  }, [])

  const conversionRate = stats.totalUsers > 0
    ? ((stats.paidUsers / stats.totalUsers) * 100).toFixed(1)
    : '0.0'

  if (loading) {
    return (
      <div className="p-8">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-100 rounded-xl w-48" />
          <div className="grid grid-cols-3 gap-4">
            {[1,2,3,4,5].map(i => <div key={i} className="h-28 bg-gray-100 rounded-2xl" />)}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Overview</h1>
        <p className="text-sm text-gray-500 mt-1">Welcome back. Here's what's happening with Ayla.</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4 mb-8">
        {STAT_CARDS.map(({ key, label, icon: Icon, gradient, bg, text, sub }) => (
          <div key={key} className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5 hover:shadow-md transition-shadow">
            <div className="flex items-start justify-between mb-4">
              <div className={`rounded-xl p-2.5 ${bg}`}>
                <Icon size={18} className={text} />
              </div>
              <div className={`text-xs font-semibold px-2 py-0.5 rounded-full bg-gradient-to-r ${gradient} text-white opacity-80`}>
                {key === 'paidUsers' ? `${conversionRate}%` : '↑'}
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">{stats[key].toLocaleString()}</p>
            <p className="text-xs font-medium text-gray-700 mt-0.5">{label}</p>
            <p className="text-xs text-gray-400 mt-0.5">{sub}</p>
          </div>
        ))}
      </div>

      {/* Chart + Conversion card */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Signups chart */}
        <div className="xl:col-span-2 bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-base font-semibold text-gray-900">New Signups</h2>
              <p className="text-xs text-gray-400 mt-0.5">Last 14 days</p>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-violet-600 font-medium bg-violet-50 px-3 py-1.5 rounded-lg">
              <TrendingUp size={13} />
              Daily trend
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={signups} barCategoryGap="35%">
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
              <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: '#f5f3ff' }} />
              <Bar dataKey="count" fill="url(#barGradient)" radius={[6, 6, 0, 0]} />
              <defs>
                <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#7c3aed" />
                  <stop offset="100%" stopColor="#a78bfa" />
                </linearGradient>
              </defs>
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Conversion + quick stats */}
        <div className="space-y-4">
          <div className="bg-gradient-to-br from-violet-500 to-purple-700 rounded-2xl p-6 text-white shadow-md shadow-violet-200">
            <p className="text-violet-200 text-sm font-medium">Conversion Rate</p>
            <p className="text-5xl font-bold mt-2">{conversionRate}%</p>
            <p className="text-violet-200 text-xs mt-2">
              {stats.paidUsers} of {stats.totalUsers} users are on paid plans
            </p>
            <div className="mt-4 bg-white/20 rounded-full h-2">
              <div
                className="bg-white rounded-full h-2 transition-all"
                style={{ width: `${Math.min(parseFloat(conversionRate), 100)}%` }}
              />
            </div>
          </div>

          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">Quick Stats</p>
            <div className="space-y-3">
              {[
                { label: 'Free users', value: stats.totalUsers - stats.paidUsers, color: 'bg-gray-200' },
                { label: 'Pending approvals', value: stats.pendingPayments, color: 'bg-amber-400' },
                { label: 'Avg articles', value: stats.totalArticles, color: 'bg-blue-400' },
              ].map(item => (
                <div key={item.label} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className={`w-2 h-2 rounded-full ${item.color}`} />
                    <span className="text-sm text-gray-600">{item.label}</span>
                  </div>
                  <span className="text-sm font-semibold text-gray-900">{item.value.toLocaleString()}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
