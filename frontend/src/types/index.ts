export interface User {
  id: number;
  username: string;
  email: string;
  isAdmin: boolean;
  rfid_uid?: string;
  active: boolean;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export interface LoginForm {
  username: string;
  password: string;
}

export interface RegisterForm {
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
}

export interface EditUserForm {
  username?: string;
  email?: string;
  password?: string;
  isAdmin?: boolean;
  rfid_uid?: string;
  active?: boolean;
}

export interface Game {
  id: number;
  name: string;
  description: string;
  active: boolean;
  created_at: string;
}

export interface Match {
  id: number;
  game_id: number;
  player1_id: number;
  player2_id: number;
  player1_score: number;
  player2_score: number;
  winner_id: number | null;
  status: 'pending' | 'active' | 'completed' | 'cancelled';
  created_at: string;
  updated_at: string;
}

export interface Player {
  id: number;
  username: string;
  elo: number;
  wins: number;
  losses: number;
}

export interface GameType {
  id: number;
  name: string;
  players: Player[];
}

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (data: Partial<User>) => Promise<void>;
} 