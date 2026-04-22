import React, { useEffect, useState } from 'react';
import { Search, Filter, MoreVertical, ExternalLink, Shield, ShieldOff, CreditCard } from 'lucide-react';
import { getDashboardData, updateBusinessStatus } from '../services/api';

const Businesses = () => {
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const load = async () => {
      try {
        const res = await getDashboardData();
        setBusinesses(res.businesses);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const handleToggleStatus = async (uuid, currentStatus) => {
    try {
      await updateBusinessStatus(uuid, !currentStatus);
      const updated = businesses.map(b => 
        b.uuid === uuid ? { ...b, is_active: !currentStatus } : b
      );
      setBusinesses(updated);
    } catch (err) {
      alert('Failed to update status');
    }
  };

  const filtered = businesses.filter(b => {
    const matchesSearch = b.business_name.toLowerCase().includes(search.toLowerCase()) || 
                         b.owner_name.toLowerCase().includes(search.toLowerCase());
    const matchesFilter = filter === 'all' || 
                         (filter === 'active' && b.is_active) || 
                         (filter === 'inactive' && !b.is_active) ||
                         (filter === 'paid' && b.plan === 'PAID') ||
                         (filter === 'free' && b.plan === 'FREE');
    return matchesSearch && matchesFilter;
  });

  if (loading) return <div className="loading">Loading Businesses...</div>;

  return (
    <div className="businesses-page animate-fade-in">
      <header className="page-header">
        <h1 className="gradient-text">Business Management</h1>
        <div className="header-actions">
          <div className="search-bar">
            <Search size={20} className="text-dim" />
            <input 
              type="text" 
              placeholder="Search by name or owner..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <select 
            className="glass-select" 
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="active">Active Only</option>
            <option value="inactive">Inactive Only</option>
            <option value="paid">Paid Plans</option>
            <option value="free">Free Plans</option>
          </select>
        </div>
      </header>

      <div className="glass-card table-card full-width">
        <div className="table-responsive">
          <table>
            <thead>
              <tr>
                <th>Business Name</th>
                <th>Owner Details</th>
                <th>Plan Status</th>
                <th>Revenue</th>
                <th>Created</th>
                <th>System Status</th>
                <th className="text-right">Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(b => (
                <tr key={b.uuid}>
                  <td>
                    <div className="cell-business">
                      <div className="avatar">{(b.business_name || 'B')[0]}</div>
                      <div>
                        <div className="name">{b.business_name}</div>
                        <div className="type">{b.business_type || 'Retail'}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div className="cell-owner">
                      <div className="owner-name">{b.owner_name}</div>
                      <div className="owner-phone text-dim">{b.phone}</div>
                    </div>
                  </td>
                  <td>
                    <div className="plan-badge-container">
                      <span className={`badge plan-${b.plan.toLowerCase()}`}>
                        {b.plan}
                      </span>
                      {b.plan === 'PAID' && <CreditCard size={14} className="text-primary" />}
                    </div>
                  </td>
                  <td>
                    <div className="revenue-cell">
                      <span>₹{b.total_revenue?.toLocaleString()}</span>
                    </div>
                  </td>
                  <td>
                    <div className="date-cell text-dim">
                      {new Date(b.created_at).toLocaleDateString()}
                    </div>
                  </td>
                  <td>
                    <span className={`badge status-${b.is_active ? 'active' : 'inactive'}`}>
                      {b.is_active ? 'Active' : 'Disabled'}
                    </span>
                  </td>
                  <td className="text-right">
                    <button 
                      className={`btn-icon ${b.is_active ? 'text-accent' : 'text-primary'}`}
                      onClick={() => handleToggleStatus(b.uuid, b.is_active)}
                      title={b.is_active ? "Deactivate" : "Activate"}
                    >
                      {b.is_active ? <ShieldOff size={20} /> : <Shield size={20} />}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <style jsx>{`
        .businesses-page {
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
        .header-actions {
          display: flex;
          gap: 1rem;
          align-items: center;
        }
        .glass-select {
          background: rgba(255, 255, 255, 0.05);
          border: 1px solid var(--glass-border);
          color: white;
          padding: 0.6rem 1rem;
          border-radius: 0.75rem;
          outline: none;
        }
        .full-width {
          width: 100%;
        }
        .cell-owner {
          display: flex;
          flex-direction: column;
          gap: 0.2rem;
        }
        .plan-badge-container {
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }
        .text-right { text-align: right; }
        .btn-icon {
          background: transparent;
          border: none;
          cursor: pointer;
          opacity: 0.7;
          transition: opacity 0.2s;
        }
        .btn-icon:hover { opacity: 1; }
      `}</style>
    </div>
  );
};

export default Businesses;
