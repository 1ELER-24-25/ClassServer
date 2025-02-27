import { useState, useEffect } from 'react';
import axios from 'axios';

interface User {
  id: number;
  username: string;
  email: string;
  rfid_uid: string | null;
  active: boolean;
  isAdmin: boolean;
  created_at: string;
}

const UserManagement = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [rfidMode, setRfidMode] = useState(false);
  const [rfidInput, setRfidInput] = useState('');

  useEffect(() => {
    // In a real app, this would fetch data from the API
    // For now, we'll use mock data
    setTimeout(() => {
      setUsers([
        {
          id: 1,
          username: 'john_doe',
          email: 'john@example.com',
          rfid_uid: 'AB123456',
          active: true,
          isAdmin: true,
          created_at: '2023-01-15T12:00:00Z'
        },
        {
          id: 2,
          username: 'jane_smith',
          email: 'jane@example.com',
          rfid_uid: 'CD789012',
          active: true,
          isAdmin: false,
          created_at: '2023-02-20T14:30:00Z'
        },
        {
          id: 3,
          username: 'bob_johnson',
          email: 'bob@example.com',
          rfid_uid: null,
          active: false,
          isAdmin: false,
          created_at: '2023-03-10T09:15:00Z'
        }
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  const handleEditUser = (user: User) => {
    setCurrentUser(user);
    setShowModal(true);
    setRfidMode(false);
  };

  const handleRfidRegistration = (user: User) => {
    setCurrentUser(user);
    setShowModal(true);
    setRfidMode(true);
    setRfidInput('');
  };

  const handleSaveUser = () => {
    if (!currentUser) return;

    if (rfidMode) {
      // In a real app, this would update the user's RFID in the API
      setUsers(users.map(user => 
        user.id === currentUser.id 
          ? { ...user, rfid_uid: rfidInput } 
          : user
      ));
    } else {
      // In a real app, this would update the user in the API
      setUsers(users.map(user => 
        user.id === currentUser.id 
          ? currentUser 
          : user
      ));
    }
    
    setShowModal(false);
    setCurrentUser(null);
  };

  const handleToggleActive = (userId: number) => {
    // In a real app, this would update the user's active status in the API
    setUsers(users.map(user => 
      user.id === userId 
        ? { ...user, active: !user.active } 
        : user
    ));
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
        <h1 className="text-3xl font-bold text-text">User Management</h1>
        <button 
          className="bg-primary text-white px-4 py-2 rounded-lg shadow hover:bg-blue-700 transition"
          onClick={() => {
            setCurrentUser({
              id: 0,
              username: '',
              email: '',
              rfid_uid: null,
              active: true,
              isAdmin: false,
              created_at: new Date().toISOString()
            });
            setShowModal(true);
            setRfidMode(false);
          }}
        >
          Add New User
        </button>
      </div>
      
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Username
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                RFID
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {users.map(user => (
              <tr key={user.id}>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-text">{user.username}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-500">{user.email}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {user.rfid_uid ? (
                    <div className="text-sm text-gray-500">{user.rfid_uid}</div>
                  ) : (
                    <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">
                      Not Registered
                    </span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    user.active 
                      ? 'bg-green-100 text-green-800' 
                      : 'bg-red-100 text-red-800'
                  }`}>
                    {user.active ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    user.isAdmin 
                      ? 'bg-purple-100 text-purple-800' 
                      : 'bg-blue-100 text-blue-800'
                  }`}>
                    {user.isAdmin ? 'Admin' : 'User'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button 
                    className="text-primary hover:text-blue-700 mr-4"
                    onClick={() => handleEditUser(user)}
                  >
                    Edit
                  </button>
                  <button 
                    className="text-secondary hover:text-red-700 mr-4"
                    onClick={() => handleToggleActive(user.id)}
                  >
                    {user.active ? 'Deactivate' : 'Activate'}
                  </button>
                  <button 
                    className="text-gray-600 hover:text-gray-900"
                    onClick={() => handleRfidRegistration(user)}
                  >
                    {user.rfid_uid ? 'Update RFID' : 'Register RFID'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      
      {/* Modal */}
      {showModal && currentUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg p-6 w-full max-w-md">
            <h2 className="text-2xl font-bold text-text mb-4">
              {rfidMode 
                ? 'RFID Registration' 
                : currentUser.id === 0 ? 'Add New User' : 'Edit User'}
            </h2>
            
            {rfidMode ? (
              <div className="mb-4">
                <label className="block text-gray-700 text-sm font-bold mb-2">
                  RFID UID
                </label>
                <input 
                  type="text" 
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  value={rfidInput}
                  onChange={(e) => setRfidInput(e.target.value)}
                  placeholder="Scan RFID card or enter UID manually"
                />
                <p className="text-sm text-gray-500 mt-2">
                  Place the RFID card on the reader to automatically populate this field.
                </p>
              </div>
            ) : (
              <>
                <div className="mb-4">
                  <label className="block text-gray-700 text-sm font-bold mb-2">
                    Username
                  </label>
                  <input 
                    type="text" 
                    className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                    value={currentUser.username}
                    onChange={(e) => setCurrentUser({...currentUser, username: e.target.value})}
                  />
                </div>
                <div className="mb-4">
                  <label className="block text-gray-700 text-sm font-bold mb-2">
                    Email
                  </label>
                  <input 
                    type="email" 
                    className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                    value={currentUser.email}
                    onChange={(e) => setCurrentUser({...currentUser, email: e.target.value})}
                  />
                </div>
                <div className="mb-4 flex items-center">
                  <input 
                    type="checkbox" 
                    id="isAdmin" 
                    className="mr-2"
                    checked={currentUser.isAdmin}
                    onChange={(e) => setCurrentUser({...currentUser, isAdmin: e.target.checked})}
                  />
                  <label htmlFor="isAdmin" className="text-gray-700 text-sm font-bold">
                    Admin User
                  </label>
                </div>
                <div className="mb-4 flex items-center">
                  <input 
                    type="checkbox" 
                    id="active" 
                    className="mr-2"
                    checked={currentUser.active}
                    onChange={(e) => setCurrentUser({...currentUser, active: e.target.checked})}
                  />
                  <label htmlFor="active" className="text-gray-700 text-sm font-bold">
                    Active
                  </label>
                </div>
              </>
            )}
            
            <div className="flex justify-end">
              <button 
                className="bg-gray-300 text-gray-800 px-4 py-2 rounded-lg mr-2 hover:bg-gray-400 transition"
                onClick={() => {
                  setShowModal(false);
                  setCurrentUser(null);
                }}
              >
                Cancel
              </button>
              <button 
                className="bg-primary text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition"
                onClick={handleSaveUser}
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserManagement; 