import React, { useState } from 'react';

const Settings: React.FC = () => {
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [darkMode, setDarkMode] = useState(false);
  const [language, setLanguage] = useState('en');
  const [message, setMessage] = useState({ text: '', type: '' });

  const handleSaveSettings = () => {
    // In a real app, this would save settings to the API
    setMessage({ text: 'Settings saved successfully!', type: 'success' });
    
    // Clear message after 3 seconds
    setTimeout(() => setMessage({ text: '', type: '' }), 3000);
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-text mb-8">Settings</h1>
      
      {message.text && (
        <div className={`p-4 mb-6 rounded-lg ${
          message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
        }`}>
          {message.text}
        </div>
      )}
      
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-text mb-6">Account Settings</h2>
        
        <div className="space-y-6">
          {/* Notifications */}
          <div>
            <h3 className="text-lg font-medium text-text mb-3">Notifications</h3>
            <div className="flex items-center">
              <input
                id="email-notifications"
                type="checkbox"
                className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                checked={emailNotifications}
                onChange={(e) => setEmailNotifications(e.target.checked)}
              />
              <label htmlFor="email-notifications" className="ml-2 block text-sm text-gray-700">
                Receive email notifications
              </label>
            </div>
            <p className="text-sm text-gray-500 mt-1">
              Get notified about game results, new challenges, and system updates.
            </p>
          </div>
          
          {/* Appearance */}
          <div>
            <h3 className="text-lg font-medium text-text mb-3">Appearance</h3>
            <div className="flex items-center">
              <input
                id="dark-mode"
                type="checkbox"
                className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                checked={darkMode}
                onChange={(e) => setDarkMode(e.target.checked)}
              />
              <label htmlFor="dark-mode" className="ml-2 block text-sm text-gray-700">
                Dark mode
              </label>
            </div>
            <p className="text-sm text-gray-500 mt-1">
              Switch between light and dark theme.
            </p>
          </div>
          
          {/* Language */}
          <div>
            <h3 className="text-lg font-medium text-text mb-3">Language</h3>
            <select
              className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary focus:border-primary sm:text-sm rounded-md"
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
            >
              <option value="en">English</option>
              <option value="no">Norwegian</option>
              <option value="sv">Swedish</option>
              <option value="da">Danish</option>
            </select>
            <p className="text-sm text-gray-500 mt-1">
              Select your preferred language for the interface.
            </p>
          </div>
          
          {/* Security */}
          <div>
            <h3 className="text-lg font-medium text-text mb-3">Security</h3>
            <button
              className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition"
            >
              Change Password
            </button>
          </div>
        </div>
        
        <div className="mt-8 flex justify-end">
          <button
            className="bg-primary text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition"
            onClick={handleSaveSettings}
          >
            Save Settings
          </button>
        </div>
      </div>
    </div>
  );
};

export default Settings; 