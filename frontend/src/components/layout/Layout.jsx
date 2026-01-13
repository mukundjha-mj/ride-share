import { Outlet } from 'react-router-dom';
import Header from './Header';
import BottomNav from './BottomNav';

export function Layout({ showBack = false, title, actions, hideNav = false }) {
    return (
        <div className="min-h-screen flex flex-col bg-gradient-to-br from-slate-50 via-white to-slate-100 dark:from-slate-900 dark:via-slate-900 dark:to-slate-800">
            <Header showBack={showBack} title={title} actions={actions} />
            <main className="flex-1 max-w-7xl w-full mx-auto px-4 py-6 pb-24">
                <Outlet />
            </main>
            {!hideNav && <BottomNav />}
        </div>
    );
}

export function PageLayout({ children, showBack = false, title, actions, hideNav = false }) {
    return (
        <div className="min-h-screen flex flex-col bg-gradient-to-br from-slate-50 via-white to-slate-100 dark:from-slate-900 dark:via-slate-900 dark:to-slate-800">
            <Header showBack={showBack} title={title} actions={actions} />
            <main className="flex-1 max-w-7xl w-full mx-auto px-4 py-6 pb-24">
                {children}
            </main>
            {!hideNav && <BottomNav />}
        </div>
    );
}

export default Layout;
