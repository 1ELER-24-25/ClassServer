import { useState, useEffect } from 'react';
import axios from 'axios';

interface GameStats {
  totalGames: number;
  activeGames: number;
  foosballGames: number;
  chessGames: number;
}

interface UserStats {
  totalUsers: number;
  activeUsers: number;
}

const Dashboard = () => {
  const [gameStats, setGameStats] = useState<GameStats>({
    totalGames: 0,
    activeGames: 0,
    foosballGames: 0,
    chessGames: 0
  });
  
  const [userStats, setUserStats] = useState<UserStats>({
    totalUsers: 0,
    activeUsers: 0
  });
  
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // In a real app, this would fetch data from the API
    // For now, we'll use mock data
    setTimeout(() => {
      setGameStats({
        totalGames: 156,
        activeGames: 3,
        foosballGames: 98,
        chessGames: 58
      });
      
      setUserStats({
        totalUsers: 42,
        activeUsers: 28
      });
      
      setLoading(false);
    }, 1000);
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-3xl font-bold text-text mb-8">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {/* Stats Cards */}
        <div className="bg-white rounded-lg shadow p-6 border-l-4 border-primary">
          <h2 className="text-sm font-medium text-gray-500">Total Games</h2>
          <p className="text-3xl font-bold text-text mt-2">{gameStats.totalGames}</p>
        </div>
        
        <div className="bg-white rounded-lg shadow p-6 border-l-4 border-green-500">
          <h2 className="text-sm font-medium text-gray-500">Active Games</h2>
          <p className="text-3xl font-bold text-text mt-2">{gameStats.activeGames}</p>
        </div>
        
        <div className="bg-white rounded-lg shadow p-6 border-l-4 border-secondary">
          <h2 className="text-sm font-medium text-gray-500">Total Users</h2>
          <p className="text-3xl font-bold text-text mt-2">{userStats.totalUsers}</p>
        </div>
        
        <div className="bg-white rounded-lg shadow p-6 border-l-4 border-yellow-500">
          <h2 className="text-sm font-medium text-gray-500">Active Users</h2>
          <p className="text-3xl font-bold text-text mt-2">{userStats.activeUsers}</p>
        </div>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Game Distribution */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-text mb-4">Game Distribution</h2>
          <div className="flex items-center mb-4">
            <div className="w-full bg-gray-200 rounded-full h-4">
              <div 
                className="bg-primary rounded-full h-4" 
                style={{ width: `${(gameStats.foosballGames / gameStats.totalGames) * 100}%` }}
              ></div>
            </div>
            <span className="ml-4 text-sm font-medium text-text">
              {Math.round((gameStats.foosballGames / gameStats.totalGames) * 100)}% Foosball
            </span>
          </div>
          <div className="flex items-center">
            <div className="w-full bg-gray-200 rounded-full h-4">
              <div 
                className="bg-secondary rounded-full h-4" 
                style={{ width: `${(gameStats.chessGames / gameStats.totalGames) * 100}%` }}
              ></div>
            </div>
            <span className="ml-4 text-sm font-medium text-text">
              {Math.round((gameStats.chessGames / gameStats.totalGames) * 100)}% Chess
            </span>
          </div>
        </div>
        
        {/* Recent Activity */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-text mb-4">Recent Activity</h2>
          <div className="space-y-4">
            <div className="border-l-4 border-primary pl-4 py-2">
              <p className="text-sm text-gray-600">Just now</p>
              <p className="text-text">Magnus started a new chess game with Kasparov</p>
            </div>
            <div className="border-l-4 border-secondary pl-4 py-2">
              <p className="text-sm text-gray-600">5 minutes ago</p>
              <p className="text-text">John won a foosball match against Sarah (10-8)</p>
            </div>
            <div className="border-l-4 border-green-500 pl-4 py-2">
              <p className="text-sm text-gray-600">20 minutes ago</p>
              <p className="text-text">New user Alex registered</p>
            </div>
            <div className="border-l-4 border-yellow-500 pl-4 py-2">
              <p className="text-sm text-gray-600">1 hour ago</p>
              <p className="text-text">System maintenance completed</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard; 