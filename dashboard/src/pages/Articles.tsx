import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { Article } from '../lib/supabase'
import { format } from 'date-fns'
import { Plus, Lock, Unlock, Trash2, BookOpen, X, ChevronDown } from 'lucide-react'

const CATEGORIES = ['cycle', 'pregnancy', 'nutrition', 'mental_health']

const CAT_COLORS: Record<string, string> = {
  cycle: 'bg-pink-50 text-pink-600 border-pink-100',
  pregnancy: 'bg-blue-50 text-blue-600 border-blue-100',
  nutrition: 'bg-green-50 text-green-600 border-green-100',
  mental_health: 'bg-purple-50 text-purple-600 border-purple-100',
}

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
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Articles</h1>
          <p className="text-sm text-gray-500 mt-1">{articles.length} articles · {articles.filter(a => a.is_paid).length} paid</p>
        </div>
        <button
          onClick={() => setShowForm(v => !v)}
          className="flex items-center gap-2 px-4 py-2.5 bg-violet-600 text-white rounded-xl text-sm font-semibold hover:bg-violet-700 transition-colors shadow-sm shadow-violet-200"
        >
          {showForm ? <X size={15} /> : <Plus size={15} />}
          {showForm ? 'Cancel' : 'New Article'}
        </button>
      </div>

      {/* Create form */}
      {showForm && (
        <div className="bg-white rounded-2xl border border-violet-100 shadow-sm p-6 mb-6">
          <h2 className="font-semibold text-gray-900 mb-5 flex items-center gap-2">
            <BookOpen size={16} className="text-violet-500" /> New Article
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">Title (Uzbek) *</label>
              <input
                value={draft.title_uz}
                onChange={e => setDraft(d => ({ ...d, title_uz: e.target.value }))}
                className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400 focus:border-transparent"
                placeholder="Sarlavha uzbekcha…"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">Title (Russian)</label>
              <input
                value={draft.title_ru ?? ''}
                onChange={e => setDraft(d => ({ ...d, title_ru: e.target.value }))}
                className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400 focus:border-transparent"
                placeholder="Заголовок по-русски…"
              />
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">Body (Uzbek) *</label>
              <textarea
                rows={5}
                value={draft.body_uz}
                onChange={e => setDraft(d => ({ ...d, body_uz: e.target.value }))}
                className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400 focus:border-transparent resize-none"
                placeholder="Maqola matni…"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">Body (Russian)</label>
              <textarea
                rows={5}
                value={draft.body_ru ?? ''}
                onChange={e => setDraft(d => ({ ...d, body_ru: e.target.value }))}
                className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400 focus:border-transparent resize-none"
                placeholder="Текст статьи…"
              />
            </div>
          </div>
          <div className="flex flex-wrap gap-4 items-end">
            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">Category</label>
              <div className="relative">
                <select
                  value={draft.category}
                  onChange={e => setDraft(d => ({ ...d, category: e.target.value }))}
                  className="appearance-none border border-gray-200 rounded-xl px-3.5 py-2.5 pr-8 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400 bg-white"
                >
                  {CATEGORIES.map(c => <option key={c} value={c}>{c.replace('_', ' ')}</option>)}
                </select>
                <ChevronDown size={13} className="absolute right-2.5 top-3 text-gray-400 pointer-events-none" />
              </div>
            </div>
            <div className="flex items-center gap-2.5">
              <input
                type="checkbox"
                id="paid"
                checked={draft.is_paid}
                onChange={e => setDraft(d => ({ ...d, is_paid: e.target.checked }))}
                className="w-4 h-4 accent-violet-600 rounded"
              />
              <label htmlFor="paid" className="text-sm font-medium text-gray-700">Paid only</label>
            </div>
            <div className="flex-1 min-w-48">
              <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">Cover URL</label>
              <input
                value={draft.cover_url ?? ''}
                onChange={e => setDraft(d => ({ ...d, cover_url: e.target.value || null }))}
                className="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-violet-400"
                placeholder="https://…"
              />
            </div>
            <button
              onClick={save}
              disabled={saving}
              className="px-5 py-2.5 bg-green-600 text-white rounded-xl text-sm font-semibold hover:bg-green-700 disabled:opacity-50 shadow-sm shadow-green-200 transition-colors"
            >
              {saving ? 'Publishing…' : 'Publish'}
            </button>
          </div>
        </div>
      )}

      {/* Category filters */}
      <div className="flex gap-2 mb-5 flex-wrap">
        {['all', ...CATEGORIES].map(c => (
          <button
            key={c}
            onClick={() => setCatFilter(c)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold capitalize transition-all border ${
              catFilter === c
                ? 'bg-violet-600 text-white border-violet-600 shadow-sm shadow-violet-200'
                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
            }`}
          >
            {c.replace('_', ' ')}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="space-y-3">
          {[1,2,3].map(i => <div key={i} className="h-16 bg-gray-100 rounded-2xl animate-pulse" />)}
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Title</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Category</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Access</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Published</th>
                <th className="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map(a => (
                <tr key={a.id} className="hover:bg-violet-50/20 transition-colors group">
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      {a.cover_url ? (
                        <img src={a.cover_url} alt="" className="w-10 h-10 rounded-xl object-cover shrink-0 bg-gray-100" />
                      ) : (
                        <div className="w-10 h-10 rounded-xl bg-violet-50 flex items-center justify-center shrink-0">
                          <BookOpen size={15} className="text-violet-400" />
                        </div>
                      )}
                      <span className="font-medium text-gray-900 truncate max-w-xs">{a.title_uz}</span>
                    </div>
                  </td>
                  <td className="px-5 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize border ${CAT_COLORS[a.category] ?? 'bg-gray-50 text-gray-600 border-gray-100'}`}>
                      {a.category.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-5 py-4">
                    {a.is_paid ? (
                      <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-amber-700 bg-amber-50 px-2.5 py-1 rounded-full border border-amber-100">
                        <Lock size={11} /> Paid
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-green-700 bg-green-50 px-2.5 py-1 rounded-full border border-green-100">
                        <Unlock size={11} /> Free
                      </span>
                    )}
                  </td>
                  <td className="px-5 py-4 text-xs text-gray-400">
                    {format(new Date(a.published_at), 'MMM d, yyyy')}
                  </td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => togglePaid(a)}
                        className="text-xs px-2.5 py-1 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 border border-gray-200 font-medium transition-colors"
                      >
                        {a.is_paid ? 'Make Free' : 'Make Paid'}
                      </button>
                      <button
                        onClick={() => remove(a.id)}
                        className="p-1.5 rounded-lg text-red-300 hover:bg-red-50 hover:text-red-500 transition-colors opacity-0 group-hover:opacity-100"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-16 text-center">
                    <BookOpen size={32} className="text-gray-200 mx-auto mb-3" />
                    <p className="text-gray-400 text-sm">No articles in this category</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

