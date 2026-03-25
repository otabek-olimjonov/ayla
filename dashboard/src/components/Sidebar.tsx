import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Users, CreditCard, BookOpen,
  MessageSquare, LogOut, Moon
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
  const { signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  return (
    <aside className="w-60 min-h-screen bg-white border-r border-gray-200 flex flex-col">
      <div className="p-6 flex items-center gap-2 border-b border-gray-200">
        <Moon className="text-violet-500" size={22} />
        <span className="font-bold text-lg text-gray-900">Ayla Admin</span>
      </div>
      <nav className="flex-1 p-4 space-y-1">
        {links.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-violet-50 text-violet-700'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`
            }
          >
            <Icon size={18} />
            {label}
          </NavLink>
        ))}
      </nav>
      <div className="p-4 border-t border-gray-200">
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 px-3 py-2 w-full rounded-lg text-sm font-medium text-gray-600 hover:bg-red-50 hover:text-red-600 transition-colors"
        >
          <LogOut size={18} />
          Sign out
        </button>
      </div>
    </aside>
  )
}
