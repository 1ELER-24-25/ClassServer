import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import { useAuth } from '@hooks/useAuth';

// Layouts
import MainLayout from '@components/layouts/MainLayout';
import AuthLayout from '@components/layouts/AuthLayout';

// Pages
import Login from '@pages/auth/Login';
import Register from '@pages/auth/Register';
import Dashboard from '@pages/Dashboard';
import Profile from '@pages/Profile';
import Leaderboard from '@pages/Leaderboard';
import MatchHistory from '@pages/MatchHistory';
import AdminUsers from '@pages/admin/Users';
import AdminBackup from '@pages/admin/Backup';
import AdminGames from '@pages/admin/Games';
import NotFound from '@pages/NotFound';

// Components
import ProtectedRoute from '@components/auth/ProtectedRoute';
import AdminRoute from '@components/auth/AdminRoute';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          {/* Public routes */}
          <Route element={<AuthLayout />}>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/leaderboard" element={<Leaderboard />} />
          </Route>

          {/* Protected routes */}
          <Route element={<ProtectedRoute><MainLayout /></ProtectedRoute>}>
            <Route path="/" element={<Dashboard />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/matches" element={<MatchHistory />} />
            
            {/* Admin routes */}
            <Route element={<AdminRoute />}>
              <Route path="/admin/users" element={<AdminUsers />} />
              <Route path="/admin/backup" element={<AdminBackup />} />
              <Route path="/admin/games" element={<AdminGames />} />
            </Route>
          </Route>

          {/* Fallback route */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App; 