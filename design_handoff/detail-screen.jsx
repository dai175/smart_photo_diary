// Diary Detail Screen — Hero variant.
// Inherits the list Hero card's visual language:
//   · photo as a true hero (full-bleed under the AppBar)
//   · uppercase accent date label as a third type tier
//   · bold tightened title
//   · filled 3-tone tag chips
// Drops the "card-in-card with icon + heading" chrome from the
// current detail screen; the page reads as one editorial spread.

// ─── icons ──────────────────────────────────────────────────────
function IconBack({ c, s = 22 }) { return (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
    <path d="M15 6l-6 6 6 6" stroke={c} strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);}
function IconShare({ c, s = 22 }) { return (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
    <path d="M12 4v12M12 4l-4 4M12 4l4 4" stroke={c} strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M5 14v5a1 1 0 001 1h12a1 1 0 001-1v-5" stroke={c} strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);}
function IconEdit({ c, s = 22 }) { return (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
    <path d="M4 20h4l10-10-4-4L4 16v4z" stroke={c} strokeWidth="2"
      strokeLinejoin="round"/>
    <path d="M13.5 6.5l4 4" stroke={c} strokeWidth="2" strokeLinecap="round"/>
  </svg>
);}
function IconMore({ c, s = 22 }) { return (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
    <circle cx="5" cy="12" r="1.7" fill={c}/>
    <circle cx="12" cy="12" r="1.7" fill={c}/>
    <circle cx="19" cy="12" r="1.7" fill={c}/>
  </svg>
);}

// ─── floating pill button (over photo) ──────────────────────────
function PillIcon({ children, dark = false }) {
  return (
    <div style={{
      width: 38, height: 38, borderRadius: 999,
      background: dark ? 'rgba(20,18,16,0.55)' : 'rgba(20,18,16,0.35)',
      backdropFilter: 'blur(14px) saturate(160%)',
      WebkitBackdropFilter: 'blur(14px) saturate(160%)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 1px 2px rgba(0,0,0,0.2)',
    }}>{children}</div>
  );
}

// ─── plain header button (over surface) ─────────────────────────
function FlatIconBtn({ children, tokens }) {
  return (
    <div style={{
      width: 38, height: 38, borderRadius: 999,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: tokens.title,
    }}>{children}</div>
  );
}

// ─── detail AppBar ──────────────────────────────────────────────
// overPhoto=true → floating pill buttons over scrim
function DetailAppBar({ tokens, overPhoto = false }) {
  const icon = overPhoto ? '#fff' : tokens.title;
  const Wrap = overPhoto ? PillIcon : ((p) => <FlatIconBtn tokens={tokens} {...p}/>);
  return (
    <div style={{
      position: overPhoto ? 'absolute' : 'static',
      top: overPhoto ? 54 : 'auto', left: 0, right: 0, zIndex: 5,
      display: 'flex', alignItems: 'center',
      padding: '8px 12px', height: 56, gap: 4,
    }}>
      <Wrap><IconBack c={icon}/></Wrap>
      <div style={{ flex: 1 }}/>
      <Wrap><IconShare c={icon}/></Wrap>
      <Wrap><IconEdit c={icon}/></Wrap>
      <Wrap><IconMore c={icon}/></Wrap>
    </div>
  );
}

// ─── small bits ─────────────────────────────────────────────────
function Divider({ tokens }) {
  return <div style={{ height: 1, background: tokens.divider, margin: '20px 0' }}/>;
}

function MetaRow({ label, value, tokens }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0' }}>
      <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.4,
        textTransform: 'uppercase', color: tokens.accentMuted }}>{label}</span>
      <span style={{ fontSize: 13, color: tokens.muted, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
    </div>
  );
}

// ─── inline photo gallery (for multi-photo entries) ─────────────
function InlineGallery({ photos, tokens }) {
  // First photo is the hero, remaining go here. Show up to 4 + overflow.
  const extra = photos.slice(1);
  if (extra.length === 0) return null;
  return (
    <div style={{ marginTop: 8 }}>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
        color: tokens.accentMuted, marginBottom: 10,
      }}>Gallery · {photos.length} photos</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6 }}>
        {extra.slice(0, 3).map((p, i) => (
          <div key={i} style={{
            aspectRatio: '1 / 1', borderRadius: 10, overflow: 'hidden',
            position: 'relative', background: tokens.photoFallback,
          }}>
            <img src={p} alt="" loading="lazy"
              style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
            {i === 2 && extra.length > 3 && (
              <div style={{
                position: 'absolute', inset: 0, background: 'rgba(20,18,16,0.55)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: '#fff', fontSize: 18, fontWeight: 700,
              }}>+{extra.length - 3}</div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── inline editable field (edit mode) ──────────────────────────
function EditField({ label, value, multiline = false, tokens, style = {} }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 0.8, textTransform: 'uppercase',
        color: tokens.accentMuted, marginBottom: 6,
      }}>{label}</div>
      <div style={{
        background: tokens.editFieldBg,
        border: `1px solid ${tokens.editFieldBorder}`,
        borderRadius: 12, padding: multiline ? '14px 14px' : '12px 14px',
        color: tokens.title,
        minHeight: multiline ? 160 : 'auto',
        ...style,
      }}>
        <div style={{
          color: tokens.title, fontSize: style.fontSize ?? 16,
          fontWeight: style.fontWeight ?? 400,
          lineHeight: style.lineHeight ?? 1.6,
          letterSpacing: style.letterSpacing ?? 0,
          whiteSpace: multiline ? 'pre-wrap' : 'nowrap',
        }}>{value}</div>
      </div>
    </div>
  );
}

function EditBottomBar({ tokens }) {
  return (
    <div style={{
      borderTop: `0.5px solid ${tokens.divider}`,
      background: tokens.surface,
      padding: '12px 20px 14px',
      display: 'flex', gap: 12,
    }}>
      <button style={{
        flex: 1, height: 46, borderRadius: 14, border: `1px solid ${tokens.chipOutline}`,
        background: 'transparent', color: tokens.title,
        fontSize: 15, fontWeight: 600, fontFamily: 'inherit',
        cursor: 'pointer',
      }}>Cancel</button>
      <button style={{
        flex: 1, height: 46, borderRadius: 14, border: 'none',
        background: tokens.navActive,
        color: tokens.surface,
        fontSize: 15, fontWeight: 700, fontFamily: 'inherit',
        cursor: 'pointer', letterSpacing: 0.2,
      }}>Save</button>
    </div>
  );
}

// ─── main DetailScreen ──────────────────────────────────────────
function DetailScreen({ tokens, entry, mode = 'read', meta }) {
  const isDark = tokens === window.darkTokens;
  const editing = mode === 'edit';
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
      color: tokens.title,
    }}>
      {/* status bar spacer */}
      <div style={{ height: 54, flexShrink: 0 }}/>

      {/* scroll surface (visual mock — overflow clipped) */}
      <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
        {/* ───── hero photo ─────────────────────────────────── */}
        <div style={{ position: 'relative', width: '100%', aspectRatio: '4 / 3' }}>
          <img src={entry.photos[0]} alt="" loading="lazy"
            style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
          {/* top scrim under the floating AppBar */}
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0, height: '45%',
            background: 'linear-gradient(180deg, rgba(20,18,16,0.45) 0%, rgba(20,18,16,0) 100%)',
            pointerEvents: 'none',
          }}/>
          {/* photo count pill (if more than 1) */}
          {entry.photos.length > 1 && (
            <div style={{
              position: 'absolute', right: 14, bottom: 14,
              padding: '6px 12px', borderRadius: 999,
              background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(10px)',
              color: '#fff', fontSize: 12, fontWeight: 700,
              display: 'inline-flex', alignItems: 'center', gap: 6,
            }}>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                <rect x="3" y="3" width="13" height="13" rx="2" stroke="#fff" strokeWidth="2"/>
                <rect x="8" y="8" width="13" height="13" rx="2" stroke="#fff" strokeWidth="2"/>
              </svg>
              1 / {entry.photos.length}
            </div>
          )}
          {/* floating AppBar */}
          <DetailAppBar tokens={tokens} overPhoto={true}/>
        </div>

        {/* ───── content ────────────────────────────────────── */}
        <div style={{ padding: '20px 20px 24px' }}>
          {/* date label (third tier) */}
          <div style={{
            fontSize: 12, fontWeight: 700, letterSpacing: 0.8,
            textTransform: 'uppercase', color: tokens.accentMuted,
            marginBottom: 10,
            display: 'flex', alignItems: 'center', gap: 8,
          }}>
            <span>{entry.fullDate || entry.date}</span>
            <span style={{ width: 3, height: 3, borderRadius: 999, background: tokens.accentMuted, opacity: 0.5 }}/>
            <span style={{ color: tokens.muted, fontWeight: 600, letterSpacing: 0.4 }}>{entry.dayOfWeek || 'Tue'}</span>
          </div>

          {/* title */}
          {editing ? (
            <EditField label="Title" value={entry.title} tokens={tokens}
              style={{ fontSize: 22, fontWeight: 700, lineHeight: 1.25, letterSpacing: -0.2 }}/>
          ) : (
            <div style={{
              fontSize: 26, fontWeight: 700, lineHeight: 1.22,
              color: tokens.title, letterSpacing: -0.3, marginBottom: 14,
              textWrap: 'pretty',
            }}>{entry.title}</div>
          )}

          {/* tags row */}
          {!editing && <TagRow tags={entry.tags} tokens={tokens}/>}

          <Divider tokens={tokens}/>

          {/* body */}
          {editing ? (
            <EditField label="Body" value={entry.body} multiline={true} tokens={tokens}
              style={{ fontSize: 15.5, fontWeight: 400, lineHeight: 1.7 }}/>
          ) : (
            <div style={{
              fontSize: 15.5, lineHeight: 1.75, color: tokens.body,
              letterSpacing: 0.05, textWrap: 'pretty',
            }}>{entry.body}</div>
          )}

          {/* additional photos */}
          {!editing && entry.photos.length > 1 && (
            <InlineGallery photos={entry.photos} tokens={tokens}/>
          )}

          {/* footer metadata */}
          {!editing && meta && (
            <>
              <Divider tokens={tokens}/>
              <div>
                {meta.map((m) => (
                  <MetaRow key={m.label} label={m.label} value={m.value} tokens={tokens}/>
                ))}
              </div>
            </>
          )}
        </div>
      </div>

      {/* bottom save/cancel bar in edit mode */}
      {editing && <EditBottomBar tokens={tokens}/>}

      {/* home indicator spacer */}
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

Object.assign(window, { DetailScreen });
