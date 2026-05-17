// Card variants for the Diaries list redesign.
// All components consume `entry` shaped like:
//   { date, title, body, tags, photos: [url], photoCount, mood? }
// and a `tokens` object holding the resolved color palette for the current mode.

// ─── shared bits ────────────────────────────────────────────────
function Chevron({ color, size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M9 6l6 6-6 6" stroke={color} strokeWidth="2"
        strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function DateLabel({ children, color }) {
  return (
    <span style={{
      fontSize: 12, fontWeight: 600, letterSpacing: 0.6,
      textTransform: 'uppercase', color,
      fontFeatureSettings: '"tnum"',
    }}>{children}</span>
  );
}

// Filled, contrast-bearing tag chip. Three tones cycle so a row reads
// as a curated set rather than a uniform stripe.
function TagChip({ label, tone = 'primary', tokens }) {
  const palette = {
    primary:   { bg: tokens.tagPrimaryBg,   fg: tokens.tagPrimaryFg },
    secondary: { bg: tokens.tagSecondaryBg, fg: tokens.tagSecondaryFg },
    accent:    { bg: tokens.tagAccentBg,    fg: tokens.tagAccentFg },
  }[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center',
      padding: '5px 10px', borderRadius: 8,
      background: palette.bg, color: palette.fg,
      fontSize: 11.5, fontWeight: 600, letterSpacing: 0.15,
      lineHeight: 1, whiteSpace: 'nowrap',
    }}>{label}</span>
  );
}

function TagRow({ tags, tokens, tones }) {
  const cycle = tones || ['accent', 'secondary', 'primary', 'secondary'];
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
      {tags.map((t, i) => (
        <TagChip key={t} label={t} tone={cycle[i % cycle.length]} tokens={tokens} />
      ))}
    </div>
  );
}

// Photo with a soft inner highlight so it sits as a real object, not a flat fill.
function Photo({ src, w, h, radius = 14, badge, tokens }) {
  return (
    <div style={{
      position: 'relative', width: w, height: h, borderRadius: radius,
      overflow: 'hidden', flexShrink: 0,
      background: tokens.photoFallback,
      boxShadow: tokens.photoInner,
    }}>
      <img src={src} alt="" loading="lazy"
        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
      {/* subtle vignette so light photos still read against light surface */}
      <div style={{
        position: 'absolute', inset: 0, borderRadius: radius, pointerEvents: 'none',
        boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.06)',
      }} />
      {badge && (
        <div style={{
          position: 'absolute', right: 8, bottom: 8,
          padding: '4px 8px', borderRadius: 999,
          background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(8px)',
          color: '#fff', fontSize: 11, fontWeight: 700, letterSpacing: 0.2,
        }}>{badge}</div>
      )}
    </div>
  );
}

// ─── A · Baseline (current, for reference) ──────────────────────
function CardBaseline({ entry, tokens }) {
  return (
    <div style={{
      background: tokens.cardBg, borderRadius: 16,
      padding: 16, boxShadow: tokens.cardShadow,
      border: tokens.cardBorder,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <DateLabel color={tokens.muted}>{entry.date}</DateLabel>
        <Chevron color={tokens.muted} />
      </div>
      <div style={{
        fontSize: 20, fontWeight: 500, lineHeight: 1.35,
        color: tokens.title, letterSpacing: 0.1, marginBottom: 6,
      }}>{entry.title}</div>
      <div style={{
        fontSize: 13.5, lineHeight: 1.55, color: tokens.muted,
        marginBottom: 12,
        display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden',
      }}>{entry.body}</div>
      {entry.photos[0] && (
        <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
          {entry.photos.slice(0, 3).map((p, i) => (
            <Photo key={i} src={p} w={84} h={84} radius={10} tokens={tokens}/>
          ))}
        </div>
      )}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {entry.tags.map((t) => (
          <span key={t} style={{
            padding: '4px 10px', borderRadius: 999,
            border: `1px solid ${tokens.chipOutline}`,
            color: tokens.muted, fontSize: 11.5, fontWeight: 500,
          }}>{t}</span>
        ))}
      </div>
    </div>
  );
}

// ─── B · Hero photo ─────────────────────────────────────────────
// Full-width 3:2 photo crowns the card. Title gets weight 700 and a
// real type ramp drop to the body. Tags become filled chips below.
function CardHero({ entry, tokens }) {
  return (
    <div style={{
      background: tokens.cardBg, borderRadius: 20,
      overflow: 'hidden', boxShadow: tokens.cardShadow,
      border: tokens.cardBorder,
    }}>
      <div style={{ position: 'relative', width: '100%', aspectRatio: '3 / 2' }}>
        <img src={entry.photos[0]} alt="" loading="lazy"
          style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
        {entry.photoCount > 1 && (
          <div style={{
            position: 'absolute', right: 12, bottom: 12,
            padding: '5px 10px', borderRadius: 999,
            background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(8px)',
            color: '#fff', fontSize: 11, fontWeight: 700, letterSpacing: 0.2,
            display: 'inline-flex', alignItems: 'center', gap: 4,
          }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
              <rect x="3" y="3" width="13" height="13" rx="2" stroke="#fff" strokeWidth="2"/>
              <rect x="8" y="8" width="13" height="13" rx="2" stroke="#fff" strokeWidth="2"/>
            </svg>
            {entry.photoCount}
          </div>
        )}
      </div>
      <div style={{ padding: '16px 18px 18px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <DateLabel color={tokens.accentMuted}>{entry.date}</DateLabel>
          <Chevron color={tokens.muted} />
        </div>
        <div style={{
          fontSize: 22, fontWeight: 700, lineHeight: 1.25,
          color: tokens.title, letterSpacing: -0.2, marginBottom: 8,
        }}>{entry.title}</div>
        <div style={{
          fontSize: 13.5, lineHeight: 1.6, color: tokens.muted,
          marginBottom: 14,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{entry.body}</div>
        <TagRow tags={entry.tags} tokens={tokens} />
      </div>
    </div>
  );
}

// ─── C · Magazine (asymmetric) ──────────────────────────────────
// Tall photo locked to the left edge; the right column carries the
// type ramp + tags. Trades photo scale for a more compact card height.
function CardMagazine({ entry, tokens }) {
  return (
    <div style={{
      background: tokens.cardBg, borderRadius: 18,
      overflow: 'hidden', boxShadow: tokens.cardShadow,
      border: tokens.cardBorder,
      display: 'grid', gridTemplateColumns: '124px 1fr', gap: 14,
      padding: 14,
    }}>
      <div style={{ position: 'relative' }}>
        <Photo src={entry.photos[0]} w={124} h={156} radius={14}
          badge={entry.photoCount > 1 ? `+${entry.photoCount - 1}` : null}
          tokens={tokens}/>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0, paddingRight: 4 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
          <DateLabel color={tokens.accentMuted}>{entry.date}</DateLabel>
          <Chevron color={tokens.muted} />
        </div>
        <div style={{
          fontSize: 19, fontWeight: 700, lineHeight: 1.22,
          color: tokens.title, letterSpacing: -0.1, marginBottom: 6,
          textWrap: 'pretty',
        }}>{entry.title}</div>
        <div style={{
          fontSize: 13, lineHeight: 1.55, color: tokens.muted,
          marginBottom: 10, flex: 1,
          display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{entry.body}</div>
        <TagRow tags={entry.tags.slice(0, 3)} tokens={tokens} />
      </div>
    </div>
  );
}

// ─── D · Editorial (photo-led, overlay) ─────────────────────────
// Full-bleed photo carries title in white, scrim baked in. The card
// body underneath is reserved for body + tags so the photo stays
// uncluttered.
function CardEditorial({ entry, tokens }) {
  return (
    <div style={{
      background: tokens.cardBg, borderRadius: 22,
      overflow: 'hidden', boxShadow: tokens.cardShadow,
      border: tokens.cardBorder,
    }}>
      <div style={{ position: 'relative', width: '100%', aspectRatio: '5 / 4' }}>
        <img src={entry.photos[0]} alt="" loading="lazy"
          style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
        {/* bottom scrim */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, height: '70%',
          background: 'linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(0,0,0,0.15) 35%, rgba(0,0,0,0.7) 100%)',
          pointerEvents: 'none',
        }}/>
        {/* date pill top-left */}
        <div style={{
          position: 'absolute', top: 14, left: 14,
          padding: '6px 11px', borderRadius: 999,
          background: 'rgba(255,255,255,0.85)', backdropFilter: 'blur(10px)',
          color: tokens.editorialDatePill, fontSize: 11, fontWeight: 700,
          letterSpacing: 0.6, textTransform: 'uppercase',
        }}>{entry.date}</div>
        {/* photo count top-right */}
        {entry.photoCount > 1 && (
          <div style={{
            position: 'absolute', top: 14, right: 14,
            padding: '5px 10px', borderRadius: 999,
            background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(8px)',
            color: '#fff', fontSize: 11, fontWeight: 700,
            display: 'inline-flex', alignItems: 'center', gap: 5,
          }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
              <rect x="3" y="3" width="13" height="13" rx="2" stroke="#fff" strokeWidth="2"/>
              <rect x="8" y="8" width="13" height="13" rx="2" stroke="#fff" strokeWidth="2"/>
            </svg>
            {entry.photoCount}
          </div>
        )}
        {/* title overlay */}
        <div style={{
          position: 'absolute', left: 16, right: 16, bottom: 14,
          color: '#fff',
        }}>
          <div style={{
            fontSize: 22, fontWeight: 700, lineHeight: 1.2,
            letterSpacing: -0.2, textShadow: '0 1px 12px rgba(0,0,0,0.3)',
          }}>{entry.title}</div>
        </div>
      </div>
      <div style={{ padding: '14px 18px 18px' }}>
        <div style={{
          fontSize: 13.5, lineHeight: 1.6, color: tokens.muted,
          marginBottom: 12,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{entry.body}</div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
          <TagRow tags={entry.tags.slice(0, 3)} tokens={tokens} />
          <Chevron color={tokens.muted} />
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  CardBaseline, CardHero, CardMagazine, CardEditorial,
  TagChip, TagRow, Photo, DateLabel, Chevron,
});
