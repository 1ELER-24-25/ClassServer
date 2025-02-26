import { Outlet, Link } from 'react-router-dom';
import { useAuth } from '@hooks/useAuth';
import {
  HomeIcon,
  TrophyIcon,
  UserIcon,
  ClockIcon,
  UsersIcon,
  ServerIcon,
  CogIcon,
} from '@heroicons/react/24/outline';

const MainLayout = () => {
  const { user, isAdmin, logout } = useAuth();

  const navigation = [
    { name: 'Dashboard', href: '/', icon: HomeIcon },
    { name: 'Leaderboard', href: '/leaderboard', icon: TrophyIcon },
    { name: 'Match History', href: '/matches', icon: ClockIcon },
    { name: 'Profile', href: '/profile', icon: UserIcon },
  ];

  const adminNavigation = [
    { name: 'Users', href: '/admin/users', icon: UsersIcon },
    { name: 'Games', href: '/admin/games', icon: CogIcon },
    { name: 'Backup', href: '/admin/backup', icon: ServerIcon },
  ];

  return (
    <div className="min-h-screen bg-background">
      {/* Sidebar */}
      <div className="fixed inset-y-0 left-0 w-64 bg-white shadow-lg">
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center justify-center h-16 border-b">
            <h1 className="text-2xl font-bold text-primary">ClassServer</h1>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 space-y-1">
            {navigation.map((item) => (
              <Link
                key={item.name}
                to={item.href}
                className="flex items-center px-4 py-2 text-text hover:bg-primary hover:text-white rounded-lg"
              >
                <item.icon className="w-5 h-5 mr-3" />
                {item.name}
              </Link>
            ))}

            {/* Admin Navigation */}
            {isAdmin && (
              <>
                <div className="pt-4 pb-2">
                  <p className="px-4 text-sm font-semibold text-gray-500">Admin</p>
                </div>
                {adminNavigation.map((item) => (
                  <Link
                    key={item.name}
                    to={item.href}
                    className="flex items-center px-4 py-2 text-text hover:bg-primary hover:text-white rounded-lg"
                  >
                    <item.icon className="w-5 h-5 mr-3" />
                    {item.name}
                  </Link>
                ))}
              </>
            )}
          </nav>

          {/* User Menu */}
          <div className="p-4 border-t">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <UserIcon className="w-8 h-8 text-gray-400" />
              </div>
              <div className="ml-3">
                <p className="text-sm font-medium text-text">{user?.username}</p>
                <button
                  onClick={logout}
                  className="text-sm text-red-600 hover:text-red-800"
                >
                  Logout
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="ml-64 p-8">
        <Outlet />
      </div>
    </div>
  );
};

export default MainLayout; 