import React, { useState } from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { 
  UserGroupIcon, 
  ChartBarIcon, 
  PlayIcon,
  HomeIcon,
  UserCircleIcon,
  ArrowRightOnRectangleIcon,
  Cog6ToothIcon
} from '@heroicons/react/24/solid';

const MainLayout = () => {
  const location = useLocation();
  const [showUserMenu, setShowUserMenu] = useState(false);
  
  const isActive = (path: string) => {
    return location.pathname === path ? 'bg-primary text-white' : 'text-text hover:bg-gray-100';
  };

  return (
    <div className="min-h-screen bg-background flex">
      {/* Sidebar */}
      <div className="w-64 bg-white shadow-lg">
        <div className="p-4 border-b border-gray-200">
          <h1 className="text-2xl font-bold text-primary">ClassServer</h1>
        </div>
        <nav className="mt-4">
          <ul>
            <li>
              <Link 
                to="/" 
                className={`flex items-center p-3 mx-2 mb-2 rounded-lg ${isActive('/')}`}
              >
                <HomeIcon className="w-5 h-5 mr-2" />
                Dashboard
              </Link>
            </li>
            <li>
              <Link 
                to="/users" 
                className={`flex items-center p-3 mx-2 mb-2 rounded-lg ${isActive('/users')}`}
              >
                <UserGroupIcon className="w-5 h-5 mr-2" />
                User Management
              </Link>
            </li>
            <li>
              <Link 
                to="/games" 
                className={`flex items-center p-3 mx-2 mb-2 rounded-lg ${isActive('/games')}`}
              >
                <PlayIcon className="w-5 h-5 mr-2" />
                Game Overview
              </Link>
            </li>
            <li>
              <Link 
                to="/stats" 
                className={`flex items-center p-3 mx-2 mb-2 rounded-lg ${isActive('/stats')}`}
              >
                <ChartBarIcon className="w-5 h-5 mr-2" />
                Statistics
              </Link>
            </li>
          </ul>
        </nav>
      </div>
      
      {/* Main content */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <header className="bg-white shadow-sm">
          <div className="flex justify-end items-center p-4">
            <div className="relative">
              <button 
                className="flex items-center text-text hover:text-primary focus:outline-none"
                onClick={() => setShowUserMenu(!showUserMenu)}
              >
                <span className="mr-2">John Doe</span>
                <UserCircleIcon className="w-8 h-8" />
              </button>
              
              {showUserMenu && (
                <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-10">
                  <Link 
                    to="/profile" 
                    className="block px-4 py-2 text-sm text-text hover:bg-gray-100"
                    onClick={() => setShowUserMenu(false)}
                  >
                    <div className="flex items-center">
                      <UserCircleIcon className="w-4 h-4 mr-2" />
                      My Profile
                    </div>
                  </Link>
                  <Link 
                    to="/settings" 
                    className="block px-4 py-2 text-sm text-text hover:bg-gray-100"
                    onClick={() => setShowUserMenu(false)}
                  >
                    <div className="flex items-center">
                      <Cog6ToothIcon className="w-4 h-4 mr-2" />
                      Settings
                    </div>
                  </Link>
                  <div className="border-t border-gray-100 my-1"></div>
                  <Link 
                    to="/auth/login" 
                    className="block px-4 py-2 text-sm text-text hover:bg-gray-100"
                    onClick={() => setShowUserMenu(false)}
                  >
                    <div className="flex items-center">
                      <ArrowRightOnRectangleIcon className="w-4 h-4 mr-2" />
                      Sign out
                    </div>
                  </Link>
                </div>
              )}
            </div>
          </div>
        </header>
        
        {/* Page content */}
        <div className="flex-1 p-8">
          <Outlet />
        </div>
      </div>
    </div>
  );
};

export default MainLayout; 