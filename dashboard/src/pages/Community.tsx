import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { CommunityPost } from '../lib/supabase'
import { format } from 'date-fns'
import { Trash2, Heart, MessageSquare, User, EyeOff } from 'lucide-react'

const CATS = ['general', 'pregnancy', 'symptoms', 'advice']

const CAT_COLORS: Record<string, string> = {
  general: 'bg-gray-100 text-gray-600',
  pregnancy: 'bg-blue-50 text-blue-600',
  symptoms: 'bg-rose-50 text-rose-600',
  advice: 'bg-green-50 text-green-600',
}

export default function Community() {
  const [posts, setPosts] = useState<CommunityPost[]>([])
  const [loading, setLoading] = useState(true)
  const [catFilter, setCatFilter] = useState('all')
  const [deleting, setDeleting] = useState<string | null>(null)

  const load = async () => {
    setLoading(true)
    const q = supabase.from('community_posts').select('*').order('created_at', { ascending: false })
    const { data } = catFilter === 'all' ? await q : await q.eq('category', catFilter)
    setPosts(data ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [catFilter])

  const remove = async (id: string) => {
    if (!confirm('Delete this post and all its comments?')) return
    setDeleting(id)
    await supabase.from('community_posts').delete().eq('id', id)
    setDeleting(null)
    load()
  }

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Community</h1>
          <p className="text-sm text-gray-500 mt-1">{posts.length} posts · moderation view</p>
        </div>
      </div>

      <div className="flex gap-2 mb-6 flex-wrap">
        {['all', ...CATS].map(c => (
          <button
            key={c}
            onClick={() => setCatFilter(c)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold capitalize transition-all border ${
              catFilter === c
                ? 'bg-violet-600 text-white border-violet-600 shadow-sm shadow-violet-200'
                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
            }`}
          >{c}</button>
        ))}
      </div>

      {loading ? (
        <div className="space-y-3">
          {[1,2,3].map(i => <div key={i} className="h-28 bg-gray-100 rounded-2xl animate-pulse" />)}
        </div>
      ) : posts.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 p-16 text-center shadow-sm">
          <MessageSquare size={40} className="text-gray-200 mx-auto mb-3" />
          <p className="text-gray-400">No posts in this category</p>
        </div>
      ) : (
        <div className="space-y-3">
          {posts.map(p => (
            <div
              key={p.id}
              className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5 hover:shadow-md transition-shadow group"
            >
              <div className="flex items-start gap-4">
                <div className="w-9 h-9 rounded-full bg-violet-50 flex items-center justify-center shrink-0 mt-0.5">
                  {p.is_anonymous ? (
                    <EyeOff size={14} className="text-violet-300" />
                  ) : (
                    <User size={14} className="text-violet-400" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-2 flex-wrap">
                    <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold capitalize ${CAT_COLORS[p.category] ?? 'bg-gray-100 text-gray-600'}`}>
                      {p.category}
                    </span>
                    {p.is_anonymous && (
                      <span className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-400">
                        Anonymous
                      </span>
                    )}
                    <span className="text-xs text-gray-400 ml-auto">
                      {format(new Date(p.created_at), 'MMM d, yyyy · HH:mm')}
                    </span>
                  </div>
                  <p className="text-sm text-gray-700 leading-relaxed line-clamp-3">{p.body}</p>
                  <div className="flex items-center gap-1 mt-3 text-xs text-gray-400">
                    <Heart size={12} className="text-pink-300" />
                    <span>{p.likes_count}</span>
                    <span className="ml-1">likes</span>
                  </div>
                </div>
                <button
                  onClick={() => remove(p.id)}
                  disabled={deleting === p.id}
                  className="shrink-0 p-2 rounded-xl text-gray-300 hover:bg-red-50 hover:text-red-500 transition-colors disabled:opacity-50 opacity-0 group-hover:opacity-100"
                >
                  <Trash2 size={15} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
