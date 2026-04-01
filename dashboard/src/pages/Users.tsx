import { useEffect, useState, useMemo } from 'react'
import { supabase } from '../lib/supabase'
import type { Profile } from '../lib/supabase'
import { format } from 'date-fns'
import { Search, Crown, User, Copy, Check, Calendar, Globe, Mail, AlertCircle, X } from 'lucide-react'

const LANG_LABELS: Record<string, string> = {
  uz: 'Uz',
  uz_CY: 'Uz Cyr',
  ru: 'Ru',
  en: 'En',
}

type UserRow = Profile & { resolvedEmail: string | null }

export default function Users() {
  const [users, setUsers] = useState<UserRow[]>([])
  const [search, setSearch] = useState('')
  const [planFilter, setPlanFilter] = useState<'all' | 'paid' | 'free'>('all')
  const [loading, setLoading] = useState(true)
  const [copiedId, setCopiedId] = useState<string | null>(null)
  const [emailSource, setEmailSource] = useState<'admin' | 'payment_requests' | 'profile_column' | 'none'>('none')

  const load = async () => {
    setLoading(true)
    const { data: profiles } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
    const profileList: Profile[] = profiles ?? []

    // Tier 1: admin-users edge function (uses built-in service role key, no config needed)
    try {
      const { data: edgeData, error: edgeError } = await supabase.functions.invoke('admin-users')
      if (!edgeError && edgeData?.users) {
        const emailMap: Record<string, string> = {}
        ;(edgeData.users as { id: string; email: string | null }[]).forEach(u => {
          if (u.email) emailMap[u.id] = u.email
        })
        setUsers(profileList.map(p => ({ ...p, resolvedEmail: emailMap[p.id] ?? null })))
        setEmailSource('admin')
        setLoading(false)
        return
      }
    } catch { /* fall through to lower tiers */ }

    // Tier 2: profiles.email column (if DB migration was run)
    const firstProfile = profileList[0] as unknown as Record<string, unknown>
    if (profileList.length > 0 && firstProfile['email'] != null) {
      setUsers(profileList.map(p => ({
        ...p,
        resolvedEmail: ((p as unknown as Record<string, unknown>)['email'] as string) ?? null,
      })))
      setEmailSource('profile_column')
      setLoading(false)
      return
    }

    // Tier 3: payment_requests cross-reference
    const { data: payments } = await supabase
      .from('payment_requests')
      .select('user_id, email')
      .order('created_at', { ascending: false })
    const emailMap: Record<string, string> = {}
    ;(payments ?? []).forEach((p: { user_id: string; email: string }) => {
      if (p.email && !emailMap[p.user_id]) emailMap[p.user_id] = p.email
    })
    setUsers(profileList.map(p => ({ ...p, resolvedEmail: emailMap[p.id] ?? null })))
    setEmailSource(Object.keys(emailMap).length > 0 ? 'payment_requests' : 'none')
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  const isPaid = (u: UserRow) => !!u.plan_expires_at && new Date(u.plan_expires_at) > new Date()

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return users.filter(u => {
      const matchSearch = !q || [u.id, u.resolvedEmail ?? '', u.language ?? '', u.mode ?? '', u.partner_code ?? ''].some(f => f.toLowerCase().includes(q))
      const matchPlan = planFilter === 'all' || (planFilter === 'paid' ? isPaid(u) : !isPaid(u))
      return matchSearch && matchPlan
    })
  }, [search, users, planFilter])

  const paidCount = users.filter(isPaid).length

  const extendPlan = async (userId: string, months: number) => {
    const duration = months >= 12 ? 'year' : 'month'
    const { error } = await supabase.rpc('activate_user_plan', { p_user_id: userId, p_duration: duration })
    if (!error) load()
    else alert('Error: ' + error.message)
  }

  const copyText = (text: string, key: string) => {
    navigator.clipboard.writeText(text)
    setCopiedId(key)
    setTimeout(() => setCopiedId(null), 1500)
  }

  const highlight = (text: string, q: string): React.ReactNode => {
    if (!q) return <>{text}</>
    const idx = text.toLowerCase().indexOf(q.toLowerCase())
    if (idx === -1) return <>{text}</>
    return (
      <>
        {text.slice(0, idx)}
        <mark className="bg-violet-100 text-violet-800 rounded px-0.5 not-italic font-medium">
          {text.slice(idx, idx + q.length)}
        </mark>
        {text.slice(idx + q.length)}
      </>
    )
  }

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
      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="text-sm text-gray-500 mt-1">
            {users.length} total &middot; {paidCount} paid &middot; {users.length - paidCount} free
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
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {emailSource === 'none' && (
        <div className="flex items-start gap-3 bg-amber-50 border border-amber-200 rounded-2xl p-4 mb-5">
          <AlertCircle size={16} className="text-amber-500 mt-0.5 shrink-0" />
          <div className="text-sm">
            <p className="font-semibold text-amber-800">Email search unavailable</p>
            <p className="text-amber-700 text-xs mt-0.5">
              Deploy the edge function to enable it:{` `}
              <code className="bg-amber-100 px-1 rounded font-mono">supabase functions deploy admin-users</code>
            </p>
          </div>
        </div>
      )}
      {emailSource === 'payment_requests' && (
        <div className="flex items-start gap-3 bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-5">
          <AlertCircle size={16} className="text-blue-500 mt-0.5 shrink-0" />
          <div className="text-sm">
            <p className="font-semibold text-blue-800">Partial email coverage (via payment requests)</p>
            <p className="text-blue-700 text-xs mt-0.5">
              For full email search, deploy the edge function:{` `}
              <code className="bg-blue-100 px-1 rounded font-mono">supabase functions deploy admin-users</code>
            </p>
          </div>
        </div>
      )}

      <div className="relative mb-2">
        <Search size={15} className="absolute left-3.5 top-3 text-gray-400 pointer-events-none" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search by email, user ID, language, mode, partner code..."
          className="w-full pl-10 pr-10 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-violet-400 focus:border-transparent shadow-sm"
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600">
            <X size={16} />
          </button>
        )}
      </div>
      {search ? (
        <p className="text-xs text-gray-400 mb-4 ml-1">
          {filtered.length} result{filtered.length !== 1 ? 's' : ''} for &ldquo;{search}&rdquo;
        </p>
      ) : (
        <div className="mb-4" />
      )}

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                {['User ID', 'Email', 'Plan', 'Expires', 'Mode', 'Lang', 'Joined', 'Actions'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide whitespace-nowrap">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map(u => {
                const q = search.trim().toLowerCase()
                return (
                  <tr key={u.id} className="hover:bg-violet-50/30 transition-colors group">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${isPaid(u) ? 'bg-violet-100 text-violet-600' : 'bg-gray-100 text-gray-400'}`}>
                          <User size={14} />
                        </div>
                        <div className="flex items-center gap-1.5">
                          <span className="font-mono text-xs text-gray-600">{u.id.slice(0, 8)}&hellip;</span>
                          <button onClick={() => copyText(u.id, u.id)} title="Copy full ID"
                            className="opacity-0 group-hover:opacity-100 transition-opacity text-gray-400 hover:text-gray-700">
                            {copiedId === u.id ? <Check size={12} className="text-green-500" /> : <Copy size={12} />}
                          </button>
                        </div>
                      </div>
                    </td>

                    <td className="px-5 py-4 max-w-[220px]">
                      {u.resolvedEmail ? (
                        <div className="flex items-center gap-1.5 min-w-0">
                          <Mail size={11} className="text-gray-400 shrink-0" />
                          <span className="text-xs text-gray-700 truncate" title={u.resolvedEmail}>
                            {highlight(u.resolvedEmail, q)}
                          </span>
                          <button onClick={() => copyText(u.resolvedEmail!, u.id + '-email')} title="Copy email"
                            className="opacity-0 group-hover:opacity-100 transition-opacity text-gray-400 hover:text-gray-700 shrink-0">
                            {copiedId === u.id + '-email' ? <Check size={11} className="text-green-500" /> : <Copy size={11} />}
                          </button>
                        </div>
                      ) : (
                        <span className="text-xs text-gray-300 italic">unknown</span>
                      )}
                    </td>

                    <td className="px-5 py-4">
                      {isPaid(u) ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-violet-100 text-violet-700 whitespace-nowrap">
                          <Crown size={11} /> Paid
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-500">
                          Free
                        </span>
                      )}
                    </td>

                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1.5 text-xs text-gray-500 whitespace-nowrap">
                        {u.plan_expires_at ? (
                          <><Calendar size={11} />{format(new Date(u.plan_expires_at), 'MMM d, yyyy')}</>
                        ) : '—'}
                      </div>
                    </td>

                    <td className="px-5 py-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium capitalize whitespace-nowrap ${u.mode === 'pregnancy' ? 'bg-blue-50 text-blue-600' : 'bg-pink-50 text-pink-600'}`}>
                        {u.mode ?? 'cycle'}
                      </span>
                    </td>

                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1 text-xs text-gray-600 whitespace-nowrap">
                        <Globe size={11} />{LANG_LABELS[u.language] ?? u.language}
                      </div>
                    </td>

                    <td className="px-5 py-4 text-xs text-gray-400 whitespace-nowrap">
                      {u.created_at ? format(new Date(u.created_at), 'MMM d, yyyy') : '—'}
                    </td>

                    <td className="px-5 py-4">
                      <div className="flex gap-1.5">
                        <button onClick={() => extendPlan(u.id, 1)}
                          className="text-xs px-2.5 py-1 rounded-lg bg-violet-50 text-violet-700 hover:bg-violet-100 font-medium transition-colors border border-violet-100 whitespace-nowrap">
                          +1 mo
                        </button>
                        <button onClick={() => extendPlan(u.id, 12)}
                          className="text-xs px-2.5 py-1 rounded-lg bg-violet-50 text-violet-700 hover:bg-violet-100 font-medium transition-colors border border-violet-100 whitespace-nowrap">
                          +1 yr
                        </button>
                      </div>
                    </td>
                  </tr>
                )
              })}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={8} className="px-5 py-16 text-center">
                    <Search size={32} className="text-gray-200 mx-auto mb-3" />
                    <p className="text-gray-400 text-sm">No users match &ldquo;{search}&rdquo;</p>
                    <button onClick={() => setSearch('')} className="mt-2 text-xs text-violet-500 hover:underline">
                      Clear search
                    </button>
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
