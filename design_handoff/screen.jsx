// DiaryScreen — minimal mock of the Flutter screen surrounding the cards.
// Renders the in-app AppBar ("Diaries" + search + filter), a scrollable
// list of cards, and the bottom tab nav (Diary tab active).

function DiaryAppBar({ tokens }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '8px 8px 8px 20px', height: 56,
      background: tokens.surface,
    }}>
      <div style={{
        fontSize: 22, fontWeight: 600, color: tokens.title,
        letterSpacing: 0.1,
      }}>Diaries</div>
      <div style={{ display: 'flex', gap: 4 }}>
        {/* search */}
        <button style={btnReset(tokens)}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <circle cx="11" cy="11" r="7" stroke={tokens.title} strokeWidth="2"/>
            <path d="M20 20l-3.5-3.5" stroke={tokens.title} strokeWidth="2" strokeLinecap="round"/>
          </svg>
        </button>
        {/* filter */}
        <button style={btnReset(tokens)}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path d="M4 6h16M7 12h10M10 18h4" stroke={tokens.title} strokeWidth="2" strokeLinecap="round"/>
          </svg>
        </button>
      </div>
    </div>
  );
}

function btnReset(tokens) {
  return {
    width: 44, height: 44, borderRadius: 12, border: 'none',
    background: 'transparent', cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    color: tokens.title,
  };
}

function BottomNav({ tokens, active = 'diary' }) {
  const items = [
    { id: 'home', label: 'Home', icon: (c) => (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
        <path d="M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-7h-6v7H4a1 1 0 01-1-1v-9z"
          stroke={c} strokeWidth="1.8" strokeLinejoin="round"/>
      </svg>
    )},
    { id: 'diary', label: 'Diary', icon: (c) => (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
        <path d="M5 4h11a3 3 0 013 3v13H8a3 3 0 01-3-3V4z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/>
        <path d="M5 17a3 3 0 013-3h11" stroke={c} strokeWidth="1.8"/>
      </svg>
    )},
    { id: 'stats', label: 'Statistics', icon: (c) => (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
        <path d="M5 20V10M12 20V4M19 20v-7" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
      </svg>
    )},
    { id: 'settings', label: 'Settings', icon: (c) => (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
        <circle cx="12" cy="12" r="3" stroke={c} strokeWidth="1.8"/>
        <path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4"
          stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
      </svg>
    )},
  ];
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-around', alignItems: 'flex-start',
      padding: '10px 0 6px',
      background: tokens.surface,
      borderTop: `0.5px solid ${tokens.divider}`,
    }}>
      {items.map((it) => {
        const isActive = it.id === active;
        const c = isActive ? tokens.navActive : tokens.navInactive;
        return (
          <div key={it.id} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            color: c,
          }}>
            {it.icon(c)}
            <div style={{ fontSize: 11, fontWeight: isActive ? 600 : 500, letterSpacing: 0.2 }}>
              {it.label}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// The full screen shell used inside each iPhone artboard.
function DiaryScreen({ tokens, entries, Card, sectionLabel }) {
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
      color: tokens.title,
    }}>
      {/* status bar spacer */}
      <div style={{ height: 54, flexShrink: 0 }}/>
      <DiaryAppBar tokens={tokens}/>
      {sectionLabel && (
        <div style={{
          padding: '4px 20px 8px', fontSize: 11, fontWeight: 700,
          letterSpacing: 1, textTransform: 'uppercase',
          color: tokens.accentMuted,
        }}>{sectionLabel}</div>
      )}
      <div style={{
        flex: 1, overflow: 'hidden', // visual mock, no scroll needed
        padding: '8px 16px 16px',
        display: 'flex', flexDirection: 'column', gap: 16,
      }}>
        {entries.map((e, i) => <Card key={i} entry={e} tokens={tokens}/>)}
      </div>
      <BottomNav tokens={tokens}/>
      {/* home indicator handled by IOSDevice */}
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

Object.assign(window, { DiaryScreen, DiaryAppBar, BottomNav });
