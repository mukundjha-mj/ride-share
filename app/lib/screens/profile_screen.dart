import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate name
    if (name.length < 2) {
      _showError('Name must be at least 2 characters');
      return;
    }

    // Validate password if changing
    if (_showPasswordFields && newPassword.isNotEmpty) {
      if (currentPassword.isEmpty) {
        _showError('Please enter your current password');
        return;
      }
      if (newPassword.length < 6) {
        _showError('New password must be at least 6 characters');
        return;
      }
      if (newPassword != confirmPassword) {
        _showError('Passwords do not match');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{'name': name};

      if (_showPasswordFields && newPassword.isNotEmpty) {
        body['currentPassword'] = currentPassword;
        body['newPassword'] = newPassword;
      }

      final response = await _api.patch(ApiConfig.updateProfile, body);

      if (response != null && response['success'] == true) {
        // Refresh user data
        await context.read<AuthProvider>().initialize();

        if (mounted) {
          _showSuccess('Profile updated successfully');
          // Clear password fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          setState(() => _showPasswordFields = false);
        }
      } else {
        _showError(response?['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('An error occurred');
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<RideProvider>().clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user?.name ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Email (read-only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppTheme.textHint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.lock_outline,
                    color: AppTheme.textHint,
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name (editable)
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),

            // Change password toggle
            InkWell(
              onTap: () =>
                  setState(() => _showPasswordFields = !_showPasswordFields),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Change Password')),
                    Icon(
                      _showPasswordFields
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppTheme.textHint,
                    ),
                  ],
                ),
              ),
            ),

            // Password fields
            if (_showPasswordFields) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
