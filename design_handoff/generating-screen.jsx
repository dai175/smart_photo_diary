// GeneratingScreen — the screen shown while the AI composes the diary
// entry. Three takes on the same content (photos, prompt, status) that
// inherit the Hero language used across the redesigned app: editorial
// hero photo, ACCENT eyebrow → bold headline, no per-section CustomCard
// chrome, tag-style filled chips, hairline dividers.
//
// Variants
//   A · Calm editorial    — quietest, single slim progress bar.
//   B · Staged             — vertical stage list (read → sense → compose
//                            → polish) with current step pulsing.
//   C · Skeleton preview   — shows where the finished entry will appear,
//                            with shimmering placeholders.

// ─── one-time keyframes injection ──────────────────────────────
if (typeof document !== 'undefined' && !document.getElementById('gen-styles')) {
  const s = document.createElement('style');
  s.id = 'gen-styles';
  s.textContent = [
    '@keyframes gen-shimmer{0%{background-position:-220px 0}100%{background-position:220px 0}}',
    '@keyframes gen-pulse{0%,100%{opacity:.6}50%{opacity:1}}',
    '@keyframes gen-indet{0%{transform:translateX(-100%)}100%{transform:translateX(220%)}}',
    '@keyframes gen-dot{0%,80%,100%{opacity:.25;transform:translateY(0)}',
    '  40%{opacity:1;transform:translateY(-2px)}}',
    '.gen-shimmer{background:linear-gradient(90deg,',
    '  var(--gen-shimmer-base) 0%, var(--gen-shimmer-hi) 50%, var(--gen-shimmer-base) 100%);',
    '  background-size:220px 100%;background-repeat:no-repeat;',
    '  background-color:var(--gen-shimmer-base);',
    '  animation:gen-shimmer 1.4s linear infinite}',
    '.gen-pulse{animation:gen-pulse 1.6s ease-in-out infinite}',
    '.gen-indet{animation:gen-indet 1.4s cubic-bezier(.4,0,.2,1) infinite}',
    '.gen-dot{display:inline-block;animation:gen-dot 1.2s ease-in-out infinite}',
    '.gen-dot:nth-child(2){animation-delay:.15s}',
    '.gen-dot:nth-child(3){animation-delay:.3s}',
  ].join('\n');
  document.head.appendChild(s);
}

// ─── icons (kept local to avoid load-order coupling) ───────────
function GenIconBack({ c, s = 22 }) { return (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
    <path d="M15 6l-6 6 6 6" stroke={c} strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);}
function GenIconCheck({ c, s = 14 }) { return (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
    <path d="M5 12l4.5 4.5L19 7" stroke={c} strokeWidth="2.4"
      strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);}
function GenIconSparkle({ c, s = 14 }) { return (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
    <path d="M12 3l1.6 4.4 4.4 1.6-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6L12 3z"
      stroke={c} strokeWidth="1.6" strokeLinejoin="round"/>
    <path d="M19 15.5l.7 1.8 1.8.7-1.8.7L19 20.5l-.7-1.8-1.8-.7 1.8-.7L19 15.5z"
      fill={c}/>
  </svg>
);}

// ─── shared bits ───────────────────────────────────────────────
function GenAppBar({ tokens, label }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', height: 56,
      padding: '8px 8px 8px 8px', background: 'transparent',
      position: 'relative',
    }}>
      <button style={{
        width: 44, height: 44, borderRadius: 12, border: 'none',
        background: 'transparent', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: tokens.title,
      }}>
        <GenIconBack c={tokens.title}/>
      </button>
      {label && (
        <div style={{
          position: 'absolute', left: 0, right: 0, textAlign: 'center',
          pointerEvents: 'none',
          fontSize: 11, fontWeight: 700, letterSpacing: 1,
          textTransform: 'uppercase', color: tokens.accentMuted,
        }}>{label}</div>
      )}
    </div>
  );
}

// Indeterminate slim track. Used in A and B; C uses a thicker variant.
function GenProgressTrack({ tokens, thick = false }) {
  const isDark = tokens === window.darkTokens;
  return (
    <div style={{
      width: '100%', height: thick ? 4 : 3,
      borderRadius: 999, overflow: 'hidden',
      background: isDark ? 'rgba(255,255,255,0.06)' : 'rgba(35,30,26,0.06)',
      position: 'relative',
    }}>
      <div className="gen-indet" style={{
        position: 'absolute', top: 0, bottom: 0, width: '45%',
        borderRadius: 999, background: tokens.accentMuted,
      }}/>
    </div>
  );
}

function GenDateLine({ tokens, date, dayOfWeek }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      fontSize: 12, fontWeight: 700, letterSpacing: 0.8,
      textTransform: 'uppercase', color: tokens.accentMuted,
    }}>
      <span>{date}</span>
      <span style={{ width: 3, height: 3, borderRadius: 999,
        background: tokens.accentMuted, opacity: 0.5 }}/>
      <span style={{ color: tokens.muted, fontWeight: 600, letterSpacing: 0.4 }}>
        {dayOfWeek}
      </span>
    </div>
  );
}

// Animated three-dot tail for headline ("Writing your diary").
function GenDots({ tokens }) {
  return (
    <span style={{ marginLeft: 2, color: tokens.accentMuted, fontWeight: 700 }}>
      <span className="gen-dot">.</span>
      <span className="gen-dot">.</span>
      <span className="gen-dot">.</span>
    </span>
  );
}

// ─── sample data ───────────────────────────────────────────────
const GEN_DEFAULT = {
  date: 'MAY 16, 2026',
  dayOfWeek: 'Saturday',
  promptCategory: 'Emotion',
  promptText: 'What was the very first feeling that surfaced in this moment?',
  photos: [
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=800&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=800&q=80&auto=format&fit=crop',
  ],
  photoCount: 3,
};

// ════════════════════════════════════════════════════════════════
// Variant A · Calm editorial
// ════════════════════════════════════════════════════════════════
function GeneratingScreenEditorial({ tokens, data = GEN_DEFAULT, progress = 0.5 }) {
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface, color: tokens.title,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
    }}>
      <div style={{ height: 54, flexShrink: 0 }}/>
      <GenAppBar tokens={tokens}/>

      <div style={{ flex: 1, padding: '4px 20px 0', overflow: 'hidden' }}>
        {/* eyebrow + headline */}
        <GenDateLine tokens={tokens} date={data.date} dayOfWeek={data.dayOfWeek}/>
        <div style={{ height: 8 }}/>
        <div style={{
          fontSize: 26, fontWeight: 700, lineHeight: 1.22, letterSpacing: -0.3,
          color: tokens.title, textWrap: 'pretty',
        }}>
          Writing your diary<GenDots tokens={tokens}/>
        </div>

        {/* prompt — quiet italic, no card */}
        <div style={{ marginTop: 18,
          paddingLeft: 14, borderLeft: `2px solid ${tokens.chipOutline}` }}>
          <div style={{
            fontSize: 10.5, fontWeight: 700, letterSpacing: 0.9,
            textTransform: 'uppercase', color: tokens.muted, marginBottom: 4,
          }}>Prompt · {data.promptCategory}</div>
          <div style={{
            fontSize: 14.5, lineHeight: 1.55, fontStyle: 'italic',
            color: tokens.body || tokens.title, fontWeight: 400,
            letterSpacing: 0.05,
          }}>"{data.promptText}"</div>
        </div>

        {/* hairline */}
        <div style={{ height: 1, background: tokens.divider, margin: '24px 0' }}/>

        {/* selected photos — quiet strip, no card chrome */}
        <div style={{
          fontSize: 10.5, fontWeight: 700, letterSpacing: 0.9,
          textTransform: 'uppercase', color: tokens.muted, marginBottom: 10,
        }}>{data.photoCount} photo{data.photoCount > 1 ? 's' : ''} selected</div>
        <div style={{ display: 'flex', gap: 8 }}>
          {data.photos.slice(0, 4).map((p, i) => (
            <div key={i} style={{
              flex: 1, aspectRatio: '1 / 1', borderRadius: 10, overflow: 'hidden',
              background: tokens.photoFallback, position: 'relative',
              boxShadow: tokens.photoInner,
            }}>
              <img src={p} alt="" loading="lazy"
                style={{ width: '100%', height: '100%', objectFit: 'cover',
                  display: 'block', filter: 'saturate(0.92)' }}/>
            </div>
          ))}
        </div>
      </div>

      {/* status footer — slim, anchored to the bottom */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: 8,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <GenIconSparkle c={tokens.accentMuted} s={14}/>
            <span className="gen-pulse" style={{
              fontSize: 13.5, fontWeight: 600, color: tokens.title,
              letterSpacing: -0.1,
            }}>Composing</span>
          </div>
          <div style={{
            fontSize: 11.5, fontWeight: 600, color: tokens.muted,
            letterSpacing: 0.3, fontVariantNumeric: 'tabular-nums',
          }}>Step 3 of 4</div>
        </div>
        <GenProgressTrack tokens={tokens}/>
      </div>
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// Variant B · Staged
// ════════════════════════════════════════════════════════════════
const GEN_STAGES = [
  { id: 'read',    label: 'Reading 3 photos',  caption: 'Looking at what you captured.' },
  { id: 'sense',   label: 'Sensing the mood',  caption: 'Light, colour, what stands out.' },
  { id: 'compose', label: 'Composing',          caption: 'Drafting in your voice.' },
  { id: 'polish',  label: 'Polishing',          caption: 'Title, tags, final pass.' },
];

function GenStageRow({ stage, status, tokens, last }) {
  const isDark = tokens === window.darkTokens;
  // completed → check disc in accentMuted
  // active    → pulsing ring in accentMuted
  // pending   → muted hollow disc
  const accent = tokens.accentMuted;
  let disc;
  if (status === 'done') {
    disc = (
      <div style={{
        width: 28, height: 28, borderRadius: 999,
        background: isDark ? 'rgba(212,166,142,0.22)' : 'rgba(184,133,108,0.18)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <GenIconCheck c={accent} s={14}/>
      </div>
    );
  } else if (status === 'active') {
    disc = (
      <div className="gen-pulse" style={{
        width: 28, height: 28, borderRadius: 999,
        background: accent,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 0 0 5px ${isDark ? 'rgba(212,166,142,0.18)' : 'rgba(184,133,108,0.14)'}`,
      }}>
        <GenIconSparkle c="#fff" s={14}/>
      </div>
    );
  } else {
    disc = (
      <div style={{
        width: 28, height: 28, borderRadius: 999,
        border: `1.5px solid ${tokens.chipOutline}`,
        background: 'transparent',
      }}/>
    );
  }

  const titleColor = status === 'pending' ? tokens.muted : tokens.title;
  const titleWeight = status === 'active' ? 700 : 600;
  return (
    <div style={{ display: 'flex', gap: 14, position: 'relative' }}>
      {/* connector */}
      {!last && (
        <div style={{
          position: 'absolute', left: 14, top: 30, bottom: -22, width: 1.5,
          background: tokens.divider,
        }}/>
      )}
      <div style={{ flexShrink: 0, position: 'relative', zIndex: 1 }}>{disc}</div>
      <div style={{ flex: 1, paddingTop: 1 }}>
        <div style={{
          fontSize: 15, fontWeight: titleWeight, color: titleColor,
          letterSpacing: -0.1, lineHeight: 1.3,
        }}>
          {stage.label}
          {status === 'active' && <GenDots tokens={tokens}/>}
        </div>
        <div style={{
          fontSize: 12.5, color: tokens.muted, lineHeight: 1.45,
          marginTop: 2,
        }}>{stage.caption}</div>
      </div>
    </div>
  );
}

function GeneratingScreenStaged({ tokens, data = GEN_DEFAULT, activeIndex = 2 }) {
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface, color: tokens.title,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
    }}>
      <div style={{ height: 54, flexShrink: 0 }}/>
      <GenAppBar tokens={tokens}/>

      <div style={{ flex: 1, padding: '4px 20px 0', overflow: 'hidden' }}>
        <GenDateLine tokens={tokens} date={data.date} dayOfWeek={data.dayOfWeek}/>
        <div style={{ height: 8 }}/>
        <div style={{
          fontSize: 26, fontWeight: 700, lineHeight: 1.22, letterSpacing: -0.3,
          color: tokens.title, textWrap: 'pretty',
        }}>
          Writing your diary<GenDots tokens={tokens}/>
        </div>

        {/* photo strip — anchors the user's selection without taking centre stage */}
        <div style={{ display: 'flex', gap: 6, marginTop: 18 }}>
          {data.photos.slice(0, 4).map((p, i) => (
            <div key={i} style={{
              width: 52, height: 52, borderRadius: 10, overflow: 'hidden',
              background: tokens.photoFallback, boxShadow: tokens.photoInner,
            }}>
              <img src={p} alt="" loading="lazy"
                style={{ width: '100%', height: '100%', objectFit: 'cover',
                  display: 'block' }}/>
            </div>
          ))}
          <div style={{
            marginLeft: 'auto', alignSelf: 'flex-end',
            fontSize: 11, fontWeight: 600, color: tokens.muted,
            letterSpacing: 0.3,
          }}>{data.photoCount} photos · {data.promptCategory.toLowerCase()} prompt</div>
        </div>

        {/* hairline */}
        <div style={{ height: 1, background: tokens.divider, margin: '24px 0' }}/>

        {/* stage list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 22 }}>
          {GEN_STAGES.map((s, i) => (
            <GenStageRow key={s.id} stage={s} tokens={tokens}
              status={i < activeIndex ? 'done' : i === activeIndex ? 'active' : 'pending'}
              last={i === GEN_STAGES.length - 1}/>
          ))}
        </div>
      </div>

      {/* progress at very bottom */}
      <div style={{ padding: '0 20px 20px' }}>
        <GenProgressTrack tokens={tokens}/>
      </div>
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// Variant C · Skeleton preview
// ════════════════════════════════════════════════════════════════
function GenSkel({ w = '100%', h = 14, r = 6, tokens, style = {} }) {
  const isDark = tokens === window.darkTokens;
  return (
    <div className="gen-shimmer" style={{
      width: w, height: h, borderRadius: r,
      '--gen-shimmer-base': isDark ? 'rgba(255,255,255,0.05)' : 'rgba(35,30,26,0.05)',
      '--gen-shimmer-hi':   isDark ? 'rgba(255,255,255,0.10)' : 'rgba(35,30,26,0.09)',
      ...style,
    }}/>
  );
}

function GeneratingScreenSkeleton({ tokens, data = GEN_DEFAULT }) {
  const isDark = tokens === window.darkTokens;
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface, color: tokens.title,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
      position: 'relative',
    }}>
      <div style={{ height: 54, flexShrink: 0 }}/>

      {/* hero photo (matches the detail screen layout exactly) */}
      <div style={{ position: 'relative', width: '100%', aspectRatio: '4 / 3' }}>
        <img src={data.photos[0]} alt="" loading="lazy"
          style={{ width: '100%', height: '100%', objectFit: 'cover',
            display: 'block', filter: 'saturate(0.9)' }}/>
        {/* top scrim for AppBar legibility */}
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: '45%',
          background: 'linear-gradient(180deg, rgba(20,18,16,0.45) 0%, rgba(20,18,16,0) 100%)',
          pointerEvents: 'none',
        }}/>
        {/* floating back button */}
        <div style={{
          position: 'absolute', top: -56, left: 0, right: 0,
          height: 56, padding: '8px 8px 8px 8px',
          display: 'flex', alignItems: 'center',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 999,
            background: 'rgba(0,0,0,0.42)', backdropFilter: 'blur(10px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <GenIconBack c="#fff" s={20}/>
          </div>
        </div>
        {/* photo count pill */}
        {data.photoCount > 1 && (
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
            1 / {data.photoCount}
          </div>
        )}
      </div>

      {/* skeleton content area — mirrors detail screen */}
      <div style={{ flex: 1, padding: '20px 20px 0', overflow: 'hidden' }}>
        {/* date label (real, not skeleton — it's known) */}
        <GenDateLine tokens={tokens} date={data.date} dayOfWeek={data.dayOfWeek}/>

        {/* title shimmer */}
        <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <GenSkel tokens={tokens} w="85%" h={22} r={6}/>
          <GenSkel tokens={tokens} w="55%" h={22} r={6}/>
        </div>

        {/* tag chip shimmer (3-tone heights of real chips) */}
        <div style={{ display: 'flex', gap: 6, marginTop: 16 }}>
          <GenSkel tokens={tokens} w={70} h={22} r={6}/>
          <GenSkel tokens={tokens} w={86} h={22} r={6}/>
          <GenSkel tokens={tokens} w={58} h={22} r={6}/>
        </div>

        {/* hairline */}
        <div style={{ height: 1, background: tokens.divider, margin: '20px 0' }}/>

        {/* body shimmer lines */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <GenSkel tokens={tokens} w="100%" h={12} r={4}/>
          <GenSkel tokens={tokens} w="96%"  h={12} r={4}/>
          <GenSkel tokens={tokens} w="100%" h={12} r={4}/>
          <GenSkel tokens={tokens} w="78%"  h={12} r={4}/>
        </div>
      </div>

      {/* generating banner pinned above the home indicator */}
      <div style={{ padding: '0 16px 16px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '12px 14px',
          background: isDark ? 'rgba(212,166,142,0.14)' : 'rgba(184,133,108,0.10)',
          borderRadius: 14,
          border: `0.5px solid ${isDark ? 'rgba(212,166,142,0.22)' : 'rgba(184,133,108,0.20)'}`,
        }}>
          <div className="gen-pulse" style={{
            width: 28, height: 28, borderRadius: 999, background: tokens.accentMuted,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <GenIconSparkle c="#fff" s={14}/>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontSize: 13.5, fontWeight: 700, color: tokens.title,
              letterSpacing: -0.1, lineHeight: 1.25,
            }}>Writing your diary<GenDots tokens={tokens}/></div>
            <div style={{
              fontSize: 11.5, color: tokens.muted, marginTop: 2,
              letterSpacing: 0.2,
            }}>Reading 3 photos · {data.promptCategory.toLowerCase()} prompt</div>
          </div>
        </div>
        <div style={{ height: 10 }}/>
        <GenProgressTrack tokens={tokens} thick={true}/>
      </div>
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

// ─── variant catalogue ─────────────────────────────────────────
const GEN_VARIANTS = [
  { id: 'editorial', label: 'A · Calm editorial', Screen: GeneratingScreenEditorial,
    blurb: 'Quietest. Hero language, prompt as a quiet quote, slim progress bar at the bottom.' },
  { id: 'staged',    label: 'B · Staged',          Screen: GeneratingScreenStaged,
    blurb: 'Vertical stage list. The user sees what the AI is doing for the 1–3 seconds it runs.' },
  { id: 'skeleton',  label: 'C · Skeleton preview', Screen: GeneratingScreenSkeleton,
    blurb: 'Shows the detail-screen layout the entry will land in, with shimmering placeholders.' },
];

Object.assign(window, {
  GeneratingScreenEditorial, GeneratingScreenStaged, GeneratingScreenSkeleton,
  GEN_VARIANTS, GEN_DEFAULT,
});
