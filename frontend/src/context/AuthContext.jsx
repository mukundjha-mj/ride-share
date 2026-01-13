import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import authService from '@/services/auth';
import socketService from '@/services/socket';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    // Check for existing auth on mount
    useEffect(() => {
        const initAuth = async () => {
            const token = authService.getToken();
            if (token) {
                try {
                    const response = await authService.getMe();
                    if (response.success) {
                        setUser(response.data.user);
                        socketService.connect();
                    }
                } catch (err) {
                    console.error('Auth init error:', err);
                    authService.clearToken();
                }
            }
            setLoading(false);
        };

        initAuth();
    }, []);

    const login = useCallback(async (email, password) => {
        setError(null);
        try {
            const response = await authService.login(email, password);
            if (response.success) {
                authService.setToken(response.data.token);
                setUser(response.data.user);
                socketService.connect();
                return { success: true };
            }
            return { success: false, message: response.message };
        } catch (err) {
            const message = err.response?.data?.message || 'Login failed';
            setError(message);
            return { success: false, message };
        }
    }, []);

    const register = useCallback(async (name, email, password) => {
        setError(null);
        try {
            const response = await authService.register(name, email, password);
            if (response.success) {
                authService.setToken(response.data.token);
                setUser(response.data.user);
                socketService.connect();
                return { success: true };
            }
            return { success: false, message: response.message };
        } catch (err) {
            const message = err.response?.data?.message || 'Registration failed';
            setError(message);
            return { success: false, message };
        }
    }, []);

    const logout = useCallback(() => {
        authService.clearToken();
        socketService.disconnect();
        setUser(null);
    }, []);

    const updateProfile = useCallback(async (data) => {
        try {
            const response = await authService.updateProfile(data);
            if (response.success) {
                setUser(response.data.user);
                return { success: true };
            }
            return { success: false, message: response.message };
        } catch (err) {
            const message = err.response?.data?.message || 'Update failed';
            return { success: false, message };
        }
    }, []);

    const value = {
        user,
        loading,
        error,
        isAuthenticated: !!user,
        login,
        register,
        logout,
        updateProfile,
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
}

export default AuthContext;
