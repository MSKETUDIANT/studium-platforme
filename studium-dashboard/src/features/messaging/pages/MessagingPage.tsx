import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { supabase }       from '../../../shared/services/supabase';
import { PageHeader }     from '../../../shared/components/PageHeader';
import { Pagination }     from '../../../shared/components/Pagination';
import { colors, fonts }  from '../../../shared/constants/theme';

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
  fileUrl:    string | null;
  fileName:   string | null;
}

interface Template {
  id:      string;
  title:   string;
  content: string;
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
  .mp-conv-item { display:flex; gap:12px; align-items:flex-start; padding:13px 16px; cursor:pointer; border-bottom:1px solid ${colors.border}; transition:background .12s; position:relative; }
  .mp-conv-item:hover { background:rgba(37,70,204,0.03); }
  .mp-conv-item--active { background:rgba(37,70,204,0.07); border-left:3px solid ${colors.blue}; padding-left:13px; }
  .mp-conv-item--unread { background:#fffbf0; }
  .mp-conv-item--unread:hover { background:#fff8e6; }
  .mp-conv-item:last-child { border-bottom:none; }

  .mp-avatar { width:42px; height:42px; border-radius:12px; display:flex; align-items:center; justify-content:center; font-size:13px; font-weight:700; font-family:${fonts.display}; flex-shrink:0; letter-spacing:-.3px; }
  .mp-unread-badge { min-width:20px; height:20px; border-radius:10px; background:${colors.blue}; color:white; font-size:10.5px; font-weight:700; display:flex; align-items:center; justify-content:center; padding:0 5px; flex-shrink:0; margin-top:2px; }

  .mp-sidebar-pagination { border-top:1px solid ${colors.border}; padding:8px 10px; flex-shrink:0; background:white; }
  .mp-sidebar-pagination .pg-wrap { padding:0; box-shadow:none; background:transparent; border-radius:0; }

  /* Thread */
  .mp-thread { display:flex; flex-direction:column; overflow:hidden; background:white; }
  .mp-thread-head { padding:16px 22px; border-bottom:1px solid ${colors.border}; display:flex; align-items:flex-start; gap:14px; flex-shrink:0; background:linear-gradient(135deg,#f8faff 0%,#fff 100%); }
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
  .mp-reply { padding:14px 20px; border-top:1px solid ${colors.border}; display:flex; flex-direction:column; gap:8px; flex-shrink:0; background:white; position:relative; }
  .mp-textarea { width:100%; padding:10px 14px; border:1.5px solid ${colors.borderInput}; border-radius:10px; font-size:13.5px; color:${colors.textPrimary}; background:${colors.inputBg}; font-family:${fonts.body}; resize:none; outline:none; box-sizing:border-box; transition:border-color .18s; }
  .mp-textarea:focus { border-color:${colors.blue}; background:white; }
  .mp-reply-actions { display:flex; align-items:center; justify-content:space-between; }
  .mp-reply-hint { font-size:11px; color:${colors.textMuted}; }
  .mp-send { padding:8px 18px; border-radius:8px; border:none; background:linear-gradient(135deg,${colors.navy} 0%,#1e40af 100%); color:white; font-weight:700; font-size:13px; cursor:pointer; font-family:${fonts.body}; display:flex; align-items:center; gap:7px; transition:opacity .2s; }
  .mp-send:disabled { opacity:.45; cursor:not-allowed; }
  .mp-send:not(:disabled):hover { opacity:.88; }

  /* Templates */
  .mp-tpl-btn { display:inline-flex; align-items:center; gap:5px; padding:5px 11px; border-radius:8px; border:1.5px solid ${colors.borderInput}; background:white; cursor:pointer; font-size:12px; font-weight:600; color:${colors.textSecondary}; font-family:${fonts.body}; transition:all .15s; }
  .mp-tpl-btn:hover { border-color:${colors.blue}; color:${colors.blue}; background:rgba(37,70,204,0.05); }
  .mp-tpl-btn--active { border-color:${colors.blue}; color:${colors.blue}; background:rgba(37,70,204,0.07); }

  .mp-tpl-picker { position:absolute; bottom:calc(100% + 8px); left:16px; right:16px; background:white; border-radius:12px; border:1.5px solid ${colors.border}; box-shadow:0 8px 32px rgba(11,24,82,0.14); z-index:50; max-height:320px; display:flex; flex-direction:column; overflow:hidden; }
  .mp-tpl-head { padding:10px 14px; border-bottom:1px solid ${colors.border}; font-size:12px; font-weight:700; color:${colors.navy}; flex-shrink:0; display:flex; align-items:center; justify-content:space-between; }
  .mp-tpl-list { flex:1; overflow-y:auto; }
  .mp-tpl-item { padding:10px 14px; border-bottom:1px solid ${colors.border}; cursor:pointer; transition:background .12s; }
  .mp-tpl-item:hover { background:rgba(37,70,204,0.04); }
  .mp-tpl-item:last-child { border-bottom:none; }
  .mp-tpl-title { font-size:12.5px; font-weight:700; color:${colors.navy}; display:flex; align-items:center; justify-content:space-between; }
  .mp-tpl-preview { font-size:11.5px; color:${colors.textMuted}; margin-top:2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .mp-tpl-del { background:none; border:none; cursor:pointer; color:${colors.textMuted}; padding:2px 6px; border-radius:5px; font-size:11px; line-height:1; flex-shrink:0; }
  .mp-tpl-del:hover { color:${colors.danger}; background:rgba(220,38,38,0.08); }
  .mp-tpl-new { padding:10px 14px; border-top:1px solid ${colors.border}; flex-shrink:0; display:flex; flex-direction:column; gap:6px; }
  .mp-tpl-input { width:100%; padding:7px 10px; border:1.5px solid ${colors.borderInput}; border-radius:7px; font-size:12.5px; font-family:${fonts.body}; color:${colors.textPrimary}; outline:none; box-sizing:border-box; transition:border-color .15s; }
  .mp-tpl-input:focus { border-color:${colors.blue}; }
  .mp-tpl-save { align-self:flex-end; padding:6px 14px; border-radius:7px; border:none; background:${colors.blue}; color:white; font-size:12px; font-weight:700; cursor:pointer; font-family:${fonts.body}; opacity:1; transition:opacity .15s; }
  .mp-tpl-save:disabled { opacity:.4; cursor:not-allowed; }

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
  const [page,          setPage]          = useState(1);
  const [pageSize,      setPageSize]      = useState(15);
  const [messages,      setMessages]      = useState<Message[]>([]);
  const [reply,         setReply]         = useState('');
  const [loading,       setLoading]       = useState(true);
  const [refreshing,    setRefreshing]    = useState(false);
  const [msgLoading,    setMsgLoading]    = useState(false);
  const [sending,       setSending]       = useState(false);
  const [loadError,     setLoadError]     = useState<string | null>(null);
  const [templates,     setTemplates]     = useState<Template[]>([]);
  const [showTemplates, setShowTemplates] = useState(false);
  const [newTplTitle,   setNewTplTitle]   = useState('');
  const [newTplContent, setNewTplContent] = useState('');
  const [savingTpl,     setSavingTpl]     = useState(false);
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

    // Requete complete (avec tags et dernier message)
    const { data, error } = await supabase
      .from('conversations')
      .select(`
        id, updated_at, unread_staff, tags,
        student_profiles!student_profile_id(id, first_name, last_name, nationality),
        messages(content, created_at, sender_type)
      `)
      .order('updated_at', { ascending: false });

    if (!error) {
      setConversations((data ?? []).map(mapConv));
      if (isRefresh) setRefreshing(false); else setLoading(false);
      return;
    }

    console.warn('[MessagingPage] full query failed, trying fallback:', error.message);

    // Fallback sans tags ni messages imbriques (migration peut-etre pas appliquee)
    const { data: data2, error: error2 } = await supabase
      .from('conversations')
      .select(`
        id, updated_at, unread_staff,
        student_profiles!student_profile_id(id, first_name, last_name, nationality)
      `)
      .order('updated_at', { ascending: false });

    if (error2) {
      console.error('[MessagingPage] fallback error:', error2.message);
      setLoadError(`${error.message} | ${error2.message}`);
    } else {
      setConversations((data2 ?? []).map((c: any) => ({
        id:          c.id,
        updatedAt:   c.updated_at,
        unreadStaff: c.unread_staff ?? 0,
        student: {
          id:          c.student_profiles?.id ?? '',
          firstName:   c.student_profiles?.first_name ?? null,
          lastName:    c.student_profiles?.last_name ?? null,
          nationality: c.student_profiles?.nationality ?? null,
        },
        lastMessage: null,
        tags:        [],
      })));
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
            content:    msg.content ?? '',
            createdAt:  msg.created_at,
            fileUrl:    msg.file_url  ?? null,
            fileName:   msg.file_name ?? null,
          }]);
        }
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [loadConversations]);

  /*  Filtre search  */
  useEffect(() => {
    setPage(1);
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
      .select('id, sender_type, content, created_at, file_url, file_name')
      .eq('conversation_id', conv.id)
      .order('created_at', { ascending: true });

    if (error) {
      console.error('[MessagingPage] loadMessages error:', error);
    } else {
      setMessages((data ?? []).map((m: any) => ({
        id:         m.id,
        senderType: m.sender_type,
        content:    m.content ?? '',
        createdAt:  m.created_at,
        fileUrl:    m.file_url   ?? null,
        fileName:   m.file_name  ?? null,
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

  /*  Uploader une pièce jointe et envoyer le message  */
  const LARGE_THRESHOLD = 25 * 1024 * 1024; // 25 MB

  const sendAttachment = async (file: File) => {
    if (!selected) return;
    setSending(true);

    const isLarge = file.size > LARGE_THRESHOLD;
    const bucket  = isLarge ? 'large-file-transfers' : 'message-attachments';
    const ext     = file.name.split('.').pop() ?? 'bin';
    const path    = `staff/${Date.now()}.${ext}`;

    const { error: upErr } = await supabase.storage
      .from(bucket)
      .upload(path, file, { upsert: true });
    if (upErr) { console.error('[MessagingPage] upload error:', upErr); setSending(false); return; }

    let fileUrl: string;
    if (isLarge) {
      const { data: signed, error: signErr } = await supabase.storage
        .from(bucket)
        .createSignedUrl(path, 30 * 24 * 3600); // 30 jours
      if (signErr || !signed?.signedUrl) {
        console.error('[MessagingPage] sign error:', signErr);
        setSending(false);
        return;
      }
      fileUrl = signed.signedUrl;
    } else {
      fileUrl = supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl;
    }
    const { data: { user } } = await supabase.auth.getUser();
    const { data: msg, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: selected.id,
        sender_type:     'staff',
        sender_id:       user?.id ?? null,
        content:         '',
        file_url:        fileUrl,
        file_name:       file.name,
      })
      .select('id, sender_type, content, created_at, file_url, file_name')
      .single();

    if (!error && msg) {
      setMessages(prev => [...prev, {
        id:         msg.id,
        senderType: msg.sender_type,
        content:    msg.content ?? '',
        createdAt:  msg.created_at,
        fileUrl:    msg.file_url  ?? null,
        fileName:   msg.file_name ?? null,
      }]);
    }
    setSending(false);
  };

  /*  Envoyer un message texte  */
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
      .select('id, sender_type, content, created_at, file_url, file_name')
      .single();

    if (error) {
      console.error('[MessagingPage] sendReply error:', error);
    } else if (msg) {
      setMessages(prev => [...prev, {
        id:         msg.id,
        senderType: msg.sender_type,
        content:    msg.content ?? '',
        createdAt:  msg.created_at,
        fileUrl:    msg.file_url  ?? null,
        fileName:   msg.file_name ?? null,
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

  const totalPages   = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated    = useMemo(
    () => filtered.slice((page - 1) * pageSize, page * pageSize),
    [filtered, page, pageSize]
  );

  /* Templates */
  useEffect(() => {
    supabase
      .from('message_templates')
      .select('id, title, content')
      .order('created_at', { ascending: true })
      .then(({ data }) => setTemplates((data ?? []) as Template[]));
  }, []);

  const saveTpl = async () => {
    if (!newTplTitle.trim() || !newTplContent.trim()) return;
    setSavingTpl(true);
    const { data } = await supabase
      .from('message_templates')
      .insert({ title: newTplTitle.trim(), content: newTplContent.trim() })
      .select('id, title, content')
      .single();
    if (data) setTemplates(prev => [...prev, data as Template]);
    setNewTplTitle('');
    setNewTplContent('');
    setSavingTpl(false);
  };

  const deleteTpl = async (id: string) => {
    await supabase.from('message_templates').delete().eq('id', id);
    setTemplates(prev => prev.filter(t => t.id !== id));
  };

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
              <div className="mp-error-box" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 6 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                  </svg>
                  Erreur de chargement
                </div>
                <div style={{ fontSize: 11, opacity: .8, wordBreak: 'break-all' }}>{loadError}</div>
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
            ) : paginated.map(conv => {
              const [fg, bg] = avatarColor(fullName(conv.student));
              const active   = selected?.id === conv.id;
              const unread   = conv.unreadStaff > 0;
              return (
                <div
                  key={conv.id}
                  className={`mp-conv-item${active ? ' mp-conv-item--active' : unread ? ' mp-conv-item--unread' : ''}`}
                  onClick={() => openConversation(conv)}
                >
                  <div style={{ position: 'relative', flexShrink: 0 }}>
                    <div className="mp-avatar" style={{ background: bg, color: fg }}>
                      {initials(conv.student)}
                    </div>
                    {unread && (
                      <div style={{
                        position: 'absolute', top: -4, right: -4,
                        width: 10, height: 10, borderRadius: '50%',
                        background: colors.blue, border: '2px solid white',
                      }} />
                    )}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 6 }}>
                      <span style={{ fontWeight: unread ? 700 : 600, fontSize: 13, color: colors.textPrimary, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {fullName(conv.student)}
                      </span>
                      <span style={{ fontSize: 10.5, color: colors.textMuted, flexShrink: 0, fontWeight: unread ? 600 : 400 }}>
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
                        color: unread ? colors.textPrimary : colors.textMuted,
                        marginTop: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                        fontWeight: unread ? 600 : 400,
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
                  {unread && (
                    <div className="mp-unread-badge">{conv.unreadStaff}</div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Pagination sidebar */}
          {filtered.length > pageSize && (
            <div className="mp-sidebar-pagination">
              <Pagination
                page={page}
                totalPages={totalPages}
                total={filtered.length}
                pageSize={pageSize}
                onChange={p => setPage(p)}
                onPageSizeChange={size => { setPageSize(size); setPage(1); }}
                label="conversations"
              />
            </div>
          )}
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
                    <div style={{
                      width: 48, height: 48, borderRadius: 14, flexShrink: 0,
                      background: bg, color: fg,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 15, fontWeight: 800, fontFamily: fonts.display,
                      boxShadow: `0 0 0 3px white, 0 0 0 4px ${bg}`,
                    }}>
                      {initials(selected.student)}
                    </div>
                  );
                })()}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 800, fontSize: 16, color: colors.navy, fontFamily: fonts.display, letterSpacing: '-.2px' }}>
                      {fullName(selected.student)}
                    </span>
                    {selected.student.nationality && (
                      <span style={{
                        fontSize: 11.5, color: colors.textSecondary,
                        display: 'flex', alignItems: 'center', gap: 4,
                      }}>
                        <svg width={10} height={10} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
                        {selected.student.nationality}
                      </span>
                    )}
                  </div>
                  <div style={{ display: 'flex', gap: 5, marginTop: 9, flexWrap: 'wrap' }}>
                    {ALL_TAGS.map(t => {
                      const active = selected.tags.includes(t.key);
                      return (
                        <button
                          key={t.key}
                          onClick={() => toggleTag(selected.id, t.key)}
                          style={{
                            fontSize: 11, fontWeight: 700, padding: '4px 11px',
                            borderRadius: 20,
                            border: `1.5px solid ${active ? t.color : colors.borderInput}`,
                            background: active ? t.bg : 'white',
                            color: active ? t.color : colors.textMuted,
                            cursor: 'pointer', transition: 'all .15s',
                            boxShadow: active ? `0 1px 4px ${t.bg}` : 'none',
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
                ) : messages.map(msg => {
                  const isImg = msg.fileName
                    ? /\.(jpg|jpeg|png|gif|webp)$/i.test(msg.fileName)
                    : false;
                  return (
                    <div key={msg.id} className={`mp-bubble-wrap mp-bubble-wrap--${msg.senderType}`}>
                      <div className={`mp-bubble mp-bubble--${msg.senderType}`} style={{ padding: msg.fileUrl && !msg.content ? 0 : undefined, overflow: 'hidden' }}>
                        {/* Image inline */}
                        {msg.fileUrl && isImg && (
                          <a href={msg.fileUrl} target="_blank" rel="noreferrer">
                            <img
                              src={msg.fileUrl}
                              alt={msg.fileName ?? 'image'}
                              style={{ display: 'block', maxWidth: '100%', maxHeight: 260, borderRadius: msg.content ? '10px 10px 0 0' : 10, cursor: 'pointer' }}
                            />
                          </a>
                        )}
                        {/* Fichier téléchargeable */}
                        {msg.fileUrl && !isImg && (
                          <a
                            href={msg.fileUrl}
                            target="_blank"
                            rel="noreferrer"
                            style={{
                              display: 'flex', alignItems: 'center', gap: 7,
                              padding: '8px 12px',
                              color: msg.senderType === 'staff' ? 'rgba(255,255,255,0.9)' : '#2546cc',
                              textDecoration: 'none', fontSize: 12.5, fontWeight: 600,
                            }}
                          >
                            <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
                              <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/>
                            </svg>
                            {msg.fileName ?? 'Fichier joint'}
                          </a>
                        )}
                        {/* Texte */}
                        {msg.content && (
                          <span style={{ padding: msg.fileUrl ? '6px 14px 10px' : undefined, display: msg.fileUrl ? 'block' : undefined }}>
                            {msg.content}
                          </span>
                        )}
                      </div>
                      <div className="mp-bubble-time">{fmtTime(msg.createdAt)}</div>
                    </div>
                  );
                })}
                <div ref={bottomRef} />
              </div>

              {/* Reply */}
              <div className="mp-reply">
                {/* Template picker popover */}
                {showTemplates && (
                  <div className="mp-tpl-picker" onClick={e => e.stopPropagation()}>
                    <div className="mp-tpl-head">
                      <span>Reponses rapides</span>
                      <button
                        onClick={() => setShowTemplates(false)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#6b7a9e', fontSize: 16, lineHeight: 1, padding: '0 2px' }}
                      >x</button>
                    </div>
                    <div className="mp-tpl-list">
                      {templates.length === 0 ? (
                        <div style={{ padding: '14px 16px', fontSize: 12.5, color: '#6b7a9e', fontStyle: 'italic' }}>
                          Aucun template — creez-en un ci-dessous.
                        </div>
                      ) : templates.map(t => (
                        <div
                          key={t.id}
                          className="mp-tpl-item"
                          onClick={() => { setReply(t.content); setShowTemplates(false); }}
                        >
                          <div className="mp-tpl-title">
                            <span>{t.title}</span>
                            <button
                              className="mp-tpl-del"
                              onClick={e => { e.stopPropagation(); deleteTpl(t.id); }}
                              title="Supprimer"
                            >x</button>
                          </div>
                          <div className="mp-tpl-preview">{t.content}</div>
                        </div>
                      ))}
                    </div>
                    <div className="mp-tpl-new">
                      <input
                        className="mp-tpl-input"
                        placeholder="Titre du template (ex: Confirmation reception)"
                        value={newTplTitle}
                        onChange={e => setNewTplTitle(e.target.value)}
                      />
                      <textarea
                        className="mp-tpl-input"
                        rows={2}
                        placeholder="Contenu du message..."
                        value={newTplContent}
                        onChange={e => setNewTplContent(e.target.value)}
                        style={{ resize: 'none' }}
                      />
                      <button
                        className="mp-tpl-save"
                        disabled={!newTplTitle.trim() || !newTplContent.trim() || savingTpl}
                        onClick={saveTpl}
                      >
                        {savingTpl ? 'Enregistrement...' : 'Enregistrer'}
                      </button>
                    </div>
                  </div>
                )}

                <textarea
                  className="mp-textarea"
                  rows={3}
                  placeholder="Ecrire un message..."
                  value={reply}
                  onChange={e => setReply(e.target.value)}
                  onKeyDown={handleKeyDown}
                />
                <div className="mp-reply-actions">
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <button
                      className={`mp-tpl-btn${showTemplates ? ' mp-tpl-btn--active' : ''}`}
                      onClick={() => setShowTemplates(v => !v)}
                      title="Reponses rapides"
                    >
                      <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round">
                        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
                      </svg>
                      Templates
                    </button>
                    {/* Bouton pièce jointe */}
                    <label
                      title="Joindre un fichier"
                      style={{
                        display: 'inline-flex', alignItems: 'center', gap: 5,
                        padding: '5px 10px', borderRadius: 7, cursor: sending ? 'not-allowed' : 'pointer',
                        border: `1.5px solid ${colors.border}`, background: colors.pageBg,
                        fontSize: 12, fontWeight: 600, color: sending ? colors.textMuted : colors.blue,
                        opacity: sending ? 0.5 : 1, fontFamily: 'inherit',
                      }}
                    >
                      <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round">
                        <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/>
                      </svg>
                      Joindre
                      <input
                        type="file"
                        accept=".jpg,.jpeg,.png,.pdf,.doc,.docx"
                        style={{ display: 'none' }}
                        disabled={sending}
                        onChange={e => { const f = e.target.files?.[0]; if (f) sendAttachment(f); e.target.value = ''; }}
                      />
                    </label>
                    <span className="mp-reply-hint">Ctrl+Entree pour envoyer</span>
                  </div>
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
