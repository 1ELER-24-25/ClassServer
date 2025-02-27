import { useState, useEffect } from 'react';
import axios from 'axios';

interface UserStats {
  id: number;
  username: string;
  foosball: {
    elo: number;
    wins: number;
    losses: number;
    draws: number;
    total: number;
  };
  chess: {
    elo: number;
    wins: number;
    losses: number;
    draws: number;
    total: number;
  };
}

const Statistics = () => {
  const [users, setUsers] = useState<UserStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [gameType, setGameType] = useState<'foosball' | 'chess'>('foosball');

  useEffect(() => {
    // In a real app, this would fetch data from the API
    // For now, we'll use mock data
    setTimeout(() => {
      setUsers([
        {
          id: 1,
          username: 'john_doe',
          foosball: {
            elo: 1345,
            wins: 15,
            losses: 8,
            draws: 2,
            total: 25
          },
          chess: {
            elo: 1250,
            wins: 5,
            losses: 7,
            draws: 3,
            total: 15
          }
        },
        {
          id: 2,
          username: 'jane_smith',
          foosball: {
            elo: 1420,
            wins: 20,
            losses: 5,
            draws: 0,
            total: 25
          },
          chess: {
            elo: 1180,
            wins: 3,
            losses: 10,
            draws: 2,
            total: 15
          }
        },
        {
          id: 3,
          username: 'bob_johnson',
          foosball: {
            elo: 1150,
            wins: 5,
            losses: 15,
            draws: 0,
            total: 20
          },
          chess: {
            elo: 1380,
            wins: 12,
            losses: 3,
            draws: 5,
            total: 20
          }
        },
        {
          id: 4,
          username: 'alice_williams',
          foosball: {
            elo: 1280,
            wins: 10,
            losses: 10,
            draws: 5,
            total: 25
          },
          chess: {
            elo: 1450,
            wins: 18,
            losses: 2,
            draws: 0,
            total: 20
          }
        }
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  const sortedUsers = [...users].sort((a, b) => {
    return b[gameType].elo - a[gameType].elo;
  });

  const calculateWinRate = (wins: number, total: number) => {
    if (total === 0) return 0;
    return Math.round((wins / total) * 100);
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-3xl font-bold text-text mb-8">Statistics</h1>
      
      {/* Game Type Selector */}
      <div className="mb-8">
        <div className="inline-flex rounded-md shadow-sm">
          <button
            className={`px-4 py-2 text-sm font-medium rounded-l-lg ${
              gameType === 'foosball'
                ? 'bg-primary text-white'
                : 'bg-white text-gray-700 hover:bg-gray-50'
            }`}
            onClick={() => setGameType('foosball')}
          >
            Foosball
          </button>
          <button
            className={`px-4 py-2 text-sm font-medium rounded-r-lg ${
              gameType === 'chess'
                ? 'bg-primary text-white'
                : 'bg-white text-gray-700 hover:bg-gray-50'
            }`}
            onClick={() => setGameType('chess')}
          >
            Chess
          </button>
        </div>
      </div>
      
      {/* Leaderboard */}
      <div className="mb-8">
        <h2 className="text-2xl font-semibold text-text mb-4">
          {gameType === 'foosball' ? 'Foosball' : 'Chess'} Leaderboard
        </h2>
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Rank
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Player
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Elo Rating
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Win Rate
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  W/L/D
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {sortedUsers.map((user, index) => (
                <tr key={user.id} className={index === 0 ? 'bg-yellow-50' : ''}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-text">
                      {index + 1}
                      {index === 0 && (
                        <span className="ml-2 text-yellow-500">👑</span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-text">{user.username}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-text">{user[gameType].elo}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="w-full bg-gray-200 rounded-full h-2.5">
                      <div 
                        className="bg-primary rounded-full h-2.5" 
                        style={{ width: `${calculateWinRate(user[gameType].wins, user[gameType].total)}%` }}
                      ></div>
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      {calculateWinRate(user[gameType].wins, user[gameType].total)}%
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-text">
                      {user[gameType].wins}/{user[gameType].losses}/{user[gameType].draws}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      
      {/* Game Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-text mb-4">
            {gameType === 'foosball' ? 'Foosball' : 'Chess'} Stats
          </h2>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-sm font-medium text-text">Total Games</span>
                <span className="text-sm font-medium text-text">
                  {sortedUsers.reduce((sum, user) => sum + user[gameType].total, 0)}
                </span>
              </div>
            </div>
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-sm font-medium text-text">Average Elo</span>
                <span className="text-sm font-medium text-text">
                  {Math.round(
                    sortedUsers.reduce((sum, user) => sum + user[gameType].elo, 0) / sortedUsers.length
                  )}
                </span>
              </div>
            </div>
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-sm font-medium text-text">Highest Elo</span>
                <span className="text-sm font-medium text-text">
                  {sortedUsers.length > 0 ? sortedUsers[0][gameType].elo : 0}
                </span>
              </div>
            </div>
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-sm font-medium text-text">Most Wins</span>
                <span className="text-sm font-medium text-text">
                  {sortedUsers.length > 0 
                    ? Math.max(...sortedUsers.map(user => user[gameType].wins))
                    : 0}
                </span>
              </div>
            </div>
          </div>
        </div>
        
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-text mb-4">Elo Distribution</h2>
          <div className="space-y-6">
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-xs font-medium text-text">1400+</span>
                <span className="text-xs font-medium text-text">
                  {sortedUsers.filter(user => user[gameType].elo >= 1400).length} players
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-green-500 rounded-full h-2.5" 
                  style={{ 
                    width: `${(sortedUsers.filter(user => user[gameType].elo >= 1400).length / sortedUsers.length) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-xs font-medium text-text">1300-1399</span>
                <span className="text-xs font-medium text-text">
                  {sortedUsers.filter(user => user[gameType].elo >= 1300 && user[gameType].elo < 1400).length} players
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-blue-500 rounded-full h-2.5" 
                  style={{ 
                    width: `${(sortedUsers.filter(user => user[gameType].elo >= 1300 && user[gameType].elo < 1400).length / sortedUsers.length) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-xs font-medium text-text">1200-1299</span>
                <span className="text-xs font-medium text-text">
                  {sortedUsers.filter(user => user[gameType].elo >= 1200 && user[gameType].elo < 1300).length} players
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-yellow-500 rounded-full h-2.5" 
                  style={{ 
                    width: `${(sortedUsers.filter(user => user[gameType].elo >= 1200 && user[gameType].elo < 1300).length / sortedUsers.length) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-xs font-medium text-text">Below 1200</span>
                <span className="text-xs font-medium text-text">
                  {sortedUsers.filter(user => user[gameType].elo < 1200).length} players
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-red-500 rounded-full h-2.5" 
                  style={{ 
                    width: `${(sortedUsers.filter(user => user[gameType].elo < 1200).length / sortedUsers.length) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Statistics; 