export interface User {
  id: number;
  username: string;
  email: string;
  rfid_uid: string;
  isAdmin: boolean;
  active: boolean;
  created_at: string;
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

export interface EditUserForm {
  username: string;
  email: string;
  rfid_uid: string;
  isAdmin: boolean;
  password?: string;
} 