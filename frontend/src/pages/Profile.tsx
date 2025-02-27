import React, { useState, useEffect } from 'react';
import axios from 'axios';

interface UserProfile {
  id: number;
  username: string;
  email: string;
  rfid_uid: string | null;
  isAdmin: boolean;
  created_at: string;
  foosball_elo: number;
  chess_elo: number;
}

const Profile: React.FC = () => {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editedProfile, setEditedProfile] = useState<UserProfile | null>(null);
  const [message, setMessage] = useState({ text: '', type: '' });

  useEffect(() => {
    // In a real app, this would fetch data from the API
    // For now, we'll use mock data
    setTimeout(() => {
      const mockProfile: UserProfile = {
        id: 1,
        username: 'john_doe',
        email: 'john@example.com',
        rfid_uid: 'AB123456',
        isAdmin: true,
        created_at: '2023-01-15T12:00:00Z',
        foosball_elo: 1345,
        chess_elo: 1250
      };
      
      setProfile(mockProfile);
      setEditedProfile(mockProfile);
      setLoading(false);
    }, 1000);
  }, []);

  const handleEditToggle = () => {
    if (isEditing && profile !== editedProfile) {
      // Confirm before discarding changes
      if (window.confirm('Discard unsaved changes?')) {
        setEditedProfile(profile);
        setIsEditing(false);
      }
    } else {
      setIsEditing(!isEditing);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!editedProfile) return;
    
    const { name, value } = e.target;
    setEditedProfile({
      ...editedProfile,
      [name]: value
    });
  };

  const handleSaveProfile = async () => {
    if (!editedProfile) return;
    
    setLoading(true);
    
    try {
      // In a real app, this would update the profile via API
      // For now, we'll just simulate a successful update
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setProfile(editedProfile);
      setIsEditing(false);
      setMessage({ text: 'Profile updated successfully!', type: 'success' });
      
      // Clear message after 3 seconds
      setTimeout(() => setMessage({ text: '', type: '' }), 3000);
    } catch (error) {
      setMessage({ text: 'Failed to update profile. Please try again.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString();
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="text-center py-8">
        <p className="text-red-500">Failed to load profile. Please try again later.</p>
      </div>
    );
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-text">My Profile</h1>
        <button 
          className={`px-4 py-2 rounded-lg shadow ${
            isEditing 
              ? 'bg-gray-300 text-gray-800 hover:bg-gray-400' 
              : 'bg-primary text-white hover:bg-blue-700'
          } transition`}
          onClick={handleEditToggle}
        >
          {isEditing ? 'Cancel' : 'Edit Profile'}
        </button>
      </div>
      
      {message.text && (
        <div className={`p-4 mb-6 rounded-lg ${
          message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
        }`}>
          {message.text}
        </div>
      )}
      
      <div className="bg-white rounded-lg shadow p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h2 className="text-xl font-semibold text-text mb-4">Account Information</h2>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Username
                </label>
                {isEditing ? (
                  <input
                    type="text"
                    name="username"
                    className="shadow-sm focus:ring-primary focus:border-primary block w-full sm:text-sm border-gray-300 rounded-md"
                    value={editedProfile?.username || ''}
                    onChange={handleInputChange}
                  />
                ) : (
                  <p className="text-text">{profile.username}</p>
                )}
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email
                </label>
                {isEditing ? (
                  <input
                    type="email"
                    name="email"
                    className="shadow-sm focus:ring-primary focus:border-primary block w-full sm:text-sm border-gray-300 rounded-md"
                    value={editedProfile?.email || ''}
                    onChange={handleInputChange}
                  />
                ) : (
                  <p className="text-text">{profile.email}</p>
                )}
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  RFID UID
                </label>
                <p className="text-text">
                  {profile.rfid_uid || (
                    <span className="text-yellow-500">Not registered</span>
                  )}
                </p>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Account Type
                </label>
                <p className="text-text">
                  <span className={`px-2 py-1 rounded-full text-xs font-semibold ${
                    profile.isAdmin 
                      ? 'bg-purple-100 text-purple-800' 
                      : 'bg-blue-100 text-blue-800'
                  }`}>
                    {profile.isAdmin ? 'Admin' : 'User'}
                  </span>
                </p>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Member Since
                </label>
                <p className="text-text">{formatDate(profile.created_at)}</p>
              </div>
            </div>
          </div>
          
          <div>
            <h2 className="text-xl font-semibold text-text mb-4">Game Statistics</h2>
            
            <div className="space-y-6">
              <div className="bg-gray-50 p-4 rounded-lg">
                <h3 className="font-medium text-text mb-2">Foosball</h3>
                <div className="flex items-center">
                  <div className="text-3xl font-bold text-primary mr-2">{profile.foosball_elo}</div>
                  <div className="text-sm text-gray-500">Elo Rating</div>
                </div>
              </div>
              
              <div className="bg-gray-50 p-4 rounded-lg">
                <h3 className="font-medium text-text mb-2">Chess</h3>
                <div className="flex items-center">
                  <div className="text-3xl font-bold text-secondary mr-2">{profile.chess_elo}</div>
                  <div className="text-sm text-gray-500">Elo Rating</div>
                </div>
              </div>
              
              <div className="mt-4">
                <a href="/stats" className="text-primary hover:text-blue-700 text-sm font-medium">
                  View detailed statistics →
                </a>
              </div>
            </div>
          </div>
        </div>
        
        {isEditing && (
          <div className="mt-6 flex justify-end">
            <button
              className="bg-primary text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition"
              onClick={handleSaveProfile}
            >
              Save Changes
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default Profile; 