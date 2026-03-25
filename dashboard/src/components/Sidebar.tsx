import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Users, CreditCard, BookOpen,
  MessageSquare, LogOut, Moon, ChevronRight
} from 'lucide-react'
import { useAuth } from '../hooks/useAuth'

const links = [
  { to: '/', icon: LayoutDashboard, label: 'Overview' },
  { to: '/users', icon: Users, label: 'Users' },
  { to: '/payments', icon: CreditCard, label: 'Payments' },
  { to: '/articles', icon: BookOpen, label: 'Articles' },
  { to: '/community', icon: MessageSquare, label: 'Community' },
]

export default function Sidebar() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  return (
    <aside className="w-64 shrink-0 h-screen flex flex-col bg-white border-r border-gray-100 shadow-sm">
      {/* Logo */}
      <div className="px-6 py-5 border-b border-gray-100">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-violet-500 to-purple-700 flex items-center justify-center shadow-md shadow-violet-200">
            <Moon size={18} className="text-white" />
          </div>
          <div>
            <p className="font-bold text-gray-900 text-sm leading-none">Ayla</p>
            <p className="text-xs text-gray-400 mt-0.5">Admin Dashboard</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
        <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-wider px-3 mb-2">Menu</p>
        {links.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `group flex items-center justify-between gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-gradient-to-r from-violet-50 to-purple-50 text-violet-700 shadow-sm'
                  : 'text-gray-500 hover:bg-gray-50 hover:text-gray-900'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <span className="flex items-center gap-3">
                  <span className={`flex items-center justify-center w-7 h-7 rounded-lg transition-colors ${isActive ? 'bg-violet-100 text-violet-600' : 'text-gray-400 group-hover:text-gray-600'}`}>
                    <Icon size={15} />
                  </span>
                  {label}
                </span>
                {isActive && <ChevronRight size={14} className="text-violet-400" />}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* User + Sign out */}
      <div className="p-3 border-t border-gray-100">
        <div className="px-3 py-2 mb-1">
          <p className="text-xs font-medium text-gray-900 truncate">{user?.email}</p>
          <p className="text-[10px] text-gray-400 mt-0.5">Administrator</p>
        </div>
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 px-3 py-2.5 w-full rounded-xl text-sm font-medium text-gray-500 hover:bg-red-50 hover:text-red-600 transition-all"
        >
          <span className="flex items-center justify-center w-7 h-7 rounded-lg text-gray-400">
            <LogOut size={15} />
          </span>
          Sign out
        </button>
      </div>
    </aside>
  )
}
