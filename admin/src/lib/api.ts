import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:8000/api',
  headers: {
    'Accept': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const comicApi = {
  getAll: () => api.get('/comics'),
  getById: (id: number) => api.get(`/comics/${id}`),
  create: (data: any) => api.post('/comics', data),
  update: (id: number, data: any) => api.put(`/comics/${id}`, data),
  delete: (id: number) => api.delete(`/comics/${id}`),
};

export const adminApi = {
  getStats: () => api.get('/admin/dashboard'),
  // User Management
  getUsers: () => api.get('/admin/users'),
  createUser: (data: any) => api.post('/admin/users', data),
  updateUser: (id: number, data: any) => api.put(`/admin/users/${id}`, data),
  deleteUser: (id: number) => api.delete(`/admin/users/${id}`),
  // Notification Management
  getNotifications: () => api.get('/admin/notifications'),
  createNotification: (data: any) => api.post('/admin/notifications', data),
  deleteNotification: (id: number) => api.delete(`/admin/notifications/${id}`),
  // Comic Management
  getComics: () => api.get('/admin/comics'),
  createComic: (data: any) => api.post('/admin/comics', data),
  updateComic: (id: number, data: any) => {
    if (data instanceof FormData) {
      data.append('_method', 'PUT');
      return api.post(`/admin/comics/${id}`, data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    }
    return api.put(`/admin/comics/${id}`, data);
  },
  deleteComic: (id: number) => api.delete(`/admin/comics/${id}`),
  // Episode Management
  getEpisodes: (comicId: number) => api.get(`/admin/comics/${comicId}/episodes`),
  createEpisode: (comicId: number, data: any) => api.post(`/admin/comics/${comicId}/episodes`, data),
  updateEpisode: (episodeId: number, data: any) => api.put(`/admin/episodes/${episodeId}`, data),
  deleteEpisode: (episodeId: number) => api.delete(`/admin/episodes/${episodeId}`),
  // Panel Management
  getPanels: (episodeId: number) => api.get(`/admin/episodes/${episodeId}/panels`),
  createPanels: (episodeId: number, data: FormData) => api.post(`/admin/episodes/${episodeId}/panels`, data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  deletePanel: (panelId: number) => api.delete(`/admin/panels/${panelId}`),
  reorderPanels: (episodeId: number, panelIds: number[]) => api.put(`/admin/episodes/${episodeId}/panels/reorder`, { panel_ids: panelIds }),
};

export default api;
