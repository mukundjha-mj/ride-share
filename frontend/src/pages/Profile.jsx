import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sun, Moon, User, Lock, LogOut, Pencil } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import { useTheme } from '@/context/ThemeContext';
import { PageLayout } from '@/components/layout/Layout';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from '@/components/ui/dialog';
import toast from 'react-hot-toast';

export function Profile() {
    const navigate = useNavigate();
    const { user, logout, updateProfile } = useAuth();
    const { theme, toggleTheme } = useTheme();

    const [showEditName, setShowEditName] = useState(false);
    const [showChangePassword, setShowChangePassword] = useState(false);
    const [name, setName] = useState(user?.name || '');
    const [currentPassword, setCurrentPassword] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [loading, setLoading] = useState(false);

    const handleUpdateName = async () => {
        if (name.trim().length < 2) {
            toast.error('Name must be at least 2 characters');
            return;
        }

        setLoading(true);
        const result = await updateProfile({ name: name.trim() });
        setLoading(false);

        if (result.success) {
            toast.success('Name updated!');
            setShowEditName(false);
        } else {
            toast.error(result.message || 'Failed to update name');
        }
    };

    const handleChangePassword = async () => {
        if (!currentPassword) {
            toast.error('Current password is required');
            return;
        }
        if (newPassword.length < 6) {
            toast.error('New password must be at least 6 characters');
            return;
        }
        if (newPassword !== confirmPassword) {
            toast.error('Passwords do not match');
            return;
        }

        setLoading(true);
        const result = await updateProfile({ currentPassword, newPassword });
        setLoading(false);

        if (result.success) {
            toast.success('Password changed!');
            setShowChangePassword(false);
            setCurrentPassword('');
            setNewPassword('');
            setConfirmPassword('');
        } else {
            toast.error(result.message || 'Failed to change password');
        }
    };

    const handleLogout = () => {
        logout();
        navigate('/login');
        toast.success('Logged out successfully');
    };

    return (
        <PageLayout title="Profile" showBack>
            {/* Profile Header Card */}
            <Card className="mb-6 overflow-hidden">
                <CardContent className="p-0">
                    <div className="bg-gradient-to-r from-primary-500 to-secondary-500 h-24" />
                    <div className="px-6 pb-6 -mt-12">
                        <Avatar className="h-24 w-24 ring-4 ring-white dark:ring-slate-800 shadow-xl">
                            <AvatarFallback className="text-3xl bg-gradient-to-br from-primary-400 to-primary-600">
                                {user?.name?.charAt(0).toUpperCase() || '?'}
                            </AvatarFallback>
                        </Avatar>
                        <h2 className="text-2xl font-bold mt-4 mb-1">{user?.name}</h2>
                        <p className="text-slate-500 dark:text-slate-400">{user?.email}</p>
                    </div>
                </CardContent>
            </Card>

            {/* Settings Grid */}
            <div className="grid gap-3 sm:grid-cols-2">
                <Card className="overflow-hidden">
                    <button
                        className="w-full p-4 flex items-center gap-4 text-left hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                        onClick={() => setShowEditName(true)}
                    >
                        <div className="w-12 h-12 rounded-2xl bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center">
                            <Pencil className="h-5 w-5 text-primary-600 dark:text-primary-400" />
                        </div>
                        <div>
                            <p className="font-medium">Edit Name</p>
                            <p className="text-sm text-slate-500">Update your display name</p>
                        </div>
                    </button>
                </Card>

                <Card className="overflow-hidden">
                    <button
                        className="w-full p-4 flex items-center gap-4 text-left hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                        onClick={() => setShowChangePassword(true)}
                    >
                        <div className="w-12 h-12 rounded-2xl bg-secondary-100 dark:bg-secondary-900/30 flex items-center justify-center">
                            <Lock className="h-5 w-5 text-secondary-600 dark:text-secondary-400" />
                        </div>
                        <div>
                            <p className="font-medium">Change Password</p>
                            <p className="text-sm text-slate-500">Update your password</p>
                        </div>
                    </button>
                </Card>

                <Card className="overflow-hidden">
                    <button
                        className="w-full p-4 flex items-center gap-4 text-left hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                        onClick={toggleTheme}
                    >
                        <div className="w-12 h-12 rounded-2xl bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                            {theme === 'dark' ? (
                                <Sun className="h-5 w-5 text-amber-600 dark:text-amber-400" />
                            ) : (
                                <Moon className="h-5 w-5 text-amber-600" />
                            )}
                        </div>
                        <div>
                            <p className="font-medium">{theme === 'dark' ? 'Light Mode' : 'Dark Mode'}</p>
                            <p className="text-sm text-slate-500">Toggle theme appearance</p>
                        </div>
                    </button>
                </Card>

                <Card className="overflow-hidden">
                    <button
                        className="w-full p-4 flex items-center gap-4 text-left hover:bg-red-50 dark:hover:bg-red-900/10 transition-colors"
                        onClick={handleLogout}
                    >
                        <div className="w-12 h-12 rounded-2xl bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
                            <LogOut className="h-5 w-5 text-red-600 dark:text-red-400" />
                        </div>
                        <div>
                            <p className="font-medium text-red-600 dark:text-red-400">Logout</p>
                            <p className="text-sm text-slate-500">Sign out of your account</p>
                        </div>
                    </button>
                </Card>
            </div>

            {/* Edit Name Dialog */}
            <Dialog open={showEditName} onOpenChange={setShowEditName}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Edit Name</DialogTitle>
                    </DialogHeader>
                    <Input
                        label="Name"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="Enter your name"
                    />
                    <DialogFooter className="gap-2 sm:gap-0">
                        <Button variant="outline" onClick={() => setShowEditName(false)}>
                            Cancel
                        </Button>
                        <Button onClick={handleUpdateName} loading={loading}>
                            Save
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Change Password Dialog */}
            <Dialog open={showChangePassword} onOpenChange={setShowChangePassword}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Change Password</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-4">
                        <Input
                            type="password"
                            label="Current Password"
                            value={currentPassword}
                            onChange={(e) => setCurrentPassword(e.target.value)}
                            placeholder="Enter current password"
                        />
                        <Input
                            type="password"
                            label="New Password"
                            value={newPassword}
                            onChange={(e) => setNewPassword(e.target.value)}
                            placeholder="Enter new password"
                        />
                        <Input
                            type="password"
                            label="Confirm Password"
                            value={confirmPassword}
                            onChange={(e) => setConfirmPassword(e.target.value)}
                            placeholder="Confirm new password"
                        />
                    </div>
                    <DialogFooter className="gap-2 sm:gap-0">
                        <Button variant="outline" onClick={() => setShowChangePassword(false)}>
                            Cancel
                        </Button>
                        <Button onClick={handleChangePassword} loading={loading}>
                            Change Password
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </PageLayout>
    );
}

export default Profile;
