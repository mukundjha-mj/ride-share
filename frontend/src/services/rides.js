import api from './api';

export const rideService = {
    // Get all available rides (not my own)
    async getRides() {
        const response = await api.get('/rides');
        return response.data;
    },

    // Get my posted rides
    async getMyRides() {
        const response = await api.get('/rides/my');
        return response.data;
    },

    // Get single ride details
    async getRide(rideId) {
        const response = await api.get(`/rides/${rideId}`);
        return response.data;
    },

    // Create a new ride
    async createRide(data) {
        const response = await api.post('/rides', data);
        return response.data;
    },

    // Cancel a ride (owner only)
    async cancelRide(rideId) {
        const response = await api.delete(`/rides/${rideId}`);
        return response.data;
    },

    // Request to join a ride
    async joinRide(rideId) {
        const response = await api.post(`/rides/${rideId}/join`);
        return response.data;
    },

    // Get join requests for a ride (owner only)
    async getRideRequests(rideId) {
        const response = await api.get(`/rides/${rideId}/requests`);
        return response.data;
    },

    // Accept a join request
    async acceptRequest(joinId) {
        const response = await api.post(`/join/${joinId}/accept`);
        return response.data;
    },

    // Get my join requests (as requester)
    async getMyRequests() {
        const response = await api.get('/join/my');
        return response.data;
    },
};

export default rideService;
