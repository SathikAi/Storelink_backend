import React, { useEffect, useState } from 'react';
import { 
  Users, 
  Store, 
  CreditCard, 
  TrendingUp, 
  Search, 
  MoreVertical,
  CheckCircle,
  XCircle,
  Clock
} from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  AreaChart,
  Area
} from 'recharts';
import { getDashboardData, updateBusinessStatus } from '../services/api';

const Dashboard = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await getDashboardData();
      setData(res);
      setError(null);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to fetch dashboard data. Check your admin key.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleToggleStatus = async (uuid, currentStatus) => {
    try {
      await updateBusinessStatus(uuid, !currentStatus);
      loadData();
    } catch (err) {
      alert('Failed to update status');
    }
  };

  if (loading) return <div className="loading">Loading Dashboard...</div>;
  if (error) return <div className="error-container">
    <h2>Access Denied</h2>
    <p>{error}</p>
    <button className="btn-primary" onClick={() => window.location.reload()}>Retry</button>
  </div>;

  const { stats, businesses, recent_users, pagination } = data;

  // Transform plan distribution for chart
  const planData = [
    { name: 'Free', value: stats.free_plan_businesses || 0 },
    { name: 'Paid', value: stats.paid_plan_businesses || 0 },
  ];

  const filteredBusinesses = businesses.filter(b => 
    b.business_name.toLowerCase().includes(search.toLowerCase()) || 
    b.owner_name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="dashboard-page animate-fade-in">
      <header className="dashboard-header">
        <div>
          <h1 className="gradient-text">Platform Overview</h1>
          <p className="text-dim">Welcome back, Admin</p>
        </div>
        <div className="search-bar">
          <Search size={20} className="text-dim" />
          <input 
            type="text" 
            placeholder="Search businesses..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </header>

      {/* Stat Cards */}
      <div className="stats-grid">
        <StatCard 
          icon={<Store className="text-primary" />} 
          label="Total Businesses" 
          value={stats.total_businesses} 
          subtext={`Active: ${stats.active_businesses}`}
        />
        <StatCard 
          icon={<CreditCard className="text-secondary" />} 
          label="Total Revenue" 
          value={`₹${stats.total_revenue.toLocaleString()}`} 
          subtext={`Month: ₹${stats.revenue_this_month.toLocaleString()}`}
        />
        <StatCard 
          icon={<Users className="text-accent" />} 
          label="Conversion Rate" 
          value={`${stats.conversion_rate}%`} 
          subtext={`${stats.businesses_with_orders} ordering shops`}
        />
        <StatCard 
          icon={<TrendingUp id="trending-icon" color="#10b981" />} 
          label="Total Products" 
          value={stats.total_products} 
          subtext={`${stats.total_orders} total orders`}
        />
      </div>

      <div className="content-grid">
        {/* Main Table */}
        <div className="glass-card table-card">
          <div className="card-header">
            <h3>Registered Businesses</h3>
            <button className="btn-glass">Export CSV</button>
          </div>
          <div className="table-responsive">
            <table>
              <thead>
                <tr>
                  <th>Business</th>
                  <th>Owner</th>
                  <th>Plan</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredBusinesses.map(b => (
                  <tr key={b.uuid}>
                    <td>
                      <div className="cell-business">
                        <div className="avatar">{(b.business_name || 'B')[0]}</div>
                        <div>
                          <div className="name">{b.business_name}</div>
                          <div className="type">{b.business_type}</div>
                        </div>
                      </div>
                    </td>
                    <td>{b.owner_name}</td>
                    <td>
                      <span className={`badge plan-${b.plan.toLowerCase()}`}>
                        {b.plan}
                      </span>
                    </td>
                    <td>
                      <span className={`badge status-${b.is_active ? 'active' : 'inactive'}`}>
                        {b.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>
                      <button 
                        className="btn-status-toggle"
                        onClick={() => handleToggleStatus(b.uuid, b.is_active)}
                      >
                        {b.is_active ? <XCircle size={18} /> : <CheckCircle size={18} />}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Charts Side */}
        <div className="charts-side">
          <div className="glass-card chart-card">
            <h3>Plan Distribution</h3>
            <div className="chart-container">
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={planData}>
                  <XAxis dataKey="name" stroke="#94a3b8" />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '8px' }}
                    itemStyle={{ color: '#fff' }}
                  />
                  <Bar dataKey="value" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="glass-card recent-card">
            <h3>Recent Users</h3>
            <div className="user-list">
              {recent_users.map(u => (
                <div key={u.uuid} className="user-item">
                  <div className="user-info">
                    <p className="user-name">{u.full_name || 'Unnamed User'}</p>
                    <p className="user-phone">{u.phone}</p>
                  </div>
                  <div className="user-role badge">{u.role}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const StatCard = ({ icon, label, value, subtext }) => (
  <div className="glass-card stat-card">
    <div className="stat-icon">{icon}</div>
    <div className="stat-content">
      <p className="stat-label">{label}</p>
      <div className="stat-value">{value}</div>
      <p className="stat-subtext">{subtext}</p>
    </div>
  </div>
);

export default Dashboard;
