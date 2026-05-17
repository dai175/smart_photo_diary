// Settings Screen — Hero variant.
// The Hero moves applied to settings:
//   · header tier: accent label "ACCOUNT" → bold "Settings"
//   · plan card as the page hero (big display numerals for usage,
//     same vocabulary as the statistics cards)
//   · sections become flat groups headed by uppercase accent labels —
//     no more single nested CustomCard wrapping every section
//   · rows lose the heavy circle icon; the icon is a quiet accent glyph,
//     title takes the weight, subtitle is muted

// ─── row ──────────────────────────────────────────────────────
function SettingsRowH({ icon, title, subtitle, trailing, tokens, danger = false }) {
  const titleColor = danger ? tokens.error : tokens.title;
  return (
    <div style={{
      display: 'flex', alignItems: 'center',
      padding: '14px 16px', gap: 14, cursor: 'pointer',
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: danger ? tokens.usagePillWarnBg : tokens.glyphBg,
        color: danger ? tokens.error : tokens.accentMuted,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 15, fontWeight: 600, color: titleColor,
          letterSpacing: -0.1, lineHeight: 1.3,
        }}>{title}</div>
        {subtitle && (
          <div style={{
            fontSize: 12.5, color: tokens.muted, marginTop: 2,
            lineHeight: 1.4,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{subtitle}</div>
        )}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexShrink: 0 }}>
        {trailing}
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <path d="M9 6l6 6-6 6" stroke={tokens.muted} strokeWidth="2"
            strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
    </div>
  );
}

function RowDividerS({ tokens }) {
  return <div style={{ height: 0.5, background: tokens.divider, marginLeft: 66 }}/>;
}

// ─── grouped section ──────────────────────────────────────────
function SettingsGroup({ label, tokens, children }) {
  return (
    <div style={{ marginBottom: 22 }}>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
        color: tokens.accentMuted, padding: '4px 6px 10px',
      }}>{label}</div>
      <div style={{
        background: tokens.cardBg, borderRadius: 16,
        border: tokens.cardBorder, boxShadow: tokens.cardShadow,
        overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
}

// ─── plan card (page hero) ────────────────────────────────────
function PlanCard({ tokens, isPremium = false, used = 12, limit = 30 }) {
  const accent = tokens.calSelected;
  const remaining = limit - used;
  const ratio = used / limit;
  return (
    <div style={{
      borderRadius: 20,
      background: isPremium ? tokens.statCardAccent : tokens.cardBg,
      border: tokens.cardBorder,
      boxShadow: tokens.cardShadow,
      padding: '18px 18px 16px', marginBottom: 22,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          padding: '4px 10px', borderRadius: 999,
          background: isPremium ? '#fff' : tokens.tagPrimaryBg,
          color: isPremium ? tokens.tagAccentFg : tokens.tagPrimaryFg,
          fontSize: 10.5, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
        }}>
          {isPremium && (
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
              <path d="M12 2l3 6 6 1-4.5 4.5L18 20l-6-3-6 3 1.5-6.5L3 9l6-1z"
                fill={tokens.tagAccentFg}/>
            </svg>
          )}
          {isPremium ? 'Premium (monthly)' : 'Basic plan'}
        </div>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <path d="M9 6l6 6-6 6" stroke={tokens.muted} strokeWidth="2"
            strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>

      <div style={{ marginTop: 14, marginBottom: 10 }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.9, textTransform: 'uppercase',
          color: tokens.accentMuted, marginBottom: 4,
        }}>This month</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
          <span style={{
            fontSize: 36, fontWeight: 700, lineHeight: 1, letterSpacing: -1,
            color: tokens.title, fontVariantNumeric: 'tabular-nums',
          }}>{used}</span>
          <span style={{
            fontSize: 16, fontWeight: 500, color: tokens.muted,
            fontVariantNumeric: 'tabular-nums',
          }}>/ {limit} diaries</span>
          <span style={{ flex: 1 }}/>
          <span style={{
            fontSize: 12, fontWeight: 600, color: tokens.muted,
          }}>{remaining} left · resets Mar 1</span>
        </div>
      </div>

      {/* progress track */}
      <div style={{
        height: 6, borderRadius: 999, background: tokens.divider, overflow: 'hidden',
        marginBottom: 14,
      }}>
        <div style={{
          height: '100%', width: `${Math.min(100, ratio * 100)}%`,
          background: ratio > 0.85 ? tokens.error : accent,
          borderRadius: 999,
        }}/>
      </div>

      {!isPremium && (
        <button style={{
          width: '100%', height: 44, borderRadius: 12, border: 'none',
          background: accent, color: '#fff',
          fontSize: 14, fontWeight: 700, letterSpacing: 0.2,
          fontFamily: 'inherit', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 7,
        }}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
            <path d="M12 2l3 6 6 1-4.5 4.5L18 20l-6-3-6 3 1.5-6.5L3 9l6-1z" fill="#fff"/>
          </svg>
          Upgrade to Premium
        </button>
      )}
      {isPremium && (
        <div style={{
          fontSize: 12, color: tokens.muted, padding: '4px 0 0',
        }}>Auto-renews on Aug 18 · Manage subscription</div>
      )}
    </div>
  );
}

// ─── icons (lean line) ────────────────────────────────────────
const Ico = {
  theme: (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 3a9 9 0 109 9 7 7 0 01-9-9z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/></svg>,
  lang:  (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke={c} strokeWidth="1.8"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18" stroke={c} strokeWidth="1.8"/></svg>,
  diary: (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M4 7h12M4 12h16M4 17h10" stroke={c} strokeWidth="2" strokeLinecap="round"/></svg>,
  photo: (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><rect x="3" y="5" width="18" height="14" rx="2" stroke={c} strokeWidth="1.8"/><circle cx="9" cy="11" r="2" stroke={c} strokeWidth="1.8"/><path d="M3 17l5-4 5 4 4-3 4 3" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/></svg>,
  backup: (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 3v12M12 15l-4-4M12 15l4-4" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/><path d="M4 17v2a1 1 0 001 1h14a1 1 0 001-1v-2" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
  restore: (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 21V9M12 9l-4 4M12 9l4 4" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/><path d="M4 7V5a1 1 0 011-1h14a1 1 0 011 1v2" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
  info:    (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke={c} strokeWidth="1.8"/><path d="M12 11v6M12 8v.5" stroke={c} strokeWidth="2" strokeLinecap="round"/></svg>,
  privacy: (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 3l8 3v6c0 4-3.5 7.5-8 9-4.5-1.5-8-5-8-9V6l8-3z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/></svg>,
  license: (c) => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M6 3h9l5 5v13H6z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/><path d="M15 3v5h5M8 13h8M8 17h6" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
};

// ─── settings screen ──────────────────────────────────────────
function SettingsScreen({ tokens, isPremium = false }) {
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
      color: tokens.title,
    }}>
      <div style={{ height: 54, flexShrink: 0 }}/>

      {/* header */}
      <div style={{ padding: '14px 20px 6px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
          color: tokens.accentMuted, marginBottom: 2,
        }}>Account</div>
        <div style={{
          fontSize: 28, fontWeight: 700, color: tokens.title,
          letterSpacing: -0.4, lineHeight: 1.1,
        }}>Settings</div>
      </div>

      {/* scrollable body */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 16px 16px' }}>
        <PlanCard tokens={tokens} isPremium={isPremium} used={isPremium ? 47 : 12}
          limit={isPremium ? 100 : 30}/>

        <SettingsGroup label="Appearance" tokens={tokens}>
          <SettingsRowH tokens={tokens} icon={Ico.theme(tokens.accentMuted)}
            title="Theme" subtitle="Light"/>
          <RowDividerS tokens={tokens}/>
          <SettingsRowH tokens={tokens} icon={Ico.lang(tokens.accentMuted)}
            title="Language" subtitle="Follow system"/>
        </SettingsGroup>

        <SettingsGroup label="Diary & Photos" tokens={tokens}>
          <SettingsRowH tokens={tokens} icon={Ico.diary(tokens.accentMuted)}
            title="Diary length" subtitle="Short (for X posts)"/>
          <RowDividerS tokens={tokens}/>
          <SettingsRowH tokens={tokens} icon={Ico.photo(tokens.accentMuted)}
            title="Image type" subtitle="Photos only"/>
        </SettingsGroup>

        <SettingsGroup label="Data" tokens={tokens}>
          <SettingsRowH tokens={tokens} icon={Ico.backup(tokens.accentMuted)}
            title="Backup" subtitle="Save your diaries to a file"/>
          <RowDividerS tokens={tokens}/>
          <SettingsRowH tokens={tokens} icon={Ico.restore(tokens.accentMuted)}
            title="Restore" subtitle="Import diaries from a file"/>
        </SettingsGroup>

        <SettingsGroup label="About" tokens={tokens}>
          <SettingsRowH tokens={tokens} icon={Ico.info(tokens.accentMuted)}
            title="App version" subtitle="1.8.12 (1)"/>
          <RowDividerS tokens={tokens}/>
          <SettingsRowH tokens={tokens} icon={Ico.privacy(tokens.accentMuted)}
            title="Privacy policy" subtitle="How your data is handled"/>
          <RowDividerS tokens={tokens}/>
          <SettingsRowH tokens={tokens} icon={Ico.license(tokens.accentMuted)}
            title="Open-source licenses" subtitle="Third-party libraries"/>
        </SettingsGroup>
      </div>

      <BottomNav tokens={tokens} active="settings"/>
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

Object.assign(window, { SettingsScreen, SettingsGroup, SettingsRowH, PlanCard });
