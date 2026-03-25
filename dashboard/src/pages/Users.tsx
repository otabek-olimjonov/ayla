import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { Profile } from '../lib/supabase'
import { format } from 'date-fns'
import { Search, BadgeCheck, Clock } from 'lucide-react'

export default function Users() {
  const [users, setUsers] = useState<Profile[]>([])
  const [filtered, setFiltered] = useState<Profile[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
      .then(({ data }) => {
        setUsers(data ?? [])
        setFiltered(data ?? [])
        setLoading(false)
      })
  }, [])

  useEffect(() => {
    const q = search.toLowerCase()
    setFiltered(users.filter(u => u.id.toLowerCase().includes(q) || u.language.includes(q)))
  }, [search, users])

  const isPaid = (u: Profile) => !!u.plan_expires_at && new Date(u.plan_expires_at) > new Date()

  const extendPlan = async (userId: string, months: number) => {
    const duration = months >= 12 ? 'year' : 'month'
    const { error } = await supabase.rpc('activate_user_plan', { p_user_id: userId, p_duration: duration })
    if (!error) {
      const { data } = await supabase.from('profiles').select('*').order('created_at', { ascending: false })
      setUsers(data ?? [])
    } else {
      alert('Error: ' + error.message)
    }
  }

  if (loading) return <div className="p-8 text-gray-500">Loading…</div>

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Users</h1>
        <span className="text-sm text-gray-500">{users.length} total</span>
      </div>
      <div className="relative mb-4">
        <Search size={16} className="absolute left-3 top-2.5 text-gray-400" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search by user ID or language…"
          className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-violet-400"
        />
      </div>
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-4 py-3 text-left font-medium text-gray-600">User ID</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Plan</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Expires</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Mode</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Lang</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Joined</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map(u => (
              <tr key={u.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-mono text-xs text-gray-600">{u.id.slice(0, 8)}…</td>
                <td className="px-4 py-3">
                  {isPaid(u) ? (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">
                      <BadgeCheck size={12} /> Paid
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
                      <Clock size={12} /> Free
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {u.plan_expires_at ? format(new Date(u.plan_expires_at), 'MMM d, yyyy') : '—'}
                </td>
                <td className="px-4 py-3 text-gray-600 capitalize">{u.mode}</td>
                <td className="px-4 py-3 text-gray-600">{u.language}</td>
                <td className="px-4 py-3 text-gray-600">
                  {u.created_at ? format(new Date(u.created_at), 'MMM d, yyyy') : '—'}
                </td>
                <td className="px-4 py-3">
                  <div className="flex gap-2">
                    <button
                      onClick={() => extendPlan(u.id, 1)}
                      className="text-xs px-2 py-1 rounded-md bg-violet-50 text-violet-700 hover:bg-violet-100 transition-colors"
                    >+1 mo</button>
                    <button
                      onClick={() => extendPlan(u.id, 12)}
                      className="text-xs px-2 py-1 rounded-md bg-violet-50 text-violet-700 hover:bg-violet-100 transition-colors"
                    >+1 yr</button>
                  </div>
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-400">No users found</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
