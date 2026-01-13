import api from './api';

export const authService = {
    async register(name, email, password) {
        const response = await api.post('/auth/register', { name, email, password });
        return response.data;
    },

    async login(email, password) {
        const response = await api.post('/auth/login', { email, password });
        return response.data;
    },

    async getMe() {
        const response = await api.get('/auth/me');
        return response.data;
    },

    async updateProfile(data) {
        const response = await api.patch('/auth/profile', data);
        return response.data;
    },

    setToken(token) {
        localStorage.setItem('auth_token', token);
    },

    getToken() {
        return localStorage.getItem('auth_token');
    },

    clearToken() {
        localStorage.removeItem('auth_token');
    },

    isAuthenticated() {
        return !!this.getToken();
    },
};

export default authService;
