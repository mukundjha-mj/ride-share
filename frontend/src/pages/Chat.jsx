import { useState, useEffect, useRef, useCallback } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
import { format } from 'date-fns';
import { Send, Pencil, Trash2 } from 'lucide-react';
import chatService from '@/services/chat';
import socketService from '@/services/socket';
import { useAuth } from '@/context/AuthContext';
import { PageLayout } from '@/components/layout/Layout';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import toast from 'react-hot-toast';

export function Chat() {
    const { joinId } = useParams();
    const [searchParams] = useSearchParams();
    const isOwner = searchParams.get('isOwner') === 'true';
    const { user } = useAuth();

    const [messages, setMessages] = useState([]);
    const [joinRequest, setJoinRequest] = useState(null);
    const [loading, setLoading] = useState(true);
    const [sending, setSending] = useState(false);
    const [message, setMessage] = useState('');
    const [editingMessage, setEditingMessage] = useState(null);

    const messagesEndRef = useRef(null);
    const inputRef = useRef(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    const loadMessages = useCallback(async () => {
        try {
            const response = await chatService.getMessages(joinId);
            if (response.success) {
                setMessages(response.data.messages);
                setJoinRequest(response.data.joinRequest);
            }
        } catch (err) {
            console.error('Error loading messages:', err);
            toast.error('Failed to load messages');
        } finally {
            setLoading(false);
        }
    }, [joinId]);

    useEffect(() => {
        loadMessages();
        socketService.joinChat(joinId);

        const handleNewMessage = (msg) => {
            setMessages((prev) => [...prev, msg]);
        };

        const handleMessageEdited = (msg) => {
            setMessages((prev) =>
                prev.map((m) => ((m._id || m.id) === (msg._id || msg.id) ? msg : m))
            );
        };

        const handleMessageDeleted = (messageId) => {
            setMessages((prev) => prev.filter((m) => (m._id || m.id) !== messageId));
        };

        socketService.on('new_message', handleNewMessage);
        socketService.on('message_edited', handleMessageEdited);
        socketService.on('message_deleted', handleMessageDeleted);

        return () => {
            socketService.leaveChat(joinId);
            socketService.off('new_message', handleNewMessage);
            socketService.off('message_edited', handleMessageEdited);
            socketService.off('message_deleted', handleMessageDeleted);
        };
    }, [joinId, loadMessages]);

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    const handleSend = async (e) => {
        e.preventDefault();
        if (!message.trim()) return;

        setSending(true);

        try {
            if (editingMessage) {
                await chatService.editMessage(joinId, editingMessage._id || editingMessage.id, message.trim());
                setEditingMessage(null);
            } else {
                await chatService.sendMessage(joinId, message.trim());
            }
            setMessage('');
        } catch (err) {
            toast.error('Failed to send message');
        } finally {
            setSending(false);
        }
    };

    const handleEdit = (msg) => {
        setEditingMessage(msg);
        setMessage(msg.message);
        inputRef.current?.focus();
    };

    const handleDelete = async (msg) => {
        if (!confirm('Delete this message?')) return;

        try {
            await chatService.deleteMessage(joinId, msg._id || msg.id);
            toast.success('Message deleted');
        } catch (err) {
            toast.error('Failed to delete message');
        }
    };

    const cancelEdit = () => {
        setEditingMessage(null);
        setMessage('');
    };

    const canSend = joinRequest?.status === 'pending' || joinRequest?.status === 'accepted';

    if (loading) {
        return (
            <PageLayout title="Chat" showBack hideNav>
                <div className="flex items-center justify-center py-20">
                    <div className="h-12 w-12 rounded-full border-4 border-primary-200 border-t-primary-500 animate-spin" />
                </div>
            </PageLayout>
        );
    }

    return (
        <PageLayout title="Chat" showBack hideNav>
            <div className="flex flex-col h-[calc(100vh-180px)] -mx-4">
                {/* Messages */}
                <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
                    {messages.map((msg) => {
                        const isMine = (msg.senderId?._id || msg.senderId) === user?._id;
                        const isSystem = msg.isSystemMessage;

                        if (isSystem) {
                            return (
                                <div
                                    key={msg._id || msg.id}
                                    className="flex justify-center"
                                >
                                    <div className="bg-slate-100 dark:bg-slate-800 rounded-full px-4 py-2 text-xs text-slate-500 dark:text-slate-400 text-center max-w-[80%]">
                                        {msg.message}
                                    </div>
                                </div>
                            );
                        }

                        return (
                            <div
                                key={msg._id || msg.id}
                                className={cn(
                                    "flex",
                                    isMine ? "justify-end" : "justify-start"
                                )}
                            >
                                <div
                                    className={cn(
                                        "max-w-[75%] rounded-2xl px-4 py-3 shadow-sm",
                                        isMine
                                            ? "bg-gradient-to-r from-primary-500 to-primary-600 text-white rounded-br-md"
                                            : "bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-bl-md"
                                    )}
                                >
                                    <p className="break-words">{msg.message}</p>
                                    <div className={cn(
                                        "flex items-center gap-2 mt-1 text-xs",
                                        isMine ? "text-white/70" : "text-slate-400"
                                    )}>
                                        <span>{format(new Date(msg.createdAt), 'h:mm a')}</span>
                                        {msg.isEdited && <span>(edited)</span>}
                                    </div>
                                    {isMine && (
                                        <div className="flex gap-2 mt-2">
                                            <button
                                                onClick={() => handleEdit(msg)}
                                                className={cn(
                                                    "text-xs opacity-70 hover:opacity-100 transition-opacity flex items-center gap-1",
                                                    isMine ? "text-white" : "text-slate-500"
                                                )}
                                            >
                                                <Pencil className="h-3 w-3" />
                                                Edit
                                            </button>
                                            <button
                                                onClick={() => handleDelete(msg)}
                                                className={cn(
                                                    "text-xs opacity-70 hover:opacity-100 transition-opacity flex items-center gap-1",
                                                    isMine ? "text-white" : "text-slate-500"
                                                )}
                                            >
                                                <Trash2 className="h-3 w-3" />
                                                Delete
                                            </button>
                                        </div>
                                    )}
                                </div>
                            </div>
                        );
                    })}
                    <div ref={messagesEndRef} />
                </div>

                {/* Input */}
                <div className="border-t border-slate-200 dark:border-slate-700 bg-white/80 dark:bg-slate-800/80 backdrop-blur-xl p-4">
                    {editingMessage && (
                        <div className="flex justify-between items-center mb-3 px-3 py-2 bg-slate-100 dark:bg-slate-700 rounded-xl text-sm">
                            <span className="text-slate-600 dark:text-slate-300">Editing message</span>
                            <button onClick={cancelEdit} className="text-primary-500 font-medium">
                                Cancel
                            </button>
                        </div>
                    )}

                    {canSend ? (
                        <form onSubmit={handleSend} className="flex gap-3">
                            <input
                                ref={inputRef}
                                type="text"
                                className={cn(
                                    "flex-1 h-12 rounded-2xl border border-slate-200 bg-slate-50 px-5 text-sm transition-all duration-200",
                                    "focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 focus:bg-white",
                                    "dark:border-slate-700 dark:bg-slate-800 dark:focus:bg-slate-700"
                                )}
                                placeholder="Type a message..."
                                value={message}
                                onChange={(e) => setMessage(e.target.value)}
                                disabled={sending}
                            />
                            <Button
                                type="submit"
                                size="icon"
                                className="h-12 w-12 shrink-0"
                                disabled={!message.trim() || sending}
                            >
                                <Send className="h-5 w-5" />
                            </Button>
                        </form>
                    ) : (
                        <div className="text-center text-sm text-slate-500 py-2">
                            This chat has been closed
                        </div>
                    )}
                </div>
            </div>
        </PageLayout>
    );
}

export default Chat;
