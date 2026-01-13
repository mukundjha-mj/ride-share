import { NavLink } from 'react-router-dom';
import { Home, Car, MessageCircle, Send } from 'lucide-react';
import { useSocket } from '@/context/SocketContext';
import { cn } from '@/lib/utils';

const navItems = [
    { path: '/', icon: Home, label: 'Browse' },
    { path: '/my-rides', icon: Car, label: 'My Rides' },
    { path: '/chats', icon: MessageCircle, label: 'Chats', hasUnread: true },
    { path: '/requests', icon: Send, label: 'Requests' },
];

export function BottomNav() {
    const { unreadCount } = useSocket();

    return (
        <nav className="fixed bottom-0 left-0 right-0 z-50 glass-strong border-t border-slate-200/50 dark:border-slate-700/50 safe-area-bottom">
            <div className="max-w-lg mx-auto px-2">
                <div className="flex items-center justify-around py-2">
                    {navItems.map((item) => (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            className={({ isActive }) =>
                                cn(
                                    "flex flex-col items-center gap-1 px-4 py-2 rounded-2xl transition-all duration-200",
                                    isActive
                                        ? "text-primary-600 bg-primary-50 dark:bg-primary-900/20 dark:text-primary-400"
                                        : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
                                )
                            }
                        >
                            <div className="relative">
                                <item.icon className="h-5 w-5" />
                                {item.hasUnread && unreadCount > 0 && (
                                    <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white">
                                        {unreadCount > 9 ? '9+' : unreadCount}
                                    </span>
                                )}
                            </div>
                            <span className="text-xs font-medium">{item.label}</span>
                        </NavLink>
                    ))}
                </div>
            </div>
        </nav>
    );
}

export default BottomNav;
