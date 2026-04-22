import React, { useState } from 'react';
import { Shield, Key, Database, Bell, Globe, Save, RefreshCw } from 'lucide-react';

const Settings = () => {
  const [activeTab, setActiveTab] = useState('general');
  const [adminKey, setAdminKey] = useState(localStorage.getItem('adminKey') || '');
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = () => {
    setIsSaving(true);
    setTimeout(() => {
      localStorage.setItem('adminKey', adminKey);
      setIsSaving(false);
      alert('Settings saved successfully!');
    }, 1000);
  };

  return (
    <div className="settings-page animate-fade-in">
      <header className="page-header">
        <h1 className="gradient-text">Platform Settings</h1>
        <button 
          className="btn-primary" 
          onClick={handleSave}
          disabled={isSaving}
        >
          {isSaving ? <RefreshCw className="spin" size={20} /> : <Save size={20} />}
          Save Changes
        </button>
      </header>

      <div className="settings-layout">
        <aside className="settings-nav">
          <button 
            className={`settings-nav-item ${activeTab === 'general' ? 'active' : ''}`}
            onClick={() => setActiveTab('general')}
          >
            <Globe size={18} /> General
          </button>
          <button 
            className={`settings-nav-item ${activeTab === 'security' ? 'active' : ''}`}
            onClick={() => setActiveTab('security')}
          >
            <Shield size={18} /> Security
          </button>
          <button 
            className={`settings-nav-item ${activeTab === 'database' ? 'active' : ''}`}
            onClick={() => setActiveTab('database')}
          >
            <Database size={18} /> Infrastructure
          </button>
          <button 
            className={`settings-nav-item ${activeTab === 'notifications' ? 'active' : ''}`}
            onClick={() => setActiveTab('notifications')}
          >
            <Bell size={18} /> Alerts
          </button>
        </aside>

        <div className="settings-content glass-card">
          {activeTab === 'general' && (
            <div className="settings-group">
              <h3>System Information</h3>
              <div className="form-group">
                <label>Platform Name</label>
                <input type="text" className="glass-input" defaultValue="StoreLink" />
              </div>
              <div className="form-group">
                <label>API Endpoint</label>
                <input type="text" className="glass-input" defaultValue="http://localhost:9001/v1" readOnly />
                <p className="help-text">Production API endpoint used by the admin portal.</p>
              </div>
              <div className="form-group">
                <label>CORS Allowed Origins</label>
                <textarea className="glass-input" rows="3" defaultValue="http://localhost:3000, http://localhost:3001" />
              </div>
            </div>
          )}

          {activeTab === 'security' && (
            <div className="settings-group">
              <h3>Security Configuration</h3>
              <div className="form-group">
                <label>Admin Dashboard Key</label>
                <div className="input-with-button">
                  <input 
                    type="password" 
                    className="glass-input" 
                    value={adminKey}
                    onChange={(e) => setAdminKey(e.target.value)}
                  />
                  <button className="btn-glass"><Key size={16} /></button>
                </div>
                <p className="help-text">This key is required for all administrative API requests.</p>
              </div>
              <div className="form-group">
                <label>Session Timeout (mins)</label>
                <input type="number" className="glass-input" defaultValue="60" />
              </div>
            </div>
          )}

          {activeTab === 'database' && (
            <div className="settings-group text-center py-5">
              <Database size={48} className="text-dim mb-3" />
              <h3>Infrastructure Health</h3>
              <p className="text-dim">PostgreSQL Instance is healthy and running.</p>
              <div className="health-grid">
                <div className="health-stat">
                  <span className="label">Connections</span>
                  <span className="value">12/100</span>
                </div>
                <div className="health-stat">
                  <span className="label">Storage Used</span>
                  <span className="value">4.2 GB / 20 GB</span>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div className="settings-group">
              <h3>System Alerts</h3>
              <div className="toggle-group">
                <div className="toggle-item">
                  <div className="toggle-info">
                    <p className="toggle-label">New Store Alert</p>
                    <p className="toggle-desc">Notify when a new business registers.</p>
                  </div>
                  <input type="checkbox" defaultChecked />
                </div>
                <div className="toggle-item">
                  <div className="toggle-info">
                    <p className="toggle-label">Revenue Milestone</p>
                    <p className="toggle-desc">Notify when platform hits revenue targets.</p>
                  </div>
                  <input type="checkbox" defaultChecked />
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      <style jsx>{`
        .settings-page {
          padding: 2rem;
          display: flex;
          flex-direction: column;
          gap: 2rem;
        }
        .page-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .settings-layout {
          display: grid;
          grid-template-columns: 240px 1fr;
          gap: 2rem;
        }
        .settings-nav {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
        }
        .settings-nav-item {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 0.75rem 1rem;
          border-radius: 0.75rem;
          background: transparent;
          color: var(--color-text-dim);
          border: none;
          cursor: pointer;
          text-align: left;
          transition: all 0.2s;
        }
        .settings-nav-item:hover, .settings-nav-item.active {
          background: rgba(255, 255, 255, 0.05);
          color: white;
        }
        .settings-nav-item.active {
          border: 1px solid var(--color-border);
        }
        .settings-content {
          padding: 2.5rem;
        }
        .settings-group h3 {
          margin-bottom: 2rem;
          font-size: 1.5rem;
        }
        .form-group {
          margin-bottom: 1.5rem;
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
        }
        .form-group label {
          font-size: 0.9rem;
          font-weight: 500;
          color: var(--color-text-dim);
        }
        .glass-input {
          background: rgba(255, 255, 255, 0.05);
          border: 1px solid var(--glass-border);
          padding: 0.75rem 1rem;
          border-radius: 0.75rem;
          color: white;
          outline: none;
        }
        .help-text {
          font-size: 0.8rem;
          color: var(--color-text-dim);
        }
        .input-with-button {
          display: flex;
          gap: 0.5rem;
        }
        .input-with-button .glass-input { flex: 1; }
        .toggle-group {
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
        }
        .toggle-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .toggle-label { font-weight: 600; }
        .toggle-desc { font-size: 0.85rem; color: var(--color-text-dim); }
        .health-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 1rem;
          margin-top: 2rem;
        }
        .health-stat {
          background: rgba(255, 255, 255, 0.03);
          padding: 1rem;
          border-radius: 0.75rem;
          display: flex;
          flex-direction: column;
        }
        .health-stat .label { font-size: 0.8rem; color: var(--color-text-dim); }
        .health-stat .value { font-size: 1.25rem; font-weight: 700; }
        
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        .spin { animation: spin 1s linear infinite; }
        .mb-3 { margin-bottom: 1rem; }
        .py-5 { padding-top: 3rem; padding-bottom: 3rem; }
        .text-center { text-align: center; }
      `}</style>
    </div>
  );
};

export default Settings;
