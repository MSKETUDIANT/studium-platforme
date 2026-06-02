import React, { useState, useEffect, useRef, useCallback } from 'react';
import { supabase }    from '../../../shared/services/supabase';
import { PageHeader }  from '../../../shared/components/PageHeader';
import { colors, fonts } from '../../../shared/constants/theme';

/* ─── Types ──────────────────────────────────────────────────────────────── */
interface Conversation {
  id:           string;
  updatedAt:    string;
  unreadStaff:  number;
  student:      { id: string; firstName: string | null; lastName: string | null; nationality: string | null };
  lastMessage:  string | null;
}

interface Message {
  id:         string;
  senderType: 'student' | 'staff';
  content:    string;
  createdAt:  string;
}

/* ─── Helpers ─────────────────────────────────────────────────────────────── */
const fullName = (s: Conversation['student']) =>
  [s.firstName, s.lastName].filter(Boolean).join(' ') || 'Étudiant';

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

/* ─── CSS ─────────────────────────────────────────────────────────────────── */
const CSS = `
  .mp-layout { display:grid; grid-template-columns:320px 1fr; height:calc(100vh - 140px); gap:0; background:white; border-radius:16px; box-shadow:0 1px 3px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.04); overflow:hidden; }
  @media(max-width:900px){ .mp-layout{ grid-template-columns:1fr; } }

  /* Sidebar conversations */
  .mp-sidebar { border-right:1px solid ${colors.border}; display:flex; flex-direction:column; overflow:hidden; }
  .mp-sidebar-head { padding:14px 16px; border-bottom:1px solid ${colors.border}; flex-shrink:0; }
  .mp-search { width:100%; padding:8px 12px 8px 34px; border:1.5px solid ${colors.borderInput}; border-radius:8px; font-size:13px; color:${colors.textPrimary}; background:${colors.inputBg}; outline:none; box-sizing:border-box; font-family:${fonts.body}; transition:border-color .18s; }
  .mp-search:focus { border-color:${colors.blue}; background:white; }

  .mp-conv-list { flex:1; overflow-y:auto; }
  .mp-conv-item { display:flex; gap:12px; align-items:flex-start; padding:14px 16px; cursor:pointer; border-bottom:1px solid ${colors.border}; transition:background .12s; position:relative; }
  .mp-conv-item:hover { background:${colors.inputBg}; }
  .mp-conv-item--active { background:rgba(37,70,204,0.06); border-left:3px solid ${colors.blue}; }
  .mp-conv-item:last-child { border-bottom:none; }

  .mp-avatar { width:42px; height:42px; border-radius:12px; display:flex; align-items:center; justify-content:center; font-size:13px; font-weight:700; font-family:${fonts.body}; flex-shrink:0; }
  .mp-unread { position:absolute; top:12px; right:14px; min-width:18px; height:18px; border-radius:9px; background:${colors.blue}; color:white; font-size:10px; font-weight:700; display:flex; align-items:center; justify-content:center; padding:0 4px; }

  /* Thread */
  .mp-thread { display:flex; flex-direction:column; overflow:hidden; }
  .mp-thread-head { padding:14px 20px; border-bottom:1px solid ${colors.border}; display:flex; align-items:center; gap:12px; flex-shrink:0; }
  .mp-messages { flex:1; overflow-y:auto; padding:20px 20px 8px; display:flex; flex-direction:column; gap:12px; }
  .mp-empty { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:10px; color:${colors.textMuted}; font-size:14px; }

  .mp-bubble-wrap { display:flex; flex-direction:column; }
  .mp-bubble-wrap--staff { align-items:flex-end; }
  .mp-bubble-wrap--student { align-items:flex-start; }

  .mp-bubble { max-width:72%; padding:10px 14px; border-radius:14px; font-size:13.5px; line-height:1.5; word-break:break-word; }
  .mp-bubble--staff { background:${colors.blue}; color:white; border-bottom-right-radius:4px; }
  .mp-bubble--student { background:${colors.inputBg}; color:${colors.textPrimary}; border:1px solid ${colors.border}; border-bottom-left-radius:4px; }
  .mp-bubble-time { font-size:10.5px; color:${colors.textMuted}; margin-top:3px; }

  /* Reply box */
  .mp-reply { padding:14px 20px; border-top:1px solid ${colors.border}; display:flex; flex-direction:column; gap:8px; flex-shrink:0; }
  .mp-textarea { width:100%; padding:10px 14px; border:1.5px solid ${colors.borderInput}; border-radius:10px; font-size:13.5px; color:${colors.textPrimary}; background:${colors.inputBg}; font-family:${fonts.body}; resize:none; outline:none; box-sizing:border-box; transition:border-color .18s; }
  .mp-textarea:focus { border-color:${colors.blue}; background:white; }
  .mp-send { align-self:flex-end; padding:8px 18px; border-radius:8px; border:none; background:linear-gradient(135deg,${colors.navy} 0%,#1e40af 100%); color:white; font-weight:700; font-size:13px; cursor:pointer; font-family:${fonts.body}; display:flex; align-items:center; gap:7px; transition:opacity .2s; }
  .mp-send:disabled { opacity:.45; cursor:not-allowed; }
`;

/* ═══════════════════════════════════════════════════════════════════════════
   MessagingPage
   ═══════════════════════════════════════════════════════════════════════════ */
export default function MessagingPage() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [filtered,      setFiltered]      = useState<Conversation[]>([]);
  const [search,        setSearch]        = useState('');
  const [selected,      setSelected]      = useState<Conversation | null>(null);
  const [messages,      setMessages]      = useState<Message[]>([]);
  const [reply,         setReply]         = useState('');
  const [loading,       setLoading]       = useState(true);
  const [msgLoading,    setMsgLoading]    = useState(false);
  const [sending,       setSending]       = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  /* ── Charger conversations ── */
  const loadConversations = useCallback(async () => {
    const { data } = await supabase
      .from('conversations')
      .select(`
        id, updated_at, unread_staff,
        student_profiles!student_profile_id(id, first_name, last_name, nationality),
        messages(content, created_at, sender_type)
      `)
      .order('updated_at', { ascending: false });

    const mapped: Conversation[] = (data ?? []).map((c: any) => {
      const msgs: any[] = c.messages ?? [];
      const last = msgs.sort((a: any, b: any) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime())[0];
      return {
        id:          c.id,
        updatedAt:   c.updated_at,
        unreadStaff: c.unread_staff,
        student:     {
          id:          c.student_profiles?.id ?? '',
          firstName:   c.student_profiles?.first_name ?? null,
          lastName:    c.student_profiles?.last_name ?? null,
          nationality: c.student_profiles?.nationality ?? null,
        },
        lastMessage: last?.content ?? null,
      };
    });

    setConversations(mapped);
    setLoading(false);
  }, []);

  useEffect(() => { loadConversations(); }, [loadConversations]);

  /* ── Filtre search ── */
  useEffect(() => {
    if (!search.trim()) { setFiltered(conversations); return; }
    const q = search.toLowerCase();
    setFiltered(conversations.filter(c =>
      fullName(c.student).toLowerCase().includes(q) ||
      (c.student.nationality ?? '').toLowerCase().includes(q)
    ));
  }, [search, conversations]);

  /* ── Charger messages d'une conversation ── */
  const openConversation = useCallback(async (conv: Conversation) => {
    setSelected(conv);
    setMsgLoading(true);
    setMessages([]);

    const { data } = await supabase
      .from('messages')
      .select('id, sender_type, content, created_at')
      .eq('conversation_id', conv.id)
      .order('created_at', { ascending: true });

    setMessages((data ?? []).map((m: any) => ({
      id:         m.id,
      senderType: m.sender_type,
      content:    m.content,
      createdAt:  m.created_at,
    })));
    setMsgLoading(false);

    // Marquer comme lus
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

  /* ── Scroll bas ── */
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  /* ── Envoyer un message ── */
  const sendReply = async () => {
    if (!reply.trim() || !selected) return;
    setSending(true);
    const content = reply.trim();
    setReply('');

    const { data: { user } } = await supabase.auth.getUser();
    const { data: msg } = await supabase
      .from('messages')
      .insert({
        conversation_id: selected.id,
        sender_type:     'staff',
        sender_id:       user?.id ?? null,
        content,
      })
      .select('id, sender_type, content, created_at')
      .single();

    if (msg) {
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

        {/* ── Sidebar ── */}
        <div className="mp-sidebar">
          <div className="mp-sidebar-head">
            <div style={{ position: 'relative' }}>
              <svg style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: colors.textMuted }}
                width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
              </svg>
              <input
                className="mp-search"
                placeholder="Rechercher un étudiant…"
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>

          <div className="mp-conv-list">
            {loading ? (
              <div style={{ padding: 40, textAlign: 'center', color: colors.textMuted, fontSize: 13 }}>
                Chargement…
              </div>
            ) : filtered.length === 0 ? (
              <div style={{ padding: 40, textAlign: 'center', color: colors.textMuted, fontSize: 13 }}>
                Aucune conversation
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
                        fontSize: 12, color: conv.unreadStaff > 0 ? colors.textPrimary : colors.textMuted,
                        marginTop: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                        fontWeight: conv.unreadStaff > 0 ? 600 : 400,
                      }}>
                        {conv.lastMessage}
                      </div>
                    )}
                  </div>
                  {conv.unreadStaff > 0 && (
                    <div className="mp-unread">{conv.unreadStaff}</div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* ── Thread ── */}
        <div className="mp-thread">
          {!selected ? (
            <div className="mp-empty">
              <div style={{
                width: 72, height: 72, borderRadius: 20,
                background: 'linear-gradient(135deg, rgba(37,70,204,0.10), rgba(124,58,237,0.10))',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width={32} height={32} fill="none" viewBox="0 0 24 24" stroke={colors.blue} strokeWidth={1.5}>
                  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                </svg>
              </div>
              <div style={{ fontWeight: 700, fontSize: 15, color: colors.textSecondary }}>
                Sélectionnez une conversation
              </div>
              <div style={{ fontSize: 12, color: colors.textMuted }}>
                pour lire et répondre aux messages
              </div>
            </div>
          ) : (
            <>
              {/* Header */}
              <div className="mp-thread-head">
                {(() => {
                  const [fg, bg] = avatarColor(fullName(selected.student));
                  return (
                    <div className="mp-avatar" style={{ background: bg, color: fg }}>
                      {initials(selected.student)}
                    </div>
                  );
                })()}
                <div>
                  <div style={{ fontWeight: 700, fontSize: 15, color: colors.navy }}>
                    {fullName(selected.student)}
                  </div>
                  {selected.student.nationality && (
                    <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 1 }}>
                      {selected.student.nationality}
                    </div>
                  )}
                </div>
              </div>

              {/* Messages */}
              <div className="mp-messages">
                {msgLoading ? (
                  <div style={{ textAlign: 'center', color: colors.textMuted, fontSize: 13, padding: 32 }}>
                    Chargement…
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
                  placeholder="Écrire un message… (Ctrl+Entrée pour envoyer)"
                  value={reply}
                  onChange={e => setReply(e.target.value)}
                  onKeyDown={handleKeyDown}
                />
                <button
                  className="mp-send"
                  disabled={!reply.trim() || sending}
                  onClick={sendReply}
                >
                  <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
                    <line x1="22" y1="2" x2="11" y2="13"/>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"/>
                  </svg>
                  {sending ? 'Envoi…' : 'Envoyer'}
                </button>
              </div>
            </>
          )}
        </div>

      </div>
    </>
  );
}
