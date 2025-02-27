import React from 'react';
import { Link } from 'react-router-dom';

const NotFound: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="text-center">
        <h1 className="text-9xl font-bold text-primary">404</h1>
        <h2 className="text-3xl font-semibold text-text mt-4">Page Not Found</h2>
        <p className="text-gray-500 mt-2 mb-6">The page you are looking for doesn't exist or has been moved.</p>
        <Link 
          to="/" 
          className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-blue-700 transition"
        >
          Go to Dashboard
        </Link>
      </div>
    </div>
  );
};

export default NotFound; 