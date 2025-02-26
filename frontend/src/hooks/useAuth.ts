import { create } from 'zustand';
import axios from 'axios';
import { User, AuthState } from '@/types';

export const useAuth = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  isAdmin: false,

  login: async (email: string, password: string) => {
    try {
      const { data } = await axios.post<{ user: User }>('/api/auth/login', { email, password });
      set({
        user: data.user,
        isAuthenticated: true,
        isAdmin: data.user.isAdmin,
      });
    } catch (error) {
      throw new Error('Invalid credentials');
    }
  },

  logout: async () => {
    try {
      await axios.post('/api/auth/logout');
      set({ user: null, isAuthenticated: false, isAdmin: false });
    } catch (error) {
      console.error('Logout failed:', error);
    }
  },

  updateProfile: async (data: Partial<User>) => {
    try {
      const response = await axios.put<User>('/api/users/profile', data);
      set((state) => ({
        user: { ...state.user, ...response.data } as User,
      }));
    } catch (error) {
      throw new Error('Failed to update profile');
    }
  },
})); 