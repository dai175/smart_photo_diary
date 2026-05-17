// Prompt Selection Modal — Hero variant.
// Two presentations of the same content:
//   · centered dialog (matches current CustomDialog placement)
//   · bottom sheet (iOS-native; recommended on iPhone)
//
// Same Hero vocabulary as the rest of the app:
//   · uppercase accent labels as the third tier
//   · filled 3-tone chips replace the rainbow category palette
//   · selection state: warm accent tint + filled check disc, no 2-px borders
//   · one continuous sheet, no nested bordered cards

// ─── deterministic category → tone mapping ─────────────────────
// Categories cycle through primary / accent / secondary so a list of
// prompts reads as a curated set rather than a random palette grab.
const CATEGORY_TONE = {
  'Emotion':           'primary',
  'Deep Emotion':      'secondary',
  'Sensory Emotion':   'accent',
  'Growth':            'secondary',
  'Connection':        'primary',
  'Discovery':         'accent',
  'Imagination':       'secondary',
  'Healing':           'primary',
  'Energy':            'accent',
};

// ─── reusable bits ─────────────────────────────────────────────
function CheckDisc({ accent }) {
  return (
    <div style={{
      width: 22, height: 22, borderRadius: 999, background: accent,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0,
    }}>
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
        <path d="M5 12l4 4 10-10" stroke="#fff" strokeWidth="2.6"
          strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </div>
  );
}

function PremiumBadge({ tokens }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 7px', borderRadius: 999,
      background: tokens.premiumBg, color: tokens.premiumFg,
      fontSize: 10, fontWeight: 700, letterSpacing: 0.3,
      textTransform: 'uppercase',
    }}>
      <svg width="9" height="9" viewBox="0 0 24 24" fill="none">
        <path d="M12 2l3 6 6 1-4.5 4.5L18 20l-6-3-6 3 1.5-6.5L3 9l6-1z"
          fill={tokens.premiumFg}/>
      </svg>
      Premium
    </div>
  );
}

// ─── quick-option card (No prompt / Random) ────────────────────
// Compact 2-up card row that visually separates the "shortcut" options
// from the actual prompt list.
function QuickOptionCard({ title, desc, glyph, selected, tokens, accent }) {
  return (
    <div style={{
      flex: 1, padding: '14px 14px 14px',
      borderRadius: 16,
      background: selected ? tokens.selectedBg : tokens.cardBg,
      border: selected
        ? `1px solid ${accent}`
        : `1px solid ${tokens.divider}`,
      boxShadow: selected ? 'none' : tokens.cardShadowSoft,
      display: 'flex', flexDirection: 'column', gap: 6,
      cursor: 'pointer', position: 'relative',
      minHeight: 92,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{
          width: 28, height: 28, borderRadius: 8,
          background: selected ? accent : tokens.glyphBg,
          color: selected ? '#fff' : tokens.muted,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{glyph}</div>
        {selected && <CheckDisc accent={accent}/>}
      </div>
      <div style={{
        fontSize: 14, fontWeight: 700, color: tokens.title, letterSpacing: -0.1,
        marginTop: 4,
      }}>{title}</div>
      <div style={{
        fontSize: 11.5, lineHeight: 1.45, color: tokens.muted,
        display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
      }}>{desc}</div>
    </div>
  );
}

// ─── prompt row (single line item) ─────────────────────────────
function PromptRow({ prompt, selected, tokens, accent }) {
  const tone = CATEGORY_TONE[prompt.category] || 'primary';
  return (
    <div style={{
      padding: '14px 14px',
      borderRadius: 14,
      background: selected ? tokens.selectedBg : 'transparent',
      border: selected
        ? `1px solid ${accent}`
        : `1px solid transparent`,
      display: 'flex', flexDirection: 'column', gap: 8,
      cursor: 'pointer', position: 'relative',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
        <TagChip label={prompt.category} tone={tone} tokens={tokens}/>
        {prompt.premium && <PremiumBadge tokens={tokens}/>}
        <div style={{ flex: 1 }}/>
        {selected && <CheckDisc accent={accent}/>}
      </div>
      <div style={{
        fontSize: 15, fontWeight: selected ? 600 : 500,
        color: tokens.title, lineHeight: 1.4, letterSpacing: -0.1,
        textWrap: 'pretty',
      }}>{prompt.text}</div>
      {prompt.desc && (
        <div style={{
          fontSize: 12.5, lineHeight: 1.5, color: tokens.muted,
        }}>{prompt.desc}</div>
      )}
    </div>
  );
}

function RowDivider({ tokens }) {
  return <div style={{ height: 1, background: tokens.divider, margin: '0 14px' }}/>;
}

// ─── modal inner content (shared) ──────────────────────────────
function PromptModalContent({ tokens, selectedId = 'random', contextOpen = false, accent }) {
  const prompts = [
    { id: 'p1', category: 'Emotion',
      text: 'What was the very first feeling that surfaced in this moment?',
      desc: 'Capture the raw emotion you noticed the moment the experience began.' },
    { id: 'p2', category: 'Emotion',
      text: 'What stirred your heart in this scene?',
      desc: 'Explore why your heart reacted the way it did.' },
    { id: 'p3', category: 'Sensory Emotion', premium: true,
      text: 'Which sensory detail still echoes?',
      desc: 'Pick the one sound, smell, or feel that won’t leave your mind.' },
    { id: 'p4', category: 'Growth', premium: true,
      text: 'What did this moment quietly teach you?',
      desc: 'Find the lesson hiding in the day.' },
    { id: 'p5', category: 'Discovery', premium: true,
      text: 'If this becomes a memory in ten years, what stays?',
      desc: 'Imagine the version that future-you would keep.' },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* ───── header ───────────────────────────────────────── */}
      <div style={{ padding: '20px 20px 14px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase',
          color: tokens.accentMuted, marginBottom: 6,
        }}>February 18 · New entry</div>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
          <div>
            <div style={{
              fontSize: 22, fontWeight: 700, color: tokens.title, letterSpacing: -0.3, lineHeight: 1.2,
            }}>Choose a prompt</div>
            <div style={{
              fontSize: 13, color: tokens.muted, marginTop: 4,
            }}>Pick a question to anchor your writing, or skip.</div>
          </div>
          <button style={{
            width: 32, height: 32, borderRadius: 999, border: 'none', cursor: 'pointer',
            background: tokens.glyphBg, color: tokens.title,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path d="M6 6l12 12M18 6L6 18" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </button>
        </div>
      </div>

      {/* ───── context toggle / input ───────────────────────── */}
      <div style={{ padding: '0 20px 14px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          fontSize: 12.5, fontWeight: 600, color: tokens.accentMuted,
          cursor: 'pointer', padding: '6px 0',
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
            style={{ transform: contextOpen ? 'rotate(90deg)' : 'rotate(0deg)', transition: 'transform .15s' }}>
            <path d="M9 6l6 6-6 6" stroke="currentColor" strokeWidth="2"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <span style={{ letterSpacing: 0.2 }}>Add context</span>
          <span style={{ fontSize: 11, color: tokens.muted, fontWeight: 500, marginLeft: 4 }}>
            optional · helps the AI tailor the prompt
          </span>
        </div>
        {contextOpen && (
          <div style={{
            marginTop: 8,
            background: tokens.editFieldBg,
            border: `1px solid ${tokens.editFieldBorder}`,
            borderRadius: 12, padding: '10px 12px',
            fontSize: 13.5, color: tokens.title, minHeight: 56, lineHeight: 1.5,
          }}>Today felt heavier than usual—</div>
        )}
      </div>

      {/* ───── quick options ────────────────────────────────── */}
      <div style={{ padding: '0 20px 8px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.9, textTransform: 'uppercase',
          color: tokens.muted, marginBottom: 8,
        }}>Quick options</div>
        <div style={{ display: 'flex', gap: 10 }}>
          <QuickOptionCard
            title="No prompt"
            desc="Generate a diary using photos only."
            glyph={
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M4 20h4l10-10-4-4L4 16v4z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
                <path d="M4 4l16 16" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            }
            selected={selectedId === 'none'} tokens={tokens} accent={accent}/>
          <QuickOptionCard
            title="Random"
            desc="Pick a recommended prompt for me."
            glyph={
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M16 4h4v4M20 4l-7 7M8 20H4v-4M4 20l7-7M16 20h4v-4M20 20l-6-6"
                  stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            }
            selected={selectedId === 'random'} tokens={tokens} accent={accent}/>
        </div>
      </div>

      {/* ───── prompts section header ───────────────────────── */}
      <div style={{ padding: '14px 20px 4px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
        <span style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.9, textTransform: 'uppercase',
          color: tokens.muted,
        }}>Browse prompts</span>
        <span style={{ fontSize: 11.5, color: tokens.muted, fontWeight: 500 }}>
          {prompts.length} available
        </span>
      </div>

      {/* ───── prompt list (scrolling area) ─────────────────── */}
      <div style={{
        flex: 1, overflow: 'hidden',
        padding: '4px 6px 0',
      }}>
        {prompts.map((p, i) => (
          <React.Fragment key={p.id}>
            <PromptRow prompt={p} selected={selectedId === p.id} tokens={tokens} accent={accent}/>
            {i < prompts.length - 1 && <RowDivider tokens={tokens}/>}
          </React.Fragment>
        ))}
      </div>

      {/* ───── action bar ───────────────────────────────────── */}
      <div style={{
        padding: '14px 20px 16px',
        borderTop: `0.5px solid ${tokens.divider}`,
        background: tokens.modalBg,
        display: 'flex', gap: 10,
      }}>
        <button style={{
          flex: '0 0 auto', padding: '0 18px', height: 46, borderRadius: 14,
          background: 'transparent', border: `1px solid ${tokens.chipOutline}`,
          color: tokens.title, fontSize: 15, fontWeight: 600, cursor: 'pointer',
          fontFamily: 'inherit',
        }}>Cancel</button>
        <button style={{
          flex: 1, height: 46, borderRadius: 14,
          background: accent, border: 'none', color: '#fff',
          fontSize: 15, fontWeight: 700, letterSpacing: 0.2, cursor: 'pointer',
          fontFamily: 'inherit',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
            <path d="M5 12h14M13 5l7 7-7 7" stroke="#fff" strokeWidth="2"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          {selectedId === 'random' ? 'Create with random'
            : selectedId === 'none' ? 'Create without prompt'
            : 'Create with this prompt'}
        </button>
      </div>
    </div>
  );
}

// ─── centered modal presentation ───────────────────────────────
function CenteredModalScreen({ tokens, selectedId, contextOpen }) {
  const accent = tokens.calSelected; // accent terracotta used elsewhere
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
    }}>
      {/* status spacer */}
      <div style={{ height: 54 }}/>
      {/* background app peek (just a faded date strip) */}
      <div style={{
        padding: '16px 20px',
        fontSize: 12, fontWeight: 700, letterSpacing: 0.8, textTransform: 'uppercase',
        color: tokens.accentMuted,
        opacity: 0.4,
      }}>February 18, 2026 · Tuesday</div>

      {/* scrim */}
      <div style={{
        position: 'absolute', inset: 0, background: tokens.modalScrim,
        backdropFilter: 'blur(2px)',
      }}/>

      {/* modal card */}
      <div style={{
        position: 'absolute', left: 16, right: 16, top: '50%',
        transform: 'translateY(-50%)',
        background: tokens.modalBg, borderRadius: 24,
        boxShadow: tokens.modalShadow,
        overflow: 'hidden',
        maxHeight: 760,
        display: 'flex', flexDirection: 'column',
      }}>
        <PromptModalContent tokens={tokens} selectedId={selectedId}
          contextOpen={contextOpen} accent={accent}/>
      </div>
    </div>
  );
}

// ─── bottom-sheet presentation ─────────────────────────────────
function BottomSheetScreen({ tokens, selectedId, contextOpen }) {
  const accent = tokens.calSelected;
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: tokens.surface,
      fontFamily: '"Noto Sans JP", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
    }}>
      <div style={{ height: 54 }}/>
      <div style={{
        padding: '16px 20px',
        fontSize: 12, fontWeight: 700, letterSpacing: 0.8, textTransform: 'uppercase',
        color: tokens.accentMuted, opacity: 0.4,
      }}>February 18, 2026 · Tuesday</div>

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
        maxHeight: '88%', display: 'flex', flexDirection: 'column',
        paddingBottom: 24, // home indicator safe area
      }}>
        {/* drag handle */}
        <div style={{
          width: 36, height: 5, borderRadius: 999, background: tokens.handle,
          margin: '8px auto 0',
        }}/>
        <PromptModalContent tokens={tokens} selectedId={selectedId}
          contextOpen={contextOpen} accent={accent}/>
      </div>
    </div>
  );
}

Object.assign(window, {
  PromptModalContent, CenteredModalScreen, BottomSheetScreen,
});
