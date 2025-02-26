import { useState } from 'react';
import { useQuery } from 'react-query';
import { TrophyIcon } from '@heroicons/react/24/solid';
import axios from 'axios';

interface Player {
  id: number;
  username: string;
  elo: number;
  wins: number;
  losses: number;
}

interface GameType {
  id: number;
  name: string;
  players: Player[];
}

const Leaderboard = () => {
  const [selectedGame, setSelectedGame] = useState<number>(2); // Default to foosball

  const { data: games, isLoading } = useQuery<GameType[]>('games', async () => {
    const { data } = await axios.get('/api/games/leaderboard');
    return data;
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  const selectedGameData = games?.find((game) => game.id === selectedGame);

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-text mb-4">Leaderboard</h1>
        
        {/* Game Type Selector */}
        <div className="flex space-x-4 mb-6">
          {games?.map((game) => (
            <button
              key={game.id}
              onClick={() => setSelectedGame(game.id)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                selectedGame === game.id
                  ? 'bg-primary text-white'
                  : 'bg-white text-text hover:bg-gray-50'
              }`}
            >
              {game.name}
            </button>
          ))}
        </div>

        {/* Leaderboard Table */}
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          <table className="min-w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Rank
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Player
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  ELO
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  W/L
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {selectedGameData?.players.map((player, index) => (
                <tr
                  key={player.id}
                  className={index < 3 ? 'bg-yellow-50' : 'bg-white'}
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      {index < 3 && (
                        <TrophyIcon
                          className={`w-5 h-5 mr-2 ${
                            index === 0
                              ? 'text-yellow-400'
                              : index === 1
                              ? 'text-gray-400'
                              : 'text-amber-600'
                          }`}
                        />
                      )}
                      <span className="text-sm font-medium text-text">
                        {index + 1}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-text">
                      {player.username}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-text">{player.elo}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-text">
                      {player.wins}/{player.losses}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Leaderboard; 