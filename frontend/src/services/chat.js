import api from './api';

export const chatService = {
    // Get all messages for a join request
    async getMessages(joinId) {
        const response = await api.get(`/join/${joinId}/messages`);
        return response.data;
    },

    // Send a message
    async sendMessage(joinId, message) {
        const response = await api.post(`/join/${joinId}/messages`, { message });
        return response.data;
    },

    // Edit a message
    async editMessage(joinId, messageId, message) {
        const response = await api.put(`/join/${joinId}/messages/${messageId}`, { message });
        return response.data;
    },

    // Delete a message
    async deleteMessage(joinId, messageId) {
        const response = await api.delete(`/join/${joinId}/messages/${messageId}`);
        return response.data;
    },

    // Mark messages as read
    async markAsRead(joinId) {
        const response = await api.post(`/join/${joinId}/read`);
        return response.data;
    },
};

export default chatService;
