import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { CommunityPost } from '../lib/supabase'
import { format } from 'date-fns'
import { Trash2, Heart } from 'lucide-react'

const CATS = ['general', 'pregnancy', 'symptoms', 'advice']

export default function Community() {
  const [posts, setPosts] = useState<CommunityPost[]>([])
  const [loading, setLoading] = useState(true)
  const [catFilter, setCatFilter] = useState('all')
  const [deleting, setDeleting] = useState<string | null>(null)

  const load = async () => {
    const q = supabase.from('community_posts').select('*').order('created_at', { ascending: false })
    const { data } = catFilter === 'all' ? await q : await q.eq('category', catFilter)
    setPosts(data ?? [])
    setLoading(false)
  }

  useEffect(() => { setLoading(true); load() }, [catFilter])

  const remove = async (id: string) => {
    if (!confirm('Delete this post and all its comments?')) return
    setDeleting(id)
    await supabase.from('community_posts').delete().eq('id', id)
    setDeleting(null)
    load()
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Community</h1>
        <span className="text-sm text-gray-500">{posts.length} posts</span>
      </div>
      <div className="flex gap-2 mb-4">
        {['all', ...CATS].map(c => (
          <button key={c} onClick={() => setCatFilter(c)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition-colors ${catFilter === c ? 'bg-violet-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
            {c}
          </button>
        ))}
      </div>
      {loading ? <div className="text-gray-500">Loading…</div> : (
        <div className="space-y-3">
          {posts.map(p => (
            <div key={p.id} className="bg-white rounded-xl border border-gray-200 p-4">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="px-2 py-0.5 rounded-full text-xs bg-violet-50 text-violet-700 capitalize">{p.category}</span>
                    {p.is_anonymous && <span className="px-2 py-0.5 rounded-full text-xs bg-gray-100 text-gray-500">Anonymous</span>}
                    <span className="text-xs text-gray-400 ml-auto">{format(new Date(p.created_at), 'MMM d, yyyy HH:mm')}</span>
                  </div>
                  <p className="text-sm text-gray-800 leading-relaxed line-clamp-3">{p.body}</p>
                  <div className="flex items-center gap-1 mt-2 text-xs text-gray-400">
                    <Heart size={12} /> {p.likes_count} likes
                  </div>
                </div>
                <button
                  onClick={() => remove(p.id)}
                  disabled={deleting === p.id}
                  className="shrink-0 p-1.5 rounded-lg text-red-400 hover:bg-red-50 hover:text-red-600 transition-colors disabled:opacity-50"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          ))}
          {posts.length === 0 && (
            <div className="bg-white rounded-xl border border-gray-200 p-8 text-center text-gray-400">No posts</div>
          )}
        </div>
      )}
    </div>
  )
}
