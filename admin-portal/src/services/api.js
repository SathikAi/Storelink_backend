import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/v1';

const api = axios.create({
  baseURL: API_BASE_URL,
});

// Set the admin key for all requests
export const setAdminKey = (key) => {
  api.defaults.headers.common['X-Admin-Key'] = key;
  localStorage.setItem('adminKey', key);
};

// Initialize from localStorage if exists
const savedKey = localStorage.getItem('adminKey');
if (savedKey) {
  api.defaults.headers.common['X-Admin-Key'] = savedKey;
}

export const getDashboardData = async () => {
  const response = await api.get('/admin/dashboard-data');
  return response.data;
};

export const updateBusinessStatus = async (uuid, isActive) => {
  const response = await api.patch(`/admin/businesses/${uuid}/status`, { is_active: isActive });
  return response.data;
};

export const updateBusinessPlan = async (uuid, plan) => {
  const response = await api.patch(`/admin/businesses/${uuid}/plan`, { plan });
  return response.data;
};

export default api;
