import { useEffect, useState } from 'react'
import { Users, CreditCard, BookOpen } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { format, subDays } from 'date-fns'

type Stats = {
  totalUsers: number
  paidUsers: number
  pendingPayments: number
  totalArticles: number
  totalPosts: number
}

type DailySignup = { date: string; count: number }

function StatCard({ icon: Icon, label, value, color }: { icon: React.ElementType, label: string, value: number, color: string }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 flex items-center gap-4">
      <div className={`rounded-lg p-3 ${color}`}>
        <Icon size={22} className="text-white" />
      </div>
      <div>
        <p className="text-sm text-gray-500">{label}</p>
        <p className="text-2xl font-bold text-gray-900">{value.toLocaleString()}</p>
      </div>
    </div>
  )
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

      // Build last 14 days signups chart
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

  if (loading) return <div className="p-8 text-gray-500">Loading…</div>

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Overview</h1>
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
        <StatCard icon={Users} label="Total Users" value={stats.totalUsers} color="bg-violet-500" />
        <StatCard icon={CreditCard} label="Paid Users" value={stats.paidUsers} color="bg-green-500" />
        <StatCard icon={CreditCard} label="Pending Payments" value={stats.pendingPayments} color="bg-amber-500" />
        <StatCard icon={BookOpen} label="Articles" value={stats.totalArticles} color="bg-blue-500" />
      </div>
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h2 className="text-base font-semibold text-gray-900 mb-4">New Signups — Last 14 Days</h2>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={signups}>
            <XAxis dataKey="date" tick={{ fontSize: 12 }} />
            <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
            <Tooltip />
            <Bar dataKey="count" fill="#7c6fab" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
      <div className="mt-4 bg-white rounded-xl border border-gray-200 p-6">
        <h2 className="text-base font-semibold text-gray-900 mb-2">Community Posts</h2>
        <p className="text-3xl font-bold text-gray-900">{stats.totalPosts.toLocaleString()}</p>
        <p className="text-sm text-gray-500 mt-1">Total posts across all categories</p>
      </div>
    </div>
  )
}
