// Statistics Screen — Hero variant.
// Inherits from the list / detail Hero language:
//   · big display numerals (the number IS the data, give it scale)
//   · uppercase accent date/label tier instead of icon+label rows
//   · warm filled treatments on calendar entry days, no marker overlap
//   · hairline rhythm, no nested CustomCard chrome

// ─── small bits ────────────────────────────────────────────────
function StatsAppBar({ tokens }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', padding: '8px 8px 8px 20px',
      height: 56, background: tokens.surface,
    }}>
      <div style={{
        fontSize: 22, fontWeight: 600, color: tokens.title, letterSpacing: 0.1,
      }}>Statistics</div>
    </div>
  );
}

// ─── stat card ─────────────────────────────────────────────────
// `tone` controls a faint background tint that ties into the 3-tone
// chip palette from the list cards. Pass `tone="neutral"` for the
// flat-white treatment.
function StatCard({ label, value, unit, delta, tone = 'neutral', tokens }) {
  const tones = {
    neutral:   { bg: tokens.cardBg,         labelColor: tokens.accentMuted },
    primary:   { bg: tokens.statCardPrimary,   labelColor: tokens.tagPrimaryFg },
    secondary: { bg: tokens.statCardSecondary, labelColor: tokens.tagSecondaryFg },
    accent:    { bg: tokens.statCardAccent,    labelColor: tokens.tagAccentFg },
  }[tone];
  return (
    <div style={{
      background: tones.bg, borderRadius: 18,
      padding: '18px 18px 16px',
      boxShadow: tone === 'neutral' ? tokens.cardShadow : 'none',
      border: tone === 'neutral' ? tokens.cardBorder : `0.5px solid ${tokens.cardSoftBorder}`,
      display: 'flex', flexDirection: 'column', gap: 10,
      minHeight: 110,
    }}>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 0.9,
        textTransform: 'uppercase', color: tones.labelColor,
      }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 'auto' }}>
        <span style={{
          fontSize: 40, fontWeight: 700, lineHeight: 1, letterSpacing: -1.2,
          color: tokens.title, fontVariantNumeric: 'tabular-nums',
        }}>{value}</span>
        <span style={{
          fontSize: 13, fontWeight: 500, color: tokens.muted, letterSpacing: 0.1,
        }}>{unit}</span>
        {delta && (
          <span style={{
            marginLeft: 'auto', display: 'inline-flex', alignItems: 'center', gap: 3,
            fontSize: 11, fontWeight: 700, color: tokens.success,
            background: tokens.successBg, padding: '3px 7px', borderRadius: 999,
          }}>
            <svg width="9" height="9" viewBox="0 0 12 12" fill="none">
              <path d="M6 2v8M3 5l3-3 3 3" stroke={tokens.success} strokeWidth="1.8"
                strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            {delta}
          </span>
        )}
      </div>
    </div>
  );
}

// ─── calendar ──────────────────────────────────────────────────
// Refined month grid. Entry days get a warm tint; multi-entry days get
// a tiny filled count pill in the lower-right. Today is a ring; selected
// is the solid accent fill. No icon clutter in the header.
function StatsCalendar({ tokens, month, year, today, selected, entries, dark }) {
  // entries: { [day]: count }
  // Build grid: month starts on weekday X, has N days
  const monthIndex = ['January','February','March','April','May','June','July',
    'August','September','October','November','December'].indexOf(month);
  const first = new Date(year, monthIndex, 1);
  const startDow = first.getDay(); // 0 = Sun
  const daysInMonth = new Date(year, monthIndex + 1, 0).getDate();
  const prevMonthDays = new Date(year, monthIndex, 0).getDate();

  // cells: 6 weeks × 7 cols
  const cells = [];
  // leading other-month days
  for (let i = startDow - 1; i >= 0; i--) {
    cells.push({ day: prevMonthDays - i, other: true });
  }
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push({ day: d, other: false });
  }
  while (cells.length < 42) {
    const last = cells[cells.length - 1];
    cells.push({ day: (last.other && last.day < 15 ? last.day + 1 : 1), other: true });
  }
  // fix trailing other-month numbering
  let trailDay = 1;
  for (let i = 0; i < cells.length; i++) {
    if (i > daysInMonth + startDow - 1) {
      cells[i] = { day: trailDay++, other: true };
    }
  }

  const dows = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  return (
    <div style={{
      background: tokens.cardBg, borderRadius: 20,
      boxShadow: tokens.cardShadow, border: tokens.cardBorder,
      padding: '16px 14px 14px',
    }}>
      {/* month header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '4px 6px 14px',
      }}>
        <button style={{
          width: 34, height: 34, borderRadius: 999, border: 'none',
          background: 'transparent', color: tokens.muted,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M15 6l-6 6 6 6" stroke="currentColor" strokeWidth="2"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
        <div style={{ textAlign: 'center' }}>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
            color: tokens.accentMuted, marginBottom: 1,
          }}>{year}</div>
          <div style={{
            fontSize: 18, fontWeight: 700, color: tokens.title, letterSpacing: -0.2,
          }}>{month}</div>
        </div>
        <button style={{
          width: 34, height: 34, borderRadius: 999, border: 'none',
          background: 'transparent', color: tokens.title,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M9 6l6 6-6 6" stroke="currentColor" strokeWidth="2"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
      </div>

      {/* day-of-week row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 0, marginBottom: 6 }}>
        {dows.map((d, i) => (
          <div key={d} style={{
            textAlign: 'center', fontSize: 11, fontWeight: 700, letterSpacing: 0.5,
            color: (i === 0 || i === 6) ? tokens.accentMuted : tokens.muted,
            textTransform: 'uppercase', padding: '2px 0 8px',
          }}>{d}</div>
        ))}
      </div>

      {/* day grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2 }}>
        {cells.map((c, i) => {
          if (c.other) {
            return (
              <div key={i} style={{
                aspectRatio: '1 / 1', display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 14, color: tokens.muted, opacity: 0.35,
              }}>{c.day}</div>
            );
          }
          const count = entries[c.day] || 0;
          const isToday = c.day === today;
          const isSelected = c.day === selected;
          // visual rules
          const hasEntry = count > 0;
          const dow = (startDow + c.day - 1) % 7;
          const isWeekend = dow === 0 || dow === 6;

          let cellBg = 'transparent';
          let textColor = isWeekend ? tokens.accentMuted : tokens.title;
          let ringStyle = {};

          if (isSelected) {
            cellBg = tokens.calSelected;
            textColor = tokens.calSelectedFg;
          } else if (hasEntry) {
            cellBg = tokens.calEntryBg;
          }
          if (isToday && !isSelected) {
            ringStyle = { boxShadow: `inset 0 0 0 1.5px ${tokens.calToday}` };
          }
          return (
            <div key={i} style={{
              aspectRatio: '1 / 1', position: 'relative',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <div style={{
                width: '78%', height: '78%', borderRadius: '50%',
                background: cellBg, ...ringStyle,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                position: 'relative',
              }}>
                <span style={{
                  fontSize: 14, fontWeight: isSelected || isToday ? 700 : 500,
                  color: textColor, fontVariantNumeric: 'tabular-nums',
                }}>{c.day}</span>
                {/* count badge for multi-entry day */}
                {count > 1 && !isSelected && (
                  <div style={{
                    position: 'absolute', right: -2, bottom: -2,
                    minWidth: 14, height: 14, borderRadius: 999,
                    background: tokens.calCountBg, color: tokens.calCountFg,
                    fontSize: 9, fontWeight: 700, letterSpacing: 0,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    padding: '0 3px',
                  }}>{count}</div>
                )}
                {/* single-entry small dot */}
                {count === 1 && !isSelected && (
                  <div style={{
                    position: 'absolute', right: 4, bottom: 4,
                    width: 4, height: 4, borderRadius: 999,
                    background: tokens.calDot,
                  }}/>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* legend */}
      <div style={{
        display: 'flex', gap: 14, padding: '14px 6px 4px',
        fontSize: 11, color: tokens.muted, fontWeight: 500, letterSpacing: 0.2,
        alignItems: 'center', flexWrap: 'wrap',
      }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 10, height: 10, borderRadius: 999, background: tokens.calEntryBg, display: 'inline-block' }}/>
          <span>Entry</span>
        </div>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 10, height: 10, borderRadius: 999,
            background: tokens.calCountBg, display: 'inline-block' }}/>
          <span>Multiple</span>
        </div>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 10, height: 10, borderRadius: 999, background: 'transparent',
            boxShadow: `inset 0 0 0 1.5px ${tokens.calToday}`, display: 'inline-block' }}/>
          <span>Today</span>
        </div>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 10, height: 10, borderRadius: 999, background: tokens.calSelected, display: 'inline-block' }}/>
          <span>Selected</span>
        </div>
      </div>
    </div>
  );
}

// ─── full StatsScreen ──────────────────────────────────────────
// variant: 'neutral' (recommended) | 'tinted' (3-tone palette cards)
function StatsScreen({ tokens, variant = 'neutral' }) {
  const tones = variant === 'tinted'
    ? ['primary', 'accent', 'secondary', 'primary']
    : ['neutral', 'neutral', 'neutral', 'neutral'];

  const cards = [
    { label: 'Total entries',   value: '24', unit: 'diaries', delta: null,    tone: tones[0] },
    { label: 'Current streak',  value: '7',  unit: 'days',    delta: '+2',    tone: tones[1] },
    { label: 'Longest streak',  value: '21', unit: 'days',    delta: null,    tone: tones[2] },
    { label: 'This month',      value: '12', unit: 'diaries', delta: '+4',    tone: tones[3] },
  ];

  // Feb 2026: starts Sunday Feb 1, 28 days
  const entries = {
    2: 1, 3: 1, 5: 1, 7: 1, 9: 1, 10: 1, 12: 1, 14: 2, 16: 1, 17: 1,
    18: 1, 19: 1, 21: 3, 23: 1,
  };

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
      color: tokens.title,
    }}>
      <div style={{ height: 54, flexShrink: 0 }}/>
      <StatsAppBar tokens={tokens}/>

      <div style={{ flex: 1, overflow: 'hidden', padding: '4px 16px 16px' }}>
        {/* section label */}
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
          color: tokens.accentMuted, padding: '4px 4px 12px',
        }}>February 2026 · at a glance</div>

        {/* stat cards 2x2 */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 18,
        }}>
          {cards.map((c) => (
            <StatCard key={c.label} {...c} tokens={tokens}/>
          ))}
        </div>

        {/* calendar */}
        <StatsCalendar
          tokens={tokens} month="February" year={2026}
          today={15} selected={18} entries={entries}
          dark={tokens === window.darkTokens}
        />
      </div>

      {/* bottom tab nav */}
      <BottomNav tokens={tokens} active="stats"/>
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

Object.assign(window, { StatsScreen, StatCard, StatsCalendar });
