import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { Profile } from '../lib/supabase'
import { format } from 'date-fns'
import { Search, Crown, User, Copy, Check, Calendar, Globe } from 'lucide-react'

const LANG_LABELS: Record<string, string> = {
  uz: '🇺🇿 Uz',
  uz_CY: '🇺🇿 Кир',
  ru: '🇷🇺 Ru',
  en: '🇬🇧 En',
}

export default function Users() {
  const [users, setUsers] = useState<Profile[]>([])
  const [filtered, setFiltered] = useState<Profile[]>([])
  const [search, setSearch] = useState('')
  const [planFilter, setPlanFilter] = useState<'all' | 'paid' | 'free'>('all')
  const [loading, setLoading] = useState(true)
  const [copiedId, setCopiedId] = useState<string | null>(null)

  const load = () =>
    supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
      .then(({ data }) => {
        setUsers(data ?? [])
        setLoading(false)
      })

  useEffect(() => { load() }, [])

  useEffect(() => {
    const q = search.toLowerCase()
    setFiltered(
      users.filter(u => {
        const matchSearch = u.id.toLowerCase().includes(q) || u.language?.includes(q)
        const matchPlan = planFilter === 'all' || (planFilter === 'paid' ? isPaid(u) : !isPaid(u))
        return matchSearch && matchPlan
      })
    )
  }, [search, users, planFilter])

  const isPaid = (u: Profile) => !!u.plan_expires_at && new Date(u.plan_expires_at) > new Date()

  const extendPlan = async (userId: string, months: number) => {
    const duration = months >= 12 ? 'year' : 'month'
    const { error } = await supabase.rpc('activate_user_plan', { p_user_id: userId, p_duration: duration })
    if (!error) load()
    else alert('Error: ' + error.message)
  }

  const copyId = (id: string) => {
    navigator.clipboard.writeText(id)
    setCopiedId(id)
    setTimeout(() => setCopiedId(null), 1500)
  }

  const paidCount = users.filter(isPaid).length

  if (loading) {
    return (
      <div className="p-8">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-100 rounded-xl w-40" />
          <div className="h-10 bg-gray-100 rounded-xl" />
          <div className="h-64 bg-gray-100 rounded-2xl" />
        </div>
      </div>
    )
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="text-sm text-gray-500 mt-1">
            {users.length} total — {paidCount} paid, {users.length - paidCount} free
          </p>
        </div>
        <div className="flex gap-2">
          {(['all', 'paid', 'free'] as const).map(f => (
            <button
              key={f}
              onClick={() => setPlanFilter(f)}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold capitalize transition-all ${
                planFilter === f
                  ? 'bg-violet-600 text-white shadow-sm shadow-violet-200'
                  : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >{f}</button>
          ))}
        </div>
      </div>

      {/* Search */}
      <div className="relative mb-5">
        <Search size={15} className="absolute left-3.5 top-3 text-gray-400" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search by user ID or language…"
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-violet-400 focus:border-transparent shadow-sm"
        />
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">User</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Plan</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Expires</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Mode</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Language</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Joined</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map(u => (
                <tr key={u.id} className="hover:bg-violet-50/30 transition-colors group">
                  {/* User */}
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 ${isPaid(u) ? 'bg-violet-100 text-violet-700' : 'bg-gray-100 text-gray-500'}`}>
                        <User size={14} />
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5">
                          <span className="font-mono text-xs text-gray-700">{u.id.slice(0, 8)}…</span>
                          <button
                            onClick={() => copyId(u.id)}
                            className="opacity-0 group-hover:opacity-100 transition-opacity text-gray-400 hover:text-gray-700"
                          >
                            {copiedId === u.id ? <Check size={12} className="text-green-500" /> : <Copy size={12} />}
                          </button>
                        </div>
                      </div>
                    </div>
                  </td>
                  {/* Plan */}
                  <td className="px-5 py-4">
                    {isPaid(u) ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-violet-100 text-violet-700">
                        <Crown size={11} /> Paid
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-500">
                        Free
                      </span>
                    )}
                  </td>
                  {/* Expires */}
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-1.5 text-xs text-gray-500">
                      {u.plan_expires_at ? (
                        <>
                          <Calendar size={11} />
                          {format(new Date(u.plan_expires_at), 'MMM d, yyyy')}
                        </>
                      ) : '—'}
                    </div>
                  </td>
                  {/* Mode */}
                  <td className="px-5 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium capitalize ${u.mode === 'pregnancy' ? 'bg-blue-50 text-blue-600' : 'bg-pink-50 text-pink-600'}`}>
                      {u.mode ?? 'cycle'}
                    </span>
                  </td>
                  {/* Language */}
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-1.5 text-xs text-gray-600">
                      <Globe size={11} />
                      {LANG_LABELS[u.language] ?? u.language}
                    </div>
                  </td>
                  {/* Joined */}
                  <td className="px-5 py-4 text-xs text-gray-400">
                    {u.created_at ? format(new Date(u.created_at), 'MMM d, yyyy') : '—'}
                  </td>
                  {/* Actions */}
                  <td className="px-5 py-4">
                    <div className="flex gap-1.5">
                      <button
                        onClick={() => extendPlan(u.id, 1)}
                        className="text-xs px-2.5 py-1 rounded-lg bg-violet-50 text-violet-700 hover:bg-violet-100 font-medium transition-colors border border-violet-100"
                      >+1 mo</button>
                      <button
                        onClick={() => extendPlan(u.id, 12)}
                        className="text-xs px-2.5 py-1 rounded-lg bg-violet-50 text-violet-700 hover:bg-violet-100 font-medium transition-colors border border-violet-100"
                      >+1 yr</button>
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-5 py-16 text-center">
                    <User size={32} className="text-gray-200 mx-auto mb-3" />
                    <p className="text-gray-400 text-sm">No users found</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
