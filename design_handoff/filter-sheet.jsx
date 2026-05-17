// Diary Filter — Hero variant.
// Applies the Hero vocabulary to the FilterBottomSheet + the
// ActiveFiltersDisplay strip on the diaries list.
//
// Key moves:
//   · Section titles ("Date Range", "Tags", "Time of day") become the
//     same uppercase accent labels used everywhere
//   · Tags: stock Material FilterChip → 3-tone filled chips with
//     a clear selected state (filled accent terracotta + white text)
//   · Date range: a Card+ListTile becomes two compact pill buttons
//     (Start / End) with a visible date string when set
//   · Time of day: small icon + label chip set
//   · Apply button: filled accent pill matching the prompt modal's
//     primary CTA; includes the live active-filter count
//   · Active filters strip on the list: replaces the small avatar-chip
//     Wrap with the same 3-tone removable chip vocabulary

// ─── reusable bits ────────────────────────────────────────────
function FilterClose({ color }) {
  return (
    <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
      <path d="M6 6l12 12M18 6L6 18" stroke={color} strokeWidth="2.6"
        strokeLinecap="round"/>
    </svg>
  );
}

// ─── filter tag chip (selected/unselected) ────────────────────
// Behaves like a FilterChip but in the Hero palette.
function FilterTagChip({ label, selected, tokens, accent }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '7px 12px', borderRadius: 999,
      background: selected ? accent : tokens.glyphBg,
      color: selected ? '#fff' : tokens.title,
      border: selected ? 'none' : `1px solid ${tokens.divider}`,
      fontSize: 13, fontWeight: selected ? 700 : 500,
      letterSpacing: 0.1, lineHeight: 1, whiteSpace: 'nowrap',
      cursor: 'pointer',
    }}>
      {selected && (
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
          <path d="M5 12l4 4 10-10" stroke="#fff" strokeWidth="2.6"
            strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      )}
      {label}
    </span>
  );
}

// ─── time-of-day chip ─────────────────────────────────────────
function TimeChip({ label, icon, selected, tokens, accent }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '8px 14px', borderRadius: 999,
      background: selected ? accent : tokens.glyphBg,
      color: selected ? '#fff' : tokens.title,
      border: selected ? 'none' : `1px solid ${tokens.divider}`,
      fontSize: 13, fontWeight: selected ? 700 : 600,
      letterSpacing: 0.1, lineHeight: 1, cursor: 'pointer',
    }}>
      {icon(selected ? '#fff' : tokens.accentMuted)}
      {label}
    </span>
  );
}

const TimeIcons = {
  morning: (c) => <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="4.5" stroke={c} strokeWidth="1.8"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
  noon: (c) => <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="5" fill={c}/></svg>,
  evening: (c) => <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><path d="M3 18h18M6 15a6 6 0 0112 0" stroke={c} strokeWidth="1.8" strokeLinecap="round"/><path d="M12 7V3M5 9l-2-1M19 9l2-1" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
  night: (c) => <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><path d="M20 14a8 8 0 11-10-10 6 6 0 0010 10z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/></svg>,
};

// ─── date pill (Start / End) ──────────────────────────────────
function DatePill({ label, value, tokens, accent, filled = false, onClear }) {
  return (
    <div style={{
      flex: 1, height: 56, borderRadius: 14,
      background: filled ? tokens.selectedBg : tokens.glyphBg,
      border: filled ? `1px solid ${accent}` : `1px solid ${tokens.divider}`,
      padding: '8px 14px',
      display: 'flex', flexDirection: 'column', justifyContent: 'center',
      cursor: 'pointer', position: 'relative',
    }}>
      <div style={{
        fontSize: 10, fontWeight: 700, letterSpacing: 0.8, textTransform: 'uppercase',
        color: tokens.accentMuted,
      }}>{label}</div>
      <div style={{
        fontSize: filled ? 15 : 14, fontWeight: filled ? 600 : 500,
        color: filled ? tokens.title : tokens.muted, letterSpacing: -0.1,
        marginTop: 2,
        fontVariantNumeric: 'tabular-nums',
      }}>{value || 'Select date'}</div>
      {filled && onClear && (
        <div style={{
          position: 'absolute', top: 8, right: 8,
          width: 20, height: 20, borderRadius: 999,
          background: 'rgba(20,18,16,0.12)',
          color: tokens.title,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <FilterClose color={tokens.title}/>
        </div>
      )}
    </div>
  );
}

// ─── section header ───────────────────────────────────────────
function FilterSectionLabel({ label, hint, tokens }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      padding: '0 4px 12px',
    }}>
      <span style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
        color: tokens.accentMuted,
      }}>{label}</span>
      {hint && (
        <span style={{ fontSize: 11, color: tokens.muted, fontWeight: 500 }}>
          {hint}
        </span>
      )}
    </div>
  );
}

// ─── filter sheet content (shared) ────────────────────────────
function FilterSheetContent({ tokens, accent, state = 'default' }) {
  const isApplied = state === 'applied';
  const isDateOnly = state === 'date-range';

  const tags = ['Noon', 'Relax', 'Peace', 'Reflection', 'Evening', 'Meal',
    'Night', 'Happy', 'Cat', 'Comfort', 'Nature', 'Morning',
    '昼', 'リラックス', 'Gratitude', 'Happiness'];
  const selectedTags = isApplied ? new Set(['Night', 'Reflection', 'Peace']) : new Set();
  const selectedTimes = isApplied
    ? new Set(['evening'])
    : new Set();
  const hasDateRange = isApplied || isDateOnly;

  const activeCount = (hasDateRange ? 1 : 0) + selectedTags.size + selectedTimes.size;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* ───── header ───────────────────────────────────────── */}
      <div style={{
        padding: '12px 20px 14px',
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12,
      }}>
        <div>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
            color: tokens.accentMuted, marginBottom: 2,
          }}>Diaries</div>
          <div style={{
            fontSize: 24, fontWeight: 700, color: tokens.title,
            letterSpacing: -0.3, lineHeight: 1.2,
          }}>Filter</div>
        </div>
        {activeCount > 0 ? (
          <button style={{
            height: 32, padding: '0 12px', borderRadius: 999,
            background: 'transparent', border: `1px solid ${tokens.divider}`,
            color: tokens.title, fontSize: 12, fontWeight: 600,
            fontFamily: 'inherit', cursor: 'pointer', letterSpacing: 0.1,
          }}>Clear all</button>
        ) : (
          <div style={{ width: 32, height: 32 }}/>
        )}
      </div>

      <div style={{ height: 0.5, background: tokens.divider, margin: '0 20px' }}/>

      {/* ───── sections (scrolling) ─────────────────────────── */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '20px 20px 12px' }}>
        {/* DATE RANGE */}
        <FilterSectionLabel label="Date range"
          hint={hasDateRange ? 'Feb 11 – Feb 18' : null} tokens={tokens}/>
        <div style={{ display: 'flex', gap: 10, marginBottom: 22 }}>
          <DatePill label="Start" value={hasDateRange ? 'Feb 11, 2026' : null}
            filled={hasDateRange} tokens={tokens} accent={accent}/>
          <DatePill label="End" value={hasDateRange ? 'Feb 18, 2026' : null}
            filled={hasDateRange} tokens={tokens} accent={accent}
            onClear={hasDateRange ? () => {} : null}/>
        </div>

        {/* TAGS */}
        <FilterSectionLabel label="Tags"
          hint={selectedTags.size > 0 ? `${selectedTags.size} selected` : '20 popular'}
          tokens={tokens}/>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 22 }}>
          {tags.map((t) => (
            <FilterTagChip key={t} label={`#${t}`}
              selected={selectedTags.has(t)} tokens={tokens} accent={accent}/>
          ))}
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4,
            padding: '7px 12px', borderRadius: 999,
            background: 'transparent', color: tokens.accentMuted,
            border: `1px solid ${tokens.divider}`,
            fontSize: 12.5, fontWeight: 600, cursor: 'pointer',
          }}>
            +4 more
          </span>
        </div>

        {/* TIME OF DAY */}
        <FilterSectionLabel label="Time of day"
          hint={selectedTimes.size > 0 ? `${selectedTimes.size} selected` : null}
          tokens={tokens}/>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 16 }}>
          <TimeChip label="Morning" icon={TimeIcons.morning}
            selected={selectedTimes.has('morning')} tokens={tokens} accent={accent}/>
          <TimeChip label="Noon" icon={TimeIcons.noon}
            selected={selectedTimes.has('noon')} tokens={tokens} accent={accent}/>
          <TimeChip label="Evening" icon={TimeIcons.evening}
            selected={selectedTimes.has('evening')} tokens={tokens} accent={accent}/>
          <TimeChip label="Night" icon={TimeIcons.night}
            selected={selectedTimes.has('night')} tokens={tokens} accent={accent}/>
        </div>
      </div>

      {/* ───── apply button ─────────────────────────────────── */}
      <div style={{
        padding: '12px 20px 16px',
        borderTop: `0.5px solid ${tokens.divider}`,
        background: tokens.modalBg,
      }}>
        <button style={{
          width: '100%', height: 50, borderRadius: 14,
          background: accent, border: 'none', color: '#fff',
          fontSize: 15, fontWeight: 700, letterSpacing: 0.2,
          fontFamily: 'inherit', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          {activeCount > 0 ? (
            <>
              Apply
              <span style={{
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                minWidth: 22, height: 22, padding: '0 6px', borderRadius: 999,
                background: 'rgba(255,255,255,0.22)',
                fontSize: 12, fontWeight: 700,
                fontVariantNumeric: 'tabular-nums',
              }}>{activeCount}</span>
              filter{activeCount === 1 ? '' : 's'}
            </>
          ) : 'Apply filter'}
        </button>
      </div>
    </div>
  );
}

// ─── filter bottom sheet (over the diaries list) ──────────────
function FilterSheetScreen({ tokens, state = 'default' }) {
  const accent = tokens.calSelected;
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
    }}>
      <div style={{ height: 54 }}/>
      {/* peek of the diaries list behind */}
      <div style={{
        padding: '12px 20px 16px',
        opacity: 0.5,
      }}>
        <div style={{
          fontSize: 22, fontWeight: 600, color: tokens.title, marginBottom: 8,
        }}>Diaries</div>
        <div style={{
          height: 160, borderRadius: 16, background: tokens.cardBg,
          border: tokens.cardBorder,
          padding: 16,
        }}>
          <div style={{ fontSize: 11, color: tokens.accentMuted,
            fontWeight: 700, letterSpacing: 0.6, marginBottom: 6 }}>2/18</div>
          <div style={{ fontSize: 18, fontWeight: 700,
            color: tokens.title, marginBottom: 6 }}>Peaceful awe</div>
          <div style={{ fontSize: 13, color: tokens.muted, lineHeight: 1.5 }}>
            The vibrant colors instantly brought a profound…
          </div>
        </div>
      </div>

      {/* scrim */}
      <div style={{
        position: 'absolute', inset: 0, background: tokens.modalScrim,
        backdropFilter: 'blur(2px)',
      }}/>

      {/* sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: tokens.modalBg,
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        boxShadow: tokens.modalShadow,
        overflow: 'hidden',
        maxHeight: '90%', display: 'flex', flexDirection: 'column',
        paddingBottom: 24,
      }}>
        <div style={{
          width: 36, height: 5, borderRadius: 999, background: tokens.handle,
          margin: '8px auto 0',
        }}/>
        <FilterSheetContent tokens={tokens} accent={accent} state={state}/>
      </div>
    </div>
  );
}

// ─── active filters strip (on the diaries list, when filtered) ──
function ActiveFiltersStrip({ tokens, accent }) {
  // Combined chip list: date range + 3 tags + evening time slot
  const chips = [
    { label: 'Feb 11 – Feb 18', tone: 'date' },
    { label: '#Night',          tone: 'tag' },
    { label: '#Reflection',     tone: 'tag' },
    { label: '#Peace',          tone: 'tag' },
    { label: 'Evening',         tone: 'time' },
  ];
  const toneFill = {
    date: { bg: tokens.tagPrimaryBg,   fg: tokens.tagPrimaryFg },
    tag:  { bg: tokens.tagAccentBg,    fg: tokens.tagAccentFg },
    time: { bg: tokens.tagSecondaryBg, fg: tokens.tagSecondaryFg },
  };
  return (
    <div style={{
      padding: '10px 16px 12px',
      borderBottom: `0.5px solid ${tokens.divider}`,
      background: tokens.surface,
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 8,
      }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
          color: tokens.accentMuted,
        }}>{chips.length} filters active</div>
        <button style={{
          padding: '4px 8px', borderRadius: 6, border: 'none',
          background: 'transparent', color: tokens.title,
          fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
        }}>Clear all</button>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {chips.map((c) => {
          const p = toneFill[c.tone];
          return (
            <span key={c.label} style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '5px 6px 5px 10px', borderRadius: 999,
              background: p.bg, color: p.fg,
              fontSize: 11.5, fontWeight: 600, letterSpacing: 0.1, lineHeight: 1,
            }}>
              {c.label}
              <span style={{
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                width: 16, height: 16, borderRadius: 999,
                background: 'rgba(20,18,16,0.10)',
              }}>
                <FilterClose color={p.fg}/>
              </span>
            </span>
          );
        })}
      </div>
    </div>
  );
}

// Mini diaries list view that shows the strip in context.
function DiariesWithFiltersScreen({ tokens }) {
  const accent = tokens.calSelected;
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
      color: tokens.title,
    }}>
      <div style={{ height: 54 }}/>
      {/* simple Diaries app bar */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '8px 8px 8px 20px', height: 56,
      }}>
        <div style={{ fontSize: 22, fontWeight: 600, color: tokens.title }}>Diaries</div>
        <div style={{ display: 'flex', gap: 4 }}>
          <button style={{ width: 44, height: 44, borderRadius: 12, border: 'none',
            background: 'transparent', color: tokens.title,
            display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <circle cx="11" cy="11" r="7" stroke={tokens.title} strokeWidth="2"/>
              <path d="M20 20l-3.5-3.5" stroke={tokens.title} strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </button>
          <button style={{ width: 44, height: 44, borderRadius: 12, border: 'none',
            background: 'transparent', color: accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            {/* filter icon — active state */}
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M4 6h16M7 12h10M10 18h4" stroke={accent} strokeWidth="2.4" strokeLinecap="round"/>
            </svg>
          </button>
        </div>
      </div>

      <ActiveFiltersStrip tokens={tokens} accent={accent}/>

      {/* result count + cards (compressed) */}
      <div style={{
        padding: '12px 20px 6px',
        fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
        color: tokens.accentMuted,
      }}>4 matching entries</div>

      <div style={{ flex: 1, overflow: 'hidden', padding: '4px 16px 16px',
        display: 'flex', flexDirection: 'column', gap: 12 }}>
        {[1, 2, 3].map((i) => (
          <div key={i} style={{
            background: tokens.cardBg, borderRadius: 16,
            border: tokens.cardBorder, boxShadow: tokens.cardShadow,
            padding: 14, display: 'flex', flexDirection: 'column', gap: 6,
          }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.6,
              color: tokens.accentMuted }}>2/1{i + 1}</div>
            <div style={{ fontSize: 17, fontWeight: 700,
              color: tokens.title, letterSpacing: -0.2 }}>
              {i === 1 ? 'Finding peace in grandeur' :
               i === 2 ? 'Stillness at dusk' :
               'A quiet kind of evening'}
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
              <span style={{ padding: '3px 8px', borderRadius: 6,
                background: tokens.tagAccentBg, color: tokens.tagAccentFg,
                fontSize: 10.5, fontWeight: 600 }}>Night</span>
              <span style={{ padding: '3px 8px', borderRadius: 6,
                background: tokens.tagPrimaryBg, color: tokens.tagPrimaryFg,
                fontSize: 10.5, fontWeight: 600 }}>Reflection</span>
              <span style={{ padding: '3px 8px', borderRadius: 6,
                background: tokens.tagSecondaryBg, color: tokens.tagSecondaryFg,
                fontSize: 10.5, fontWeight: 600 }}>Peace</span>
            </div>
          </div>
        ))}
      </div>

      <BottomNav tokens={tokens} active="diary"/>
      <div style={{ height: 24, flexShrink: 0 }}/>
    </div>
  );
}

Object.assign(window, {
  FilterSheetScreen, DiariesWithFiltersScreen, ActiveFiltersStrip,
});
