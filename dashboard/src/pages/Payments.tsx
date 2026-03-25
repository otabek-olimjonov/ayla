import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { PaymentRequest } from '../lib/supabase'
import { format } from 'date-fns'
import { CheckCircle, XCircle, Clock } from 'lucide-react'

export default function Payments() {
  const [requests, setRequests] = useState<PaymentRequest[]>([])
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('pending')
  const [loading, setLoading] = useState(true)
  const [acting, setActing] = useState<string | null>(null)

  const load = async () => {
    const q = supabase.from('payment_requests').select('*').order('created_at', { ascending: false })
    const { data } = filter === 'all' ? await q : await q.eq('status', filter)
    setRequests(data ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [filter])

  const approve = async (req: PaymentRequest, months: number) => {
    setActing(req.id)
    // Extend the user's plan
    const duration = months >= 12 ? 'year' : 'month'
    const { error: planErr } = await supabase.rpc('activate_user_plan', {
      p_user_id: req.user_id,
      p_duration: duration,
    })
    if (planErr) { alert('Plan error: ' + planErr.message); setActing(null); return }

    // Mark payment as approved
    await supabase.from('payment_requests').update({ status: 'approved' }).eq('id', req.id)
    setActing(null)
    load()
  }

  const reject = async (id: string) => {
    setActing(id)
    await supabase.from('payment_requests').update({ status: 'rejected' }).eq('id', id)
    setActing(null)
    load()
  }

  const statusBadge = (status: string) => {
    if (status === 'approved') return <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700"><CheckCircle size={11} /> Approved</span>
    if (status === 'rejected') return <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700"><XCircle size={11} /> Rejected</span>
    return <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700"><Clock size={11} /> Pending</span>
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Payments</h1>
        <div className="flex gap-2">
          {(['all', 'pending', 'approved', 'rejected'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition-colors ${
                filter === f
                  ? 'bg-violet-600 text-white'
                  : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >{f}</button>
          ))}
        </div>
      </div>
      {loading ? <div className="text-gray-500">Loading…</div> : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Email</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">User ID</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Status</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Submitted</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {requests.map(req => (
                <tr key={req.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-900">{req.email}</td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-500">{req.user_id.slice(0, 8)}…</td>
                  <td className="px-4 py-3">{statusBadge(req.status)}</td>
                  <td className="px-4 py-3 text-gray-600">
                    {format(new Date(req.created_at), 'MMM d, yyyy HH:mm')}
                  </td>
                  <td className="px-4 py-3">
                    {req.status === 'pending' && (
                      <div className="flex gap-2">
                        <button
                          disabled={acting === req.id}
                          onClick={() => approve(req, 1)}
                          className="text-xs px-3 py-1 rounded-md bg-green-50 text-green-700 hover:bg-green-100 font-medium transition-colors disabled:opacity-50"
                        >✓ 1 Month</button>
                        <button
                          disabled={acting === req.id}
                          onClick={() => approve(req, 12)}
                          className="text-xs px-3 py-1 rounded-md bg-green-50 text-green-700 hover:bg-green-100 font-medium transition-colors disabled:opacity-50"
                        >✓ 1 Year</button>
                        <button
                          disabled={acting === req.id}
                          onClick={() => reject(req.id)}
                          className="text-xs px-3 py-1 rounded-md bg-red-50 text-red-700 hover:bg-red-100 font-medium transition-colors disabled:opacity-50"
                        >✗ Reject</button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
              {requests.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-8 text-center text-gray-400">No {filter} payment requests</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
