import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { PaymentRequest } from '../lib/supabase'
import { format } from 'date-fns'
import { CheckCircle, XCircle, Clock, Mail, CreditCard, Inbox } from 'lucide-react'

export default function Payments() {
  const [requests, setRequests] = useState<PaymentRequest[]>([])
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('pending')
  const [loading, setLoading] = useState(true)
  const [acting, setActing] = useState<string | null>(null)

  const load = async () => {
    setLoading(true)
    const q = supabase.from('payment_requests').select('*').order('created_at', { ascending: false })
    const { data } = filter === 'all' ? await q : await q.eq('status', filter)
    setRequests(data ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [filter])

  const approve = async (req: PaymentRequest, months: number) => {
    setActing(req.id)
    const duration = months >= 12 ? 'year' : 'month'
    const { error: planErr } = await supabase.rpc('activate_user_plan', {
      p_user_id: req.user_id,
      p_duration: duration,
    })
    if (planErr) { alert('Plan error: ' + planErr.message); setActing(null); return }
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

  const pending = requests.filter(r => r.status === 'pending').length

  return (
    <div className="p-8 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Payments</h1>
          <p className="text-sm text-gray-500 mt-1">Review and approve user payment requests</p>
        </div>
        {pending > 0 && (
          <div className="flex items-center gap-2 bg-amber-50 border border-amber-200 text-amber-700 px-3 py-2 rounded-xl text-sm font-medium">
            <Clock size={15} />
            {pending} pending {pending === 1 ? 'request' : 'requests'}
          </div>
        )}
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2 mb-6 bg-gray-100/70 rounded-xl p-1 w-fit">
        {(['pending', 'approved', 'rejected', 'all'] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all ${
              filter === f
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >{f}</button>
        ))}
      </div>

      {loading ? (
        <div className="space-y-3">
          {[1,2,3].map(i => <div key={i} className="h-24 bg-gray-100 rounded-2xl animate-pulse" />)}
        </div>
      ) : requests.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 p-16 text-center shadow-sm">
          <Inbox size={40} className="text-gray-200 mx-auto mb-3" />
          <p className="text-gray-400">No {filter} payment requests</p>
        </div>
      ) : (
        <div className="space-y-3">
          {requests.map(req => (
            <div
              key={req.id}
              className={`bg-white rounded-2xl border shadow-sm p-5 transition-colors ${
                req.status === 'pending' ? 'border-amber-100' :
                req.status === 'approved' ? 'border-green-100' : 'border-gray-100'
              }`}
            >
              <div className="flex items-center justify-between gap-4 flex-wrap">
                {/* Left: user info */}
                <div className="flex items-center gap-4 min-w-0">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                    req.status === 'pending' ? 'bg-amber-50' :
                    req.status === 'approved' ? 'bg-green-50' : 'bg-gray-50'
                  }`}>
                    <CreditCard size={18} className={
                      req.status === 'pending' ? 'text-amber-500' :
                      req.status === 'approved' ? 'text-green-500' : 'text-gray-400'
                    } />
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <Mail size={12} className="text-gray-400 shrink-0" />
                      <p className="text-sm font-semibold text-gray-900 truncate">{req.email}</p>
                    </div>
                    <p className="text-xs text-gray-400 font-mono">
                      {req.user_id.slice(0, 16)}… · {format(new Date(req.created_at), 'MMM d, yyyy HH:mm')}
                    </p>
                  </div>
                </div>

                {/* Right: status + actions */}
                <div className="flex items-center gap-3 shrink-0">
                  {req.status === 'approved' && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold bg-green-50 text-green-700 border border-green-100">
                      <CheckCircle size={13} /> Approved
                    </span>
                  )}
                  {req.status === 'rejected' && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold bg-red-50 text-red-600 border border-red-100">
                      <XCircle size={13} /> Rejected
                    </span>
                  )}
                  {req.status === 'pending' && (
                    <div className="flex items-center gap-2">
                      <button
                        disabled={acting === req.id}
                        onClick={() => approve(req, 1)}
                        className="flex items-center gap-1.5 text-xs px-3 py-2 rounded-xl bg-green-600 text-white hover:bg-green-700 font-semibold transition-colors disabled:opacity-50 shadow-sm shadow-green-200"
                      >
                        <CheckCircle size={13} /> 1 Month
                      </button>
                      <button
                        disabled={acting === req.id}
                        onClick={() => approve(req, 12)}
                        className="flex items-center gap-1.5 text-xs px-3 py-2 rounded-xl bg-violet-600 text-white hover:bg-violet-700 font-semibold transition-colors disabled:opacity-50 shadow-sm shadow-violet-200"
                      >
                        <CheckCircle size={13} /> 1 Year
                      </button>
                      <button
                        disabled={acting === req.id}
                        onClick={() => reject(req.id)}
                        className="flex items-center gap-1.5 text-xs px-3 py-2 rounded-xl bg-white border border-gray-200 text-gray-600 hover:bg-red-50 hover:text-red-600 hover:border-red-100 font-semibold transition-colors disabled:opacity-50"
                      >
                        <XCircle size={13} /> Reject
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
