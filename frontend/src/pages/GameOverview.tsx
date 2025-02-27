import { useState, useEffect } from 'react';
import axios from 'axios';

interface Game {
  id: number;
  type: 'foosball' | 'chess';
  player1: {
    id: number;
    username: string;
  };
  player2: {
    id: number;
    username: string;
  };
  status: 'active' | 'completed';
  score?: {
    player1: number;
    player2: number;
  };
  winner?: number;
  created_at: string;
  updated_at: string;
}

const GameOverview = () => {
  const [activeGames, setActiveGames] = useState<Game[]>([]);
  const [completedGames, setCompletedGames] = useState<Game[]>([]);
  const [loading, setLoading] = useState(true);
  const [showNewGameModal, setShowNewGameModal] = useState(false);
  const [gameType, setGameType] = useState<'foosball' | 'chess'>('foosball');
  const [player1, setPlayer1] = useState('');
  const [player2, setPlayer2] = useState('');

  useEffect(() => {
    // In a real app, this would fetch data from the API
    // For now, we'll use mock data
    setTimeout(() => {
      setActiveGames([
        {
          id: 1,
          type: 'foosball',
          player1: {
            id: 1,
            username: 'john_doe'
          },
          player2: {
            id: 2,
            username: 'jane_smith'
          },
          status: 'active',
          score: {
            player1: 5,
            player2: 3
          },
          created_at: '2023-05-10T14:30:00Z',
          updated_at: '2023-05-10T14:45:00Z'
        },
        {
          id: 2,
          type: 'chess',
          player1: {
            id: 3,
            username: 'bob_johnson'
          },
          player2: {
            id: 4,
            username: 'alice_williams'
          },
          status: 'active',
          created_at: '2023-05-10T15:00:00Z',
          updated_at: '2023-05-10T15:10:00Z'
        }
      ]);
      
      setCompletedGames([
        {
          id: 3,
          type: 'foosball',
          player1: {
            id: 1,
            username: 'john_doe'
          },
          player2: {
            id: 3,
            username: 'bob_johnson'
          },
          status: 'completed',
          score: {
            player1: 10,
            player2: 8
          },
          winner: 1,
          created_at: '2023-05-09T10:00:00Z',
          updated_at: '2023-05-09T10:20:00Z'
        },
        {
          id: 4,
          type: 'chess',
          player1: {
            id: 2,
            username: 'jane_smith'
          },
          player2: {
            id: 4,
            username: 'alice_williams'
          },
          status: 'completed',
          winner: 4,
          created_at: '2023-05-08T16:00:00Z',
          updated_at: '2023-05-08T16:45:00Z'
        }
      ]);
      
      setLoading(false);
    }, 1000);
  }, []);

  const handleCreateGame = () => {
    // In a real app, this would create a new game via the API
    const newGame: Game = {
      id: activeGames.length + completedGames.length + 1,
      type: gameType,
      player1: {
        id: 1, // This would be a real user ID in a real app
        username: player1
      },
      player2: {
        id: 2, // This would be a real user ID in a real app
        username: player2
      },
      status: 'active',
      score: gameType === 'foosball' ? { player1: 0, player2: 0 } : undefined,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    setActiveGames([...activeGames, newGame]);
    setShowNewGameModal(false);
    setPlayer1('');
    setPlayer2('');
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
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
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-text">Game Overview</h1>
        <button 
          className="bg-primary text-white px-4 py-2 rounded-lg shadow hover:bg-blue-700 transition"
          onClick={() => setShowNewGameModal(true)}
        >
          Start New Game
        </button>
      </div>
      
      {/* Active Games */}
      <div className="mb-8">
        <h2 className="text-2xl font-semibold text-text mb-4">Active Games</h2>
        {activeGames.length === 0 ? (
          <p className="text-gray-500">No active games at the moment.</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {activeGames.map(game => (
              <div key={game.id} className="bg-white rounded-lg shadow p-6 border-l-4 border-green-500">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-lg font-semibold text-text">
                    {game.type === 'foosball' ? 'Foosball Match' : 'Chess Match'}
                  </h3>
                  <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-semibold">
                    Active
                  </span>
                </div>
                
                <div className="flex justify-between items-center mb-4">
                  <div className="text-center">
                    <p className="font-medium text-text">{game.player1.username}</p>
                    {game.type === 'foosball' && game.score && (
                      <p className="text-3xl font-bold text-primary mt-2">{game.score.player1}</p>
                    )}
                  </div>
                  
                  <div className="text-center">
                    <p className="text-sm text-gray-500 mb-2">vs</p>
                    {game.type === 'foosball' && game.score && (
                      <p className="text-xl font-bold">-</p>
                    )}
                  </div>
                  
                  <div className="text-center">
                    <p className="font-medium text-text">{game.player2.username}</p>
                    {game.type === 'foosball' && game.score && (
                      <p className="text-3xl font-bold text-secondary mt-2">{game.score.player2}</p>
                    )}
                  </div>
                </div>
                
                <div className="text-sm text-gray-500">
                  <p>Started: {formatDate(game.created_at)}</p>
                  <p>Last update: {formatDate(game.updated_at)}</p>
                </div>
                
                <div className="mt-4 flex justify-end">
                  <button className="text-primary hover:text-blue-700 text-sm font-medium">
                    View Details
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
      
      {/* Completed Games */}
      <div>
        <h2 className="text-2xl font-semibold text-text mb-4">Match History</h2>
        {completedGames.length === 0 ? (
          <p className="text-gray-500">No completed games yet.</p>
        ) : (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Game Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Players
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Result
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {completedGames.map(game => (
                  <tr key={game.id}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 rounded-full text-xs font-semibold ${
                        game.type === 'foosball' 
                          ? 'bg-blue-100 text-blue-800' 
                          : 'bg-purple-100 text-purple-800'
                      }`}>
                        {game.type === 'foosball' ? 'Foosball' : 'Chess'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-text">
                        {game.player1.username} vs {game.player2.username}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {game.type === 'foosball' && game.score ? (
                        <div className="text-sm text-text">
                          {game.score.player1} - {game.score.player2}
                        </div>
                      ) : (
                        <div className="text-sm text-text">
                          Winner: {game.winner === game.player1.id ? game.player1.username : game.player2.username}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-500">
                        {formatDate(game.created_at)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button className="text-primary hover:text-blue-700">
                        View Details
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
      
      {/* New Game Modal */}
      {showNewGameModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg p-6 w-full max-w-md">
            <h2 className="text-2xl font-bold text-text mb-4">Start New Game</h2>
            
            <div className="mb-4">
              <label className="block text-gray-700 text-sm font-bold mb-2">
                Game Type
              </label>
              <div className="flex">
                <button 
                  className={`flex-1 py-2 px-4 rounded-l-lg ${
                    gameType === 'foosball' 
                      ? 'bg-primary text-white' 
                      : 'bg-gray-200 text-gray-700'
                  }`}
                  onClick={() => setGameType('foosball')}
                >
                  Foosball
                </button>
                <button 
                  className={`flex-1 py-2 px-4 rounded-r-lg ${
                    gameType === 'chess' 
                      ? 'bg-primary text-white' 
                      : 'bg-gray-200 text-gray-700'
                  }`}
                  onClick={() => setGameType('chess')}
                >
                  Chess
                </button>
              </div>
            </div>
            
            <div className="mb-4">
              <label className="block text-gray-700 text-sm font-bold mb-2">
                Player 1
              </label>
              <input 
                type="text" 
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                value={player1}
                onChange={(e) => setPlayer1(e.target.value)}
                placeholder="Enter username or scan RFID"
              />
            </div>
            
            <div className="mb-6">
              <label className="block text-gray-700 text-sm font-bold mb-2">
                Player 2
              </label>
              <input 
                type="text" 
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                value={player2}
                onChange={(e) => setPlayer2(e.target.value)}
                placeholder="Enter username or scan RFID"
              />
            </div>
            
            <div className="flex justify-end">
              <button 
                className="bg-gray-300 text-gray-800 px-4 py-2 rounded-lg mr-2 hover:bg-gray-400 transition"
                onClick={() => {
                  setShowNewGameModal(false);
                  setPlayer1('');
                  setPlayer2('');
                }}
              >
                Cancel
              </button>
              <button 
                className="bg-primary text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition"
                onClick={handleCreateGame}
                disabled={!player1 || !player2}
              >
                Start Game
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default GameOverview; 