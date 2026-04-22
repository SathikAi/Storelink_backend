import React, { useEffect, useState } from 'react';
import { Mail, Phone, Calendar, User as UserIcon, Shield, CheckCircle, XCircle } from 'lucide-react';
import { getDashboardData } from '../services/api';

const UsersView = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const load = async () => {
      try {
        const res = await getDashboardData();
        setUsers(res.recent_users);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const filtered = users.filter(u => 
    u.full_name?.toLowerCase().includes(search.toLowerCase()) || 
    u.phone?.toLowerCase().includes(search.toLowerCase())
  );

  if (loading) return <div className="loading">Loading Users...</div>;

  return (
    <div className="users-page animate-fade-in">
      <header className="page-header">
        <h1 className="gradient-text">User Directory</h1>
        <div className="search-bar">
          <input 
            type="text" 
            placeholder="Search users..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </header>

      <div className="users-grid">
        {filtered.map(user => (
          <div key={user.uuid} className="glass-card user-card">
            <div className="user-card-header">
              <div className="user-avatar">
                {user.full_name ? user.full_name[0] : 'U'}
              </div>
              <div className="user-badge">{user.role}</div>
            </div>
            
            <div className="user-body">
              <h3 className="user-name">{user.full_name || 'Anonymous User'}</h3>
              
              <div className="user-meta">
                <div className="meta-item">
                  <Phone size={16} className="text-primary" />
                  <span>{user.phone}</span>
                </div>
                {user.email && (
                  <div className="meta-item">
                    <Mail size={16} className="text-secondary" />
                    <span>{user.email}</span>
                  </div>
                )}
                <div className="meta-item">
                  <Calendar size={16} className="text-accent" />
                  <span>Joined {new Date(user.created_at).toLocaleDateString()}</span>
                </div>
              </div>

              <div className="user-status">
                <div className={`status-indicator ${user.is_active ? 'active' : 'inactive'}`}>
                  {user.is_active ? <CheckCircle size={14} /> : <XCircle size={14} />}
                  <span>{user.is_active ? 'Active Account' : 'Suspended'}</span>
                </div>
                <div className="business-count">
                  {user.business_count || 0} Businesses
                </div>
              </div>
            </div>

            <div className="user-actions">
              <button className="btn-glass text-sm">View Businesses</button>
              <button className="btn-glass text-sm">Reset Password</button>
            </div>
          </div>
        ))}
      </div>

      <style jsx>{`
        .users-page {
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
        .users-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
          gap: 1.5rem;
        }
        .user-card {
          padding: 1.5rem;
          display: flex;
          flex-direction: column;
          gap: 1.25rem;
          transition: transform 0.2s;
        }
        .user-card:hover {
          transform: translateY(-5px);
        }
        .user-card-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
        }
        .user-avatar {
          width: 56px;
          height: 56px;
          background: var(--color-primary);
          border-radius: 1rem;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 1.5rem;
          font-weight: 700;
        }
        .user-badge {
          font-size: 0.7rem;
          text-transform: uppercase;
          letter-spacing: 1px;
          background: rgba(255, 255, 255, 0.1);
          padding: 0.25rem 0.75rem;
          border-radius: 100px;
          color: var(--color-text-dim);
          border: 1px solid var(--color-border);
        }
        .user-name {
          font-size: 1.25rem;
          font-weight: 600;
          margin-bottom: 0.75rem;
        }
        .user-meta {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
        }
        .meta-item {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          font-size: 0.9rem;
          color: var(--color-text-dim);
        }
        .user-status {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding-top: 1rem;
          border-top: 1px solid var(--color-border);
        }
        .status-indicator {
          display: flex;
          align-items: center;
          gap: 0.4rem;
          font-size: 0.8rem;
          font-weight: 600;
        }
        .status-indicator.active { color: #10b981; }
        .status-indicator.inactive { color: #ef4444; }
        .business-count {
          font-size: 0.8rem;
          color: var(--color-text-dim);
        }
        .user-actions {
          display: flex;
          gap: 0.75rem;
        }
        .text-sm { font-size: 0.75rem; flex: 1; }
      `}</style>
    </div>
  );
};

export default UsersView;
