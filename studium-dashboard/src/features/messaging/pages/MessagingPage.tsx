import React, { useState, useEffect, useRef, useCallback } from 'react';
import { supabase }    from '../../../shared/services/supabase';
import { PageHeader }  from '../../../shared/components/PageHeader';
import { colors, fonts } from '../../../shared/constants/theme';

/*  Types  */
interface Conversation {
  id:           string;
  updatedAt:    string;
  unreadStaff:  number;
  student:      { id: string; firstName: string | null; lastName: string | null; nationality: string | null };
  lastMessage:  string | null;
  tags:         string[];
}

const ALL_TAGS = [
  { key: 'urgent',       label: 'Urgent',        color: '#ef4444', bg: 'rgba(239,68,68,0.10)'   },
  { key: 'doc_manquant', label: 'Doc manquant',   color: '#f59e0b', bg: 'rgba(245,158,11,0.10)' },
  { key: 'paiement',     label: 'Paiement',       color: '#8b5cf6', bg: 'rgba(139,92,246,0.10)' },
  { key: 'technique',    label: 'Technique',      color: '#0891b2', bg: 'rgba(8,145,178,0.10)'  },
  { key: 'resolu',       label: 'Resolu',         color: '#10b981', bg: 'rgba(16,185,129,0.10)' },
];

interface Message {
  id:         string;
  senderType: 'student' | 'staff';
  content:    string;
  createdAt:  string;
}

/*  Helpers  */
const fullName = (s: Conversation['student']) =>
  [s.firstName, s.lastName].filter(Boolean).join(' ') || 'Etudiant';

const initials = (s: Conversation['student']) =>
  `${s.firstName?.[0] ?? ''}${s.lastName?.[0] ?? ''}`.toUpperCase() || '?';

const AVATAR_COLORS = [
  ['#2546cc', 'rgba(37,70,204,0.12)'],
  ['#7c3aed', 'rgba(124,58,237,0.12)'],
  ['#16a34a', 'rgba(22,163,74,0.12)'],
  ['#d97706', 'rgba(217,119,6,0.12)'],
  ['#0891b2', 'rgba(8,145,178,0.12)'],
];
const avatarColor = (name: string) => AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length];

const fmtTime = (iso: string) => {
  const d   = new Date(iso);
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - d.getTime()) / 86400000);
  if (diffDays === 0) return d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  if (diffDays === 1) return 'Hier';
  if (diffDays < 7)  return d.toLocaleDateString('fr-FR', { weekday: 'short' });
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
};

/*  CSS  */
const CSS = `
  .mp-layout { display:grid; grid-template-columns:320px 1fr; height:calc(100vh - 140px); gap:0; background:white; border-radius:16px; box-shadow:0 1px 4px rgba(11,24,82,0.04),0 8px 24px rgba(11,24,82,0.07),0 28px 60px rgba(11,24,82,0.08); overflow:hidden; }
  @media(max-width:900px){ .mp-layout{ grid-template-columns:1fr; } }

  /* Sidebar */
  .mp-sidebar { border-right:1px solid ${colors.border}; display:flex; flex-direction:column; overflow:hidden; background:#fafbff; }
  .mp-sidebar-head { padding:14px 16px; border-bottom:1px solid ${colors.border}; flex-shrink:0; }
  .mp-sidebar-top { display:flex; align-items:center; justify-content:space-between; margin-bottom:10px; }
  .mp-sidebar-title { font-size:13px; font-weight:700; color:${colors.navy}; font-family:${fonts.display}; }

  .mp-refresh-btn { width:28px; height:28px; border-radius:8px; border:1.5px solid ${colors.borderInput}; background:white; cursor:pointer; display:flex; align-items:center; justify-content:center; color:${colors.textMuted}; transition:all .15s; }
  .mp-refresh-btn:hover { border-color:${colors.blue}; color:${colors.blue}; }
  .mp-refresh-btn.spinning svg { animation:mp-spin .7s linear infinite; }
  @keyframes mp-spin { to { transform: rotate(360deg); } }

  .mp-search-wrap { position:relative; }
  .mp-search { width:100%; padding:8px 12px 8px 34px; border:1.5px solid ${colors.borderInput}; border-radius:8px; font-size:13px; color:${colors.textPrimary}; background:white; outline:none; box-sizing:border-box; font-family:${fonts.body}; transition:border-color .18s; }
  .mp-search:focus { border-color:${colors.blue}; }

  .mp-conv-list { flex:1; overflow-y:auto; }
  .mp-conv-item { display:flex; gap:12px; align-items:flex-start; padding:14px 16px; cursor:pointer; border-bottom:1px solid ${colors.border}; transition:background .12s; position:relative; }
  .mp-conv-item:hover { background:${colors.inputBg}; }
  .mp-conv-item--active { background:rgba(37,70,204,0.06); border-left:3px solid ${colors.blue}; }
  .mp-conv-item:last-child { border-bottom:none; }

  .mp-avatar { width:42px; height:42px; border-radius:12px; display:flex; align-items:center; justify-content:center; font-size:13px; font-weight:700; font-family:${fonts.body}; flex-shrink:0; }
  .mp-unread-badge { position:absolute; top:12px; right:14px; min-width:18px; height:18px; border-radius:9px; background:${colors.blue}; color:white; font-size:10px; font-weight:700; display:flex; align-items:center; justify-content:center; padding:0 4px; }

  /* Thread */
  .mp-thread { display:flex; flex-direction:column; overflow:hidden; background:white; }
  .mp-thread-head { padding:14px 20px; border-bottom:1px solid ${colors.border}; display:flex; align-items:flex-start; gap:12px; flex-shrink:0; }
  .mp-messages { flex:1; overflow-y:auto; padding:20px 20px 8px; display:flex; flex-direction:column; gap:12px; background:#fafbff; }
  .mp-empty { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:10px; color:${colors.textMuted}; font-size:14px; }

  .mp-bubble-wrap { display:flex; flex-direction:column; }
  .mp-bubble-wrap--staff { align-items:flex-end; }
  .mp-bubble-wrap--student { align-items:flex-start; }

  .mp-bubble { max-width:72%; padding:10px 14px; border-radius:14px; font-size:13.5px; line-height:1.5; word-break:break-word; }
  .mp-bubble--staff { background:${colors.blue}; color:white; border-bottom-right-radius:4px; }
  .mp-bubble--student { background:white; color:${colors.textPrimary}; border:1px solid ${colors.border}; border-bottom-left-radius:4px; box-shadow:0 1px 3px rgba(0,0,0,.04); }
  .mp-bubble-time { font-size:10.5px; color:${colors.textMuted}; margin-top:3px; }

  /* Reply box */
  .mp-reply { padding:14px 20px; border-top:1px solid ${colors.border}; display:flex; flex-direction:column; gap:8px; flex-shrink:0; background:white; }
  .mp-textarea { width:100%; padding:10px 14px; border:1.5px solid ${colors.borderInput}; border-radius:10px; font-size:13.5px; color:${colors.textPrimary}; background:${colors.inputBg}; font-family:${fonts.body}; resize:none; outline:none; box-sizing:border-box; transition:border-color .18s; }
  .mp-textarea:focus { border-color:${colors.blue}; background:white; }
  .mp-reply-actions { display:flex; align-items:center; justify-content:space-between; }
  .mp-reply-hint { font-size:11px; color:${colors.textMuted}; }
  .mp-send { padding:8px 18px; border-radius:8px; border:none; background:linear-gradient(135deg,${colors.navy} 0%,#1e40af 100%); color:white; font-weight:700; font-size:13px; cursor:pointer; font-family:${fonts.body}; display:flex; align-items:center; gap:7px; transition:opacity .2s; }
  .mp-send:disabled { opacity:.45; cursor:not-allowed; }
  .mp-send:not(:disabled):hover { opacity:.88; }

  /* States */
  .mp-dot-loader { display:flex; gap:5px; align-items:center; padding:28px; justify-content:center; }
  .mp-dot { width:7px; height:7px; border-radius:50%; background:${colors.blue}; opacity:.3; animation:mp-dotPulse 1.2s infinite; }
  .mp-dot:nth-child(2) { animation-delay:.2s; }
  .mp-dot:nth-child(3) { animation-delay:.4s; }
  @keyframes mp-dotPulse { 0%,80%,100%{opacity:.3} 40%{opacity:1} }

  .mp-error-box { margin:12px; padding:12px 14px; background:rgba(239,68,68,0.07); border:1.5px solid rgba(239,68,68,0.18); border-radius:10px; font-size:12.5px; color:#dc2626; display:flex; align-items:center; gap:8px; }
`;

export default function MessagingPage() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [filtered,      setFiltered]      = useState<Conversation[]>([]);
  const [search,        setSearch]        = useState('');
  const [selected,      setSelected]      = useState<Conversation | null>(null);
  const [messages,      setMessages]      = useState<Message[]>([]);
  const [reply,         setReply]         = useState('');
  const [loading,       setLoading]       = useState(true);
  const [refreshing,    setRefreshing]    = useState(false);
  const [msgLoading,    setMsgLoading]    = useState(false);
  const [sending,       setSending]       = useState(false);
  const [loadError,     setLoadError]     = useState<string | null>(null);
  const bottomRef   = useRef<HTMLDivElement>(null);
  const selectedRef = useRef<Conversation | null>(null);
  selectedRef.current = selected;

  /*  Mapper une conversation brute  */
  const mapConv = useCallback((c: any): Conversation => {
    const msgs: any[] = c.messages ?? [];
    const last = msgs.sort((a: any, b: any) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime())[0];
    return {
      id:          c.id,
      updatedAt:   c.updated_at,
      unreadStaff: c.unread_staff ?? 0,
      student: {
        id:          c.student_profiles?.id ?? '',
        firstName:   c.student_profiles?.first_name ?? null,
        lastName:    c.student_profiles?.last_name ?? null,
        nationality: c.student_profiles?.nationality ?? null,
      },
      lastMessage: last?.content ?? null,
      tags:        c.tags ?? [],
    };
  }, []);

  /*  Charger conversations  */
  const loadConversations = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true); else setLoading(true);
    setLoadError(null);

    const { data, error } = await supabase
      .from('conversations')
      .select(`
        id, updated_at, unread_staff, tags,
        student_profiles!student_profile_id(id, first_name, last_name, nationality),
        messages(content, created_at, sender_type)
      `)
      .order('updated_at', { ascending: false });

    if (error) {
      console.error('[MessagingPage] loadConversations error:', error);
      setLoadError(error.message);
    } else {
      setConversations((data ?? []).map(mapConv));
    }

    if (isRefresh) setRefreshing(false); else setLoading(false);
  }, [mapConv]);

  useEffect(() => { loadConversations(); }, [loadConversations]);

  /*  Realtime — nouvelles conversations et nouveaux messages  */
  useEffect(() => {
    const channel = supabase
      .channel('mp-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'conversations' }, () => {
        loadConversations(true);
      })
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, (payload) => {
        const msg = payload.new as any;
        if (selectedRef.current?.id === msg.conversation_id && msg.sender_type === 'student') {
          setMessages(prev => [...prev, {
            id:         msg.id,
            senderType: msg.sender_type,
            content:    msg.content,
            createdAt:  msg.created_at,
          }]);
        }
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [loadConversations]);

  /*  Filtre search  */
  useEffect(() => {
    if (!search.trim()) { setFiltered(conversations); return; }
    const q = search.toLowerCase();
    setFiltered(conversations.filter(c =>
      fullName(c.student).toLowerCase().includes(q) ||
      (c.student.nationality ?? '').toLowerCase().includes(q)
    ));
  }, [search, conversations]);

  /*  Tags  */
  const toggleTag = async (convId: string, tag: string) => {
    const conv = conversations.find(c => c.id === convId);
    if (!conv) return;
    const has     = conv.tags.includes(tag);
    const newTags = has ? conv.tags.filter(t => t !== tag) : [...conv.tags, tag];
    await supabase.from('conversations').update({ tags: newTags }).eq('id', convId);
    const update = (list: Conversation[]) =>
      list.map(c => c.id === convId ? { ...c, tags: newTags } : c);
    setConversations(update);
    setFiltered(update);
    if (selected?.id === convId) setSelected(prev => prev ? { ...prev, tags: newTags } : prev);
  };

  /*  Charger messages d'une conversation  */
  const openConversation = useCallback(async (conv: Conversation) => {
    setSelected(conv);
    setMsgLoading(true);
    setMessages([]);

    const { data, error } = await supabase
      .from('messages')
      .select('id, sender_type, content, created_at')
      .eq('conversation_id', conv.id)
      .order('created_at', { ascending: true });

    if (error) {
      console.error('[MessagingPage] loadMessages error:', error);
    } else {
      setMessages((data ?? []).map((m: any) => ({
        id:         m.id,
        senderType: m.sender_type,
        content:    m.content,
        createdAt:  m.created_at,
      })));
    }
    setMsgLoading(false);

    if (conv.unreadStaff > 0) {
      await supabase
        .from('conversations')
        .update({ unread_staff: 0 })
        .eq('id', conv.id);
      setConversations(prev =>
        prev.map(c => c.id === conv.id ? { ...c, unreadStaff: 0 } : c)
      );
    }
  }, []);

  /*  Scroll bas  */
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  /*  Envoyer un message  */
  const sendReply = async () => {
    if (!reply.trim() || !selected) return;
    setSending(true);
    const content = reply.trim();
    setReply('');

    const { data: { user } } = await supabase.auth.getUser();
    const { data: msg, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: selected.id,
        sender_type:     'staff',
        sender_id:       user?.id ?? null,
        content,
      })
      .select('id, sender_type, content, created_at')
      .single();

    if (error) {
      console.error('[MessagingPage] sendReply error:', error);
    } else if (msg) {
      setMessages(prev => [...prev, {
        id:         msg.id,
        senderType: msg.sender_type,
        content:    msg.content,
        createdAt:  msg.created_at,
      }]);
      setConversations(prev =>
        prev.map(c => c.id === selected.id
          ? { ...c, lastMessage: content, updatedAt: msg.created_at }
          : c
        ).sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
      );
      supabase.functions.invoke('send-push-notification', {
        body: {
          user_ids: [selected.student.id],
          title:    'Nouveau message - Equipe Studium',
          body:     content.length > 100 ? content.substring(0, 97) + '...' : content,
          data:     { type: 'message', conversation_id: selected.id },
        },
      }).catch(console.error);
    }
    setSending(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) sendReply();
  };

  const totalUnread = conversations.reduce((s, c) => s + c.unreadStaff, 0);

  return (
    <>
      <style>{CSS}</style>
      <PageHeader
        title="Messagerie"
        subtitle={
          totalUnread > 0
            ? `${totalUnread} message${totalUnread > 1 ? 's' : ''} non lu${totalUnread > 1 ? 's' : ''}`
            : `${conversations.length} conversation${conversations.length !== 1 ? 's' : ''}`
        }
      />

      <div className="mp-layout">

        {/*  Sidebar  */}
        <div className="mp-sidebar">
          <div className="mp-sidebar-head">
            <div className="mp-sidebar-top">
              <span className="mp-sidebar-title">
                Conversations
                {conversations.length > 0 && (
                  <span style={{ marginLeft: 7, fontSize: 11, fontWeight: 700, color: colors.textMuted, background: colors.inputBg, padding: '1px 7px', borderRadius: 20 }}>
                    {conversations.length}
                  </span>
                )}
              </span>
              <button
                className={`mp-refresh-btn${refreshing ? ' spinning' : ''}`}
                onClick={() => loadConversations(true)}
                title="Actualiser"
              >
                <svg width={13} height={13} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round">
                  <polyline points="23 4 23 10 17 10"/>
                  <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
                </svg>
              </button>
            </div>
            <div className="mp-search-wrap">
              <svg style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: colors.textMuted }}
                width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
              </svg>
              <input
                className="mp-search"
                placeholder="Rechercher un etudiant"
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>

          <div className="mp-conv-list">
            {loading ? (
              <div className="mp-dot-loader">
                <div className="mp-dot" /><div className="mp-dot" /><div className="mp-dot" />
              </div>
            ) : loadError ? (
              <div className="mp-error-box">
                <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                Impossible de charger les conversations
              </div>
            ) : filtered.length === 0 ? (
              <div style={{ padding: '40px 20px', textAlign: 'center' }}>
                <svg width={32} height={32} fill="none" viewBox="0 0 24 24" stroke={colors.textMuted} strokeWidth={1.5} style={{ display: 'block', margin: '0 auto 10px' }}>
                  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                </svg>
                <span style={{ fontSize: 13, color: colors.textMuted }}>
                  {search ? 'Aucun resultat' : 'Aucune conversation'}
                </span>
              </div>
            ) : filtered.map(conv => {
              const [fg, bg] = avatarColor(fullName(conv.student));
              const active   = selected?.id === conv.id;
              return (
                <div
                  key={conv.id}
                  className={`mp-conv-item${active ? ' mp-conv-item--active' : ''}`}
                  onClick={() => openConversation(conv)}
                >
                  <div className="mp-avatar" style={{ background: bg, color: fg }}>
                    {initials(conv.student)}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 6 }}>
                      <span style={{ fontWeight: conv.unreadStaff > 0 ? 700 : 600, fontSize: 13, color: colors.textPrimary, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {fullName(conv.student)}
                      </span>
                      <span style={{ fontSize: 10.5, color: colors.textMuted, flexShrink: 0 }}>
                        {fmtTime(conv.updatedAt)}
                      </span>
                    </div>
                    {conv.student.nationality && (
                      <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 1 }}>
                        {conv.student.nationality}
                      </div>
                    )}
                    {conv.lastMessage && (
                      <div style={{
                        fontSize: 12,
                        color: conv.unreadStaff > 0 ? colors.textPrimary : colors.textMuted,
                        marginTop: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                        fontWeight: conv.unreadStaff > 0 ? 600 : 400,
                      }}>
                        {conv.lastMessage}
                      </div>
                    )}
                    {conv.tags.length > 0 && (
                      <div style={{ display: 'flex', gap: 4, marginTop: 5, flexWrap: 'wrap' }}>
                        {conv.tags.map(tag => {
                          const t = ALL_TAGS.find(t => t.key === tag);
                          if (!t) return null;
                          return (
                            <span key={tag} style={{
                              fontSize: 10, fontWeight: 700, padding: '1px 7px',
                              borderRadius: 20, background: t.bg, color: t.color,
                            }}>{t.label}</span>
                          );
                        })}
                      </div>
                    )}
                  </div>
                  {conv.unreadStaff > 0 && (
                    <div className="mp-unread-badge">{conv.unreadStaff}</div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/*  Thread  */}
        <div className="mp-thread">
          {!selected ? (
            <div className="mp-empty">
              <div style={{
                width: 72, height: 72, borderRadius: 20,
                background: 'linear-gradient(135deg, rgba(37,70,204,0.08), rgba(124,58,237,0.08))',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width={32} height={32} fill="none" viewBox="0 0 24 24" stroke={colors.blue} strokeWidth={1.5}>
                  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                </svg>
              </div>
              <div style={{ fontWeight: 700, fontSize: 15, color: colors.textSecondary }}>
                Selectionnez une conversation
              </div>
              <div style={{ fontSize: 12, color: colors.textMuted }}>
                pour lire et repondre aux messages
              </div>
            </div>
          ) : (
            <>
              {/* Header */}
              <div className="mp-thread-head">
                {(() => {
                  const [fg, bg] = avatarColor(fullName(selected.student));
                  return (
                    <div className="mp-avatar" style={{ background: bg, color: fg, flexShrink: 0 }}>
                      {initials(selected.student)}
                    </div>
                  );
                })()}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 700, fontSize: 15, color: colors.navy }}>
                    {fullName(selected.student)}
                  </div>
                  {selected.student.nationality && (
                    <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 1 }}>
                      {selected.student.nationality}
                    </div>
                  )}
                  <div style={{ display: 'flex', gap: 5, marginTop: 8, flexWrap: 'wrap' }}>
                    {ALL_TAGS.map(t => {
                      const active = selected.tags.includes(t.key);
                      return (
                        <button
                          key={t.key}
                          onClick={() => toggleTag(selected.id, t.key)}
                          style={{
                            fontSize: 10.5, fontWeight: 700, padding: '3px 10px',
                            borderRadius: 20, border: `1.5px solid ${active ? t.color : colors.border}`,
                            background: active ? t.bg : 'transparent',
                            color: active ? t.color : colors.textMuted,
                            cursor: 'pointer', transition: 'all .15s',
                          }}
                        >{t.label}</button>
                      );
                    })}
                  </div>
                </div>
              </div>

              {/* Messages */}
              <div className="mp-messages">
                {msgLoading ? (
                  <div className="mp-dot-loader">
                    <div className="mp-dot" /><div className="mp-dot" /><div className="mp-dot" />
                  </div>
                ) : messages.length === 0 ? (
                  <div style={{ textAlign: 'center', color: colors.textMuted, fontSize: 13, padding: 32 }}>
                    Aucun message pour le moment.
                  </div>
                ) : messages.map(msg => (
                  <div key={msg.id} className={`mp-bubble-wrap mp-bubble-wrap--${msg.senderType}`}>
                    <div className={`mp-bubble mp-bubble--${msg.senderType}`}>
                      {msg.content}
                    </div>
                    <div className="mp-bubble-time">{fmtTime(msg.createdAt)}</div>
                  </div>
                ))}
                <div ref={bottomRef} />
              </div>

              {/* Reply */}
              <div className="mp-reply">
                <textarea
                  className="mp-textarea"
                  rows={3}
                  placeholder="Ecrire un message..."
                  value={reply}
                  onChange={e => setReply(e.target.value)}
                  onKeyDown={handleKeyDown}
                />
                <div className="mp-reply-actions">
                  <span className="mp-reply-hint">Ctrl+Entree pour envoyer</span>
                  <button
                    className="mp-send"
                    disabled={!reply.trim() || sending}
                    onClick={sendReply}
                  >
                    <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
                      <line x1="22" y1="2" x2="11" y2="13"/>
                      <polygon points="22 2 15 22 11 13 2 9 22 2"/>
                    </svg>
                    {sending ? 'Envoi...' : 'Envoyer'}
                  </button>
                </div>
              </div>
            </>
          )}
        </div>

      </div>
    </>
  );
}
