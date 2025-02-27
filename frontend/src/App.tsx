import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AuthLayout from './components/layouts/AuthLayout';
import Register from './pages/auth/Register';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<AuthLayout />}>
          <Route path="register" element={<Register />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App; 