import React, { useState } from 'react';
import Dashboard from './pages/Dashboard';
import Businesses from './pages/Businesses';
import UsersView from './pages/Users';
import Settings from './pages/Settings';
import './styles/Dashboard.css';
import { setAdminKey } from './services/api';
import { Key, LayoutDashboard, Store, Users, Settings as SettingsIcon, LogOut } from 'lucide-react';

function App() {
  const [hasKey, setHasKey] = useState(!!localStorage.getItem('adminKey'));
  const [inputKey, setInputKey] = useState('');
  const [currentView, setCurrentView] = useState('dashboard');

  const handleLogin = (e) => {
    e.preventDefault();
    if (inputKey.trim()) {
      setAdminKey(inputKey);
      setHasKey(true);
    }
  };

  const logout = () => {
    localStorage.removeItem('adminKey');
    window.location.reload();
  };

  const renderView = () => {
    switch (currentView) {
      case 'dashboard': return <Dashboard />;
      case 'businesses': return <Businesses />;
      case 'users': return <UsersView />;
      case 'settings': return <Settings />;
      default: return <Dashboard />;
    }
  };

  if (!hasKey) {
    return (
      <div className="login-overlay">
        <div className="glass-card login-card animate-fade-in">
          <div className="login-icon">
            <Key size={40} className="text-primary" />
          </div>
          <h2 className="gradient-text">Admin Portal</h2>
          <p className="text-dim">Enter your secret admin key to access the dashboard</p>
          <form onSubmit={handleLogin}>
            <input 
              type="password" 
              placeholder="Admin Secret Key" 
              value={inputKey}
              onChange={(e) => setInputKey(e.target.value)}
              className="glass-input"
            />
            <button type="submit" className="btn-primary w-full">
              Access Dashboard
            </button>
          </form>
          <p className="hint">Hint: check settings.ADMIN_DASHBOARD_KEY</p>
        </div>
        
        <style>{`
          .login-overlay {
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--color-bg-deep);
          }
          .login-card {
            padding: 3rem;
            width: 100%;
            max-width: 450px;
            text-align: center;
            display: flex;
            flex-direction: column;
            gap: 1.5rem;
          }
          .login-icon {
            margin: 0 auto;
            width: 80px;
            height: 80px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 2rem;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .glass-input {
            width: 100%;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--glass-border);
            padding: 1rem;
            border-radius: 0.75rem;
            color: white;
            margin-bottom: 1rem;
            outline: none;
          }
          .w-full { width: 100%; justify-content: center; }
          .hint { font-size: 0.75rem; color: var(--color-text-dim); }
        `}</style>
      </div>
    );
  }

  return (
    <div className="app-container">
      <nav className="side-nav">
        <div className="logo-container">
          <div className="logo-icon">S</div>
          <span className="logo-text">StoreLink</span>
        </div>
        <div className="nav-items">
          <NavItem 
            id="dashboard" 
            icon={<LayoutDashboard size={20} />} 
            label="Dashboard" 
            active={currentView === 'dashboard'} 
            onClick={setCurrentView} 
          />
          <NavItem 
            id="businesses" 
            icon={<Store size={20} />} 
            label="Businesses" 
            active={currentView === 'businesses'} 
            onClick={setCurrentView} 
          />
          <NavItem 
            id="users" 
            icon={<Users size={20} />} 
            label="Users" 
            active={currentView === 'users'} 
            onClick={setCurrentView} 
          />
          <NavItem 
            id="settings" 
            icon={<SettingsIcon size={20} />} 
            label="Settings" 
            active={currentView === 'settings'} 
            onClick={setCurrentView} 
          />
        </div>
        <button className="logout-btn" onClick={logout}>
          <LogOut size={18} /> Logout
        </button>
      </nav>
      
      <main className="main-content">
        {renderView()}
      </main>

      <style>{`
        .app-container {
          display: flex;
          min-height: 100vh;
          background: var(--color-bg-deep);
        }
        .side-nav {
          width: 260px;
          background: rgba(15, 23, 42, 0.9);
          border-right: 1px solid var(--color-border);
          display: flex;
          flex-direction: column;
          padding: 2rem 1.5rem;
          position: sticky;
          top: 0;
          height: 100vh;
          backdrop-filter: blur(10px);
        }
        .logo-container {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          margin-bottom: 3rem;
          padding-left: 0.5rem;
        }
        .logo-icon {
          width: 32px;
          height: 32px;
          background: linear-gradient(135deg, var(--color-primary), var(--color-secondary));
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 900;
          color: white;
        }
        .logo-text {
          font-weight: 700;
          font-size: 1.25rem;
          letter-spacing: -0.5px;
          background: linear-gradient(to right, white, #94a3b8);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        .nav-items {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
          flex: 1;
        }
        .nav-link {
          display: flex;
          align-items: center;
          gap: 1rem;
          padding: 0.75rem 1rem;
          border-radius: 0.75rem;
          color: var(--color-text-dim);
          cursor: pointer;
          transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
          border: 1px solid transparent;
        }
        .nav-link:hover {
          background: rgba(255, 255, 255, 0.05);
          color: white;
        }
        .nav-link.active {
          background: rgba(59, 130, 246, 0.1);
          color: var(--color-primary);
          border-color: rgba(59, 130, 246, 0.2);
        }
        .main-content {
          flex: 1;
          height: 100vh;
          overflow-y: auto;
          background: radial-gradient(circle at top right, rgba(59, 130, 246, 0.05), transparent);
        }
        .logout-btn {
          margin-top: auto;
          background: transparent;
          color: var(--color-accent);
          font-size: 0.9rem;
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 1rem;
          border-radius: 0.75rem;
          transition: background 0.2s;
        }
        .logout-btn:hover {
          background: rgba(239, 68, 68, 0.05);
        }
      `}</style>
    </div>
  );
}

const NavItem = ({ id, icon, label, active, onClick }) => (
  <div 
    className={`nav-link ${active ? 'active' : ''}`} 
    onClick={() => onClick(id)}
  >
    {icon}
    <span>{label}</span>
  </div>
);

export default App;
