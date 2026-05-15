// Home Screen — Hero variant.
// Photo timeline of "today's photos" with the Hero language applied:
//   · uppercase accent weekday label tier → bold display headline
//   · usage pill in the top-right replaces the data_usage icon
//   · photos grouped by time-of-day with accent section labels
//   · selection state: warm accent border + filled check disc
//   · used photos: dimmed with a small "DIARY" chip
//   · Smart FAB upgrades:
//       - Camera state: stays a circular FAB
//       - Selection state: morphs into a wide pill action bar

// ─── photos (sample) ──────────────────────────────────────────
const HOME_PHOTOS = {
  cathedral: 'https://images.unsplash.com/photo-1548276145-69a9521f0499?w=600&q=80&auto=format&fit=crop',
  cat:       'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600&q=80&auto=format&fit=crop',
  sunset:    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600&q=80&auto=format&fit=crop',
  coffee:    'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=600&q=80&auto=format&fit=crop',
  street:    'https://images.unsplash.com/photo-1444723121867-7a241cacace9?w=600&q=80&auto=format&fit=crop',
  food:      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80&auto=format&fit=crop',
  garden:    'https://images.unsplash.com/photo-1416664806563-bb6be3b7e1bf?w=600&q=80&auto=format&fit=crop',
  reading:   'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&q=80&auto=format&fit=crop',
  desk:      'https://images.unsplash.com/photo-1499951360447-b19be8fe80f5?w=600&q=80&auto=format&fit=crop',
};

// ─── usage status pill ────────────────────────────────────────
function UsagePill({ used, limit, tokens, isPremium = false }) {
  const ratio = used / limit;
  const high = ratio > 0.85;
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 7,
      height: 32, padding: '0 12px 0 11px',
      borderRadius: 999,
      background: high ? tokens.usagePillWarnBg : tokens.usagePillBg,
      border: `0.5px solid ${high ? tokens.usagePillWarnBorder : tokens.usagePillBorder}`,
    }}>
      {isPremium ? (
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
          <path d="M12 2l3 6 6 1-4.5 4.5L18 20l-6-3-6 3 1.5-6.5L3 9l6-1z"
            fill={tokens.tagAccentFg}/>
        </svg>
      ) : (
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="9" stroke={high ? tokens.error : tokens.muted}
            strokeWidth="1.8"/>
          <path d="M12 7v5l3 2" stroke={high ? tokens.error : tokens.muted}
            strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      )}
      <span style={{
        fontSize: 12, fontWeight: 700, letterSpacing: 0.2,
        color: high ? tokens.error : tokens.title,
        fontVariantNumeric: 'tabular-nums',
      }}>{used}<span style={{ color: tokens.muted, fontWeight: 600 }}> / {limit}</span></span>
    </div>
  );
}

// ─── photo tile (selectable + used + locked) ──────────────────
function PhotoTile({ src, selected, used, locked, tokens, accent, span = 1 }) {
  return (
    <div style={{
      position: 'relative', borderRadius: 12, overflow: 'hidden',
      background: tokens.photoFallback,
      gridColumn: span > 1 ? `span ${span}` : 'auto',
      aspectRatio: span === 2 ? '2 / 1' : '1 / 1',
      cursor: 'pointer',
    }}>
      <img src={src} alt="" loading="lazy"
        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block',
          opacity: used ? 0.45 : (locked ? 0.55 : 1),
          filter: locked ? 'saturate(0.4)' : 'none',
        }}/>
      {/* selection ring */}
      {selected && !used && !locked && (
        <div style={{
          position: 'absolute', inset: 0, borderRadius: 12,
          boxShadow: `inset 0 0 0 2.5px ${accent}`,
          background: `${accent}22`,
          pointerEvents: 'none',
        }}/>
      )}
      {/* check disc */}
      {selected && !used && !locked && (
        <div style={{
          position: 'absolute', top: 8, right: 8,
          width: 24, height: 24, borderRadius: 999,
          background: accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 4px rgba(0,0,0,0.2)',
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
            <path d="M5 12l4 4 10-10" stroke="#fff" strokeWidth="2.8"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      )}
      {/* unselected hollow ring (hint that tile is selectable) */}
      {!selected && !used && !locked && (
        <div style={{
          position: 'absolute', top: 8, right: 8,
          width: 22, height: 22, borderRadius: 999,
          background: 'rgba(20,18,16,0.25)',
          backdropFilter: 'blur(10px)',
          border: '1.5px solid rgba(255,255,255,0.9)',
        }}/>
      )}
      {/* used badge */}
      {used && (
        <div style={{
          position: 'absolute', top: 8, left: 8,
          padding: '4px 8px', borderRadius: 999,
          background: 'rgba(20,18,16,0.7)', backdropFilter: 'blur(10px)',
          color: '#fff', fontSize: 10, fontWeight: 700, letterSpacing: 0.5,
          display: 'inline-flex', alignItems: 'center', gap: 4,
        }}>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
            <path d="M5 4h11a3 3 0 013 3v13H8a3 3 0 01-3-3V4z" stroke="#fff" strokeWidth="2.2"/>
            <path d="M5 17a3 3 0 013-3h11" stroke="#fff" strokeWidth="2.2"/>
          </svg>
          DIARY
        </div>
      )}
      {/* locked badge */}
      {locked && (
        <div style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'rgba(20,18,16,0.35)',
        }}>
          <div style={{
            padding: '5px 10px', borderRadius: 999,
            background: 'rgba(20,18,16,0.7)', backdropFilter: 'blur(10px)',
            color: '#fff', fontSize: 10, fontWeight: 700, letterSpacing: 0.5,
            display: 'inline-flex', alignItems: 'center', gap: 5,
          }}>
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
              <rect x="5" y="11" width="14" height="9" rx="2" stroke="#fff" strokeWidth="2"/>
              <path d="M8 11V7a4 4 0 018 0v4" stroke="#fff" strokeWidth="2"/>
            </svg>
            PREMIUM
          </div>
        </div>
      )}
    </div>
  );
}

// ─── time-of-day section ──────────────────────────────────────
function TimeSection({ label, sub, tokens, children }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <div style={{
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
        padding: '4px 4px 10px',
      }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
          color: tokens.accentMuted,
        }}>{label}</div>
        <div style={{ fontSize: 11, color: tokens.muted, fontWeight: 500 }}>{sub}</div>
      </div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6,
      }}>{children}</div>
    </div>
  );
}

// ─── circular FAB (camera state) ──────────────────────────────
function HomeFab({ tokens, accent }) {
  return (
    <div style={{
      position: 'absolute', right: 16, bottom: 16, zIndex: 4,
      width: 56, height: 56, borderRadius: 999,
      background: accent, color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 6px 20px rgba(184,133,108,0.4), 0 2px 6px rgba(0,0,0,0.15)',
    }}>
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
        <path d="M3 8a2 2 0 012-2h2l1.5-2h7L17 6h2a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"
          stroke="#fff" strokeWidth="2" strokeLinejoin="round"/>
        <circle cx="12" cy="13" r="3.5" stroke="#fff" strokeWidth="2"/>
      </svg>
    </div>
  );
}

// ─── wide selection action bar (selection state) ──────────────
// Replaces both the top "selection-bar" and the circular FAB when
// photos are selected. Single source of action.
function HomeSelectionBar({ count, tokens, accent }) {
  return (
    <div style={{
      position: 'absolute', left: 16, right: 16, bottom: 16, zIndex: 4,
      height: 56, borderRadius: 999,
      background: accent, color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '0 8px 0 22px',
      boxShadow: '0 8px 24px rgba(184,133,108,0.45), 0 2px 6px rgba(0,0,0,0.15)',
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span style={{
          fontSize: 19, fontWeight: 700, letterSpacing: -0.3,
          fontVariantNumeric: 'tabular-nums',
        }}>{count}</span>
        <span style={{ fontSize: 13, fontWeight: 600, opacity: 0.9 }}>
          photo{count > 1 ? 's' : ''} selected
        </span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
        <button style={{
          height: 40, padding: '0 14px', borderRadius: 999,
          background: 'rgba(255,255,255,0.18)',
          border: 'none', color: '#fff',
          fontSize: 13, fontWeight: 600, letterSpacing: 0.1,
          fontFamily: 'inherit', cursor: 'pointer',
        }}>Clear</button>
        <button style={{
          height: 40, padding: '0 16px', borderRadius: 999,
          background: '#fff', border: 'none',
          color: accent,
          fontSize: 14, fontWeight: 700, letterSpacing: 0.1,
          fontFamily: 'inherit', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', gap: 6,
        }}>
          Create diary
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
            <path d="M5 12h14M13 5l7 7-7 7" stroke="currentColor" strokeWidth="2.2"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
      </div>
    </div>
  );
}

// ─── empty state ──────────────────────────────────────────────
function HomeEmptyState({ tokens, accent }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      justifyContent: 'center', textAlign: 'center',
      padding: '60px 36px', gap: 16,
    }}>
      <div style={{
        width: 88, height: 88, borderRadius: 999,
        background: `${accent}1A`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none">
          <path d="M3 8a2 2 0 012-2h2l1.5-2h7L17 6h2a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"
            stroke={accent} strokeWidth="1.8" strokeLinejoin="round"/>
          <circle cx="12" cy="13" r="3.5" stroke={accent} strokeWidth="1.8"/>
        </svg>
      </div>
      <div style={{
        fontSize: 19, fontWeight: 700, color: tokens.title, letterSpacing: -0.2,
      }}>No photos from today yet</div>
      <div style={{
        fontSize: 13.5, color: tokens.muted, lineHeight: 1.5, maxWidth: 280,
      }}>Take a photo or wait until you snap one — your diary starts here.</div>
    </div>
  );
}

// ─── full home screen ─────────────────────────────────────────
// state: 'default' | 'selection' | 'empty'
function HomeScreen({ tokens, state = 'default' }) {
  const accent = tokens.calSelected;
  const isEmpty = state === 'empty';
  const inSelection = state === 'selection';

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
      color: tokens.title, position: 'relative',
    }}>
      <div style={{ height: 54, flexShrink: 0 }}/>

      {/* ───── header ──────────────────────────────────────── */}
      <div style={{
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
        padding: '14px 20px 4px',
      }}>
        <div>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1,
            textTransform: 'uppercase', color: tokens.accentMuted,
            marginBottom: 2,
          }}>Tuesday · Feb 18</div>
          <div style={{
            fontSize: 28, fontWeight: 700, color: tokens.title,
            letterSpacing: -0.4, lineHeight: 1.1,
          }}>Today</div>
        </div>
        <UsagePill used={12} limit={30} tokens={tokens}/>
      </div>

      {/* sub-instruction */}
      <div style={{
        padding: '8px 20px 16px', fontSize: 13.5, color: tokens.muted,
        lineHeight: 1.5,
      }}>
        {isEmpty
          ? 'Your day is just beginning.'
          : inSelection
            ? <>
              <span style={{ color: tokens.title, fontWeight: 600 }}>2 photos</span> ready
              to become one diary entry.
            </>
            : <>Tap photos from today to weave them into a diary entry.</>
        }
      </div>

      {/* ───── scrollable content ──────────────────────────── */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '4px 16px 80px' }}>
        {isEmpty ? (
          <HomeEmptyState tokens={tokens} accent={accent}/>
        ) : (
          <>
            <TimeSection label="Morning · 7:00–11:00" sub="3 photos" tokens={tokens}>
              <PhotoTile src={HOME_PHOTOS.coffee}   tokens={tokens} accent={accent} used={true}/>
              <PhotoTile src={HOME_PHOTOS.reading}  tokens={tokens} accent={accent}/>
              <PhotoTile src={HOME_PHOTOS.garden}   tokens={tokens} accent={accent}/>
            </TimeSection>

            <TimeSection label="Afternoon · 12:00–17:00" sub="3 photos" tokens={tokens}>
              <PhotoTile src={HOME_PHOTOS.food}   tokens={tokens} accent={accent}
                selected={inSelection}/>
              <PhotoTile src={HOME_PHOTOS.street} tokens={tokens} accent={accent}
                selected={inSelection}/>
              <PhotoTile src={HOME_PHOTOS.desk}   tokens={tokens} accent={accent}/>
            </TimeSection>

            <TimeSection label="Evening · 18:00–23:00" sub="3 photos · 1 locked" tokens={tokens}>
              <PhotoTile src={HOME_PHOTOS.sunset}   tokens={tokens} accent={accent}/>
              <PhotoTile src={HOME_PHOTOS.cathedral} tokens={tokens} accent={accent}/>
              <PhotoTile src={HOME_PHOTOS.cat}      tokens={tokens} accent={accent} locked={true}/>
            </TimeSection>
          </>
        )}
      </div>

      {/* ───── FAB / selection bar ─────────────────────────── */}
      {!isEmpty && (inSelection
        ? <HomeSelectionBar count={2} tokens={tokens} accent={accent}/>
        : <HomeFab tokens={tokens} accent={accent}/>
      )}
      {isEmpty && <HomeFab tokens={tokens} accent={accent}/>}

      {/* ───── bottom tab nav ──────────────────────────────── */}
      <BottomNav tokens={tokens} active="home"/>
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

Object.assign(window, {
  HomeScreen: HomeScreen, HomePhotoTile: PhotoTile, HomeUsagePill: UsagePill,
});
