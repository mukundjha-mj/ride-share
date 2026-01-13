import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Sun, Moon, User } from 'lucide-react';
import { useTheme } from '@/context/ThemeContext';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

export function Header({ title, showBack = false, actions }) {
    const navigate = useNavigate();
    const location = useLocation();
    const { theme, toggleTheme } = useTheme();

    const handleBack = () => {
        if (window.history.length > 2) {
            navigate(-1);
        } else {
            navigate('/');
        }
    };

    // Default title based on route
    const getDefaultTitle = () => {
        switch (location.pathname) {
            case '/':
                return 'Discover Rides';
            case '/my-rides':
                return 'My Rides';
            case '/chats':
                return 'Messages';
            case '/requests':
                return 'My Requests';
            case '/profile':
                return 'Profile';
            case '/create-ride':
                return 'Post a Ride';
            default:
                return 'RideShare';
        }
    };

    return (
        <header className="sticky top-0 z-40 glass-strong border-b border-slate-200/50 dark:border-slate-700/50">
            <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    {showBack ? (
                        <Button variant="ghost" size="icon" onClick={handleBack} className="rounded-full">
                            <ArrowLeft className="h-5 w-5" />
                        </Button>
                    ) : (
                        <Button variant="ghost" size="icon" onClick={toggleTheme} className="rounded-full">
                            {theme === 'dark' ? (
                                <Sun className="h-5 w-5 text-amber-500" />
                            ) : (
                                <Moon className="h-5 w-5 text-slate-600" />
                            )}
                        </Button>
                    )}
                    <h1 className="text-xl font-bold bg-gradient-to-r from-primary-600 to-secondary-600 bg-clip-text text-transparent">
                        {title || getDefaultTitle()}
                    </h1>
                </div>
                <div className="flex items-center gap-2">
                    {actions}
                    {!showBack && (
                        <Button
                            variant="ghost"
                            size="icon"
                            className="rounded-full"
                            onClick={() => navigate('/profile')}
                        >
                            <User className="h-5 w-5" />
                        </Button>
                    )}
                </div>
            </div>
        </header>
    );
}

export default Header;
