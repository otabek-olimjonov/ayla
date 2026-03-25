import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { Article } from '../lib/supabase'
import { format } from 'date-fns'
import { Plus, Lock, Unlock, Trash2 } from 'lucide-react'

const CATEGORIES = ['cycle', 'pregnancy', 'nutrition', 'mental_health']

type Draft = Omit<Article, 'id' | 'published_at'>

const emptyDraft = (): Draft => ({
  title_uz: '', title_ru: '', body_uz: '', body_ru: '',
  category: 'cycle', is_paid: false, cover_url: null,
})

export default function Articles() {
  const [articles, setArticles] = useState<Article[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [draft, setDraft] = useState<Draft>(emptyDraft())
  const [saving, setSaving] = useState(false)
  const [catFilter, setCatFilter] = useState('all')

  const load = async () => {
    const { data } = await supabase
      .from('articles')
      .select('*')
      .order('published_at', { ascending: false })
    setArticles(data ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  const save = async () => {
    if (!draft.title_uz || !draft.body_uz) return alert('Uzbek title and body are required')
    setSaving(true)
    const { error } = await supabase.from('articles').insert([draft])
    setSaving(false)
    if (error) { alert(error.message); return }
    setDraft(emptyDraft())
    setShowForm(false)
    load()
  }

  const remove = async (id: string) => {
    if (!confirm('Delete this article?')) return
    await supabase.from('articles').delete().eq('id', id)
    load()
  }

  const togglePaid = async (a: Article) => {
    await supabase.from('articles').update({ is_paid: !a.is_paid }).eq('id', a.id)
    load()
  }

  const filtered = catFilter === 'all' ? articles : articles.filter(a => a.category === catFilter)

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Articles</h1>
        <button
          onClick={() => setShowForm(v => !v)}
          className="flex items-center gap-2 px-4 py-2 bg-violet-600 text-white rounded-lg text-sm font-medium hover:bg-violet-700 transition-colors"
        >
          <Plus size={16} /> New Article
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-xl border border-gray-200 p-6 mb-6 space-y-4">
          <h2 className="font-semibold text-gray-900">New Article</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Title (Uzbek) *</label>
              <input value={draft.title_uz} onChange={e => setDraft(d => ({ ...d, title_uz: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400" />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Title (Russian)</label>
              <input value={draft.title_ru ?? ''} onChange={e => setDraft(d => ({ ...d, title_ru: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400" />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Body (Uzbek) *</label>
            <textarea rows={4} value={draft.body_uz} onChange={e => setDraft(d => ({ ...d, body_uz: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Body (Russian)</label>
            <textarea rows={4} value={draft.body_ru ?? ''} onChange={e => setDraft(d => ({ ...d, body_ru: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400" />
          </div>
          <div className="flex gap-4 items-end">
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Category</label>
              <select value={draft.category} onChange={e => setDraft(d => ({ ...d, category: e.target.value }))} className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400">
                {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" id="paid" checked={draft.is_paid} onChange={e => setDraft(d => ({ ...d, is_paid: e.target.checked }))} className="w-4 h-4 accent-violet-600" />
              <label htmlFor="paid" className="text-sm text-gray-700">Paid only</label>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Cover URL</label>
              <input value={draft.cover_url ?? ''} onChange={e => setDraft(d => ({ ...d, cover_url: e.target.value || null }))} className="w-64 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400" />
            </div>
            <button onClick={save} disabled={saving} className="px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 disabled:opacity-50">
              {saving ? 'Saving…' : 'Publish'}
            </button>
            <button onClick={() => setShowForm(false)} className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg text-sm hover:bg-gray-200">Cancel</button>
          </div>
        </div>
      )}

      <div className="flex gap-2 mb-4">
        {['all', ...CATEGORIES].map(c => (
          <button key={c} onClick={() => setCatFilter(c)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition-colors ${catFilter === c ? 'bg-violet-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
            {c.replace('_', ' ')}
          </button>
        ))}
      </div>

      {loading ? <div className="text-gray-500">Loading…</div> : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Title</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Category</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Access</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Published</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.map(a => (
                <tr key={a.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-900 max-w-xs truncate">{a.title_uz}</td>
                  <td className="px-4 py-3"><span className="px-2 py-0.5 rounded-full text-xs bg-violet-50 text-violet-700 capitalize">{a.category.replace('_', ' ')}</span></td>
                  <td className="px-4 py-3">
                    {a.is_paid
                      ? <span className="inline-flex items-center gap-1 text-xs font-medium text-amber-700 bg-amber-50 px-2 py-0.5 rounded-full"><Lock size={11} /> Paid</span>
                      : <span className="inline-flex items-center gap-1 text-xs font-medium text-green-700 bg-green-50 px-2 py-0.5 rounded-full"><Unlock size={11} /> Free</span>
                    }
                  </td>
                  <td className="px-4 py-3 text-gray-500">{format(new Date(a.published_at), 'MMM d, yyyy')}</td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <button onClick={() => togglePaid(a)} className="text-xs px-2 py-1 rounded-md bg-gray-50 text-gray-600 hover:bg-gray-100 border border-gray-200">
                        {a.is_paid ? 'Make Free' : 'Make Paid'}
                      </button>
                      <button onClick={() => remove(a.id)} className="text-xs px-2 py-1 rounded-md bg-red-50 text-red-600 hover:bg-red-100">
                        <Trash2 size={12} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-8 text-center text-gray-400">No articles</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
