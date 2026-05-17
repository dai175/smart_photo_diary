// Onboarding redesign for Smart Photo Diary.
//
// Two directions, both built on the same vocabulary as the rest of
// the Hero redesign (accent eyebrow → bold headline → quiet body →
// filled accent CTA, 3-tone chips, soft-tinted accent icon tiles).
//
//   A · Editorial          (recommended)
//      4-screen paginated flow restyled with the shared ramp.
//      Decorative glyphs replaced by real product previews —
//      a stacked-photo motif, a real Hero diary card, a privacy
//      checklist styled like a Settings group, and a permission
//      preview that previews the iOS sheet the user will see.
//
//   B · Photo-led          (alternate)
//      Same content, but each screen is anchored by a full-bleed
//      photo carrying the headline in white, with the body & CTA
//      living on a tray below. Reads more like a print magazine
//      cover — more dramatic, more committed to imagery.
//
// Exported via `window.OnboardingScreen({ tokens, step, variant })`.

const ONB_PHOTO = {
  sunset:    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900&q=80&auto=format&fit=crop',
  cat:       'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=900&q=80&auto=format&fit=crop',
  cathedral: 'https://images.unsplash.com/photo-1548276145-69a9521f0499?w=900&q=80&auto=format&fit=crop',
  coffee:    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80&auto=format&fit=crop',
  beach:     'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
  forest:    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=600&q=80&auto=format&fit=crop',
  flowers:   'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=600&q=80&auto=format&fit=crop',
  city:      'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=600&q=80&auto=format&fit=crop',
  pasta:     'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=600&q=80&auto=format&fit=crop',
};

const STEPS = [
  { eyebrow: '01 · WELCOME',          cta: 'Begin'                 },
  { eyebrow: '02 · HOW IT WORKS',     cta: 'Next'                  },
  { eyebrow: '03 · PRIVATE BY DESIGN', cta: 'Continue'              },
  { eyebrow: '04 · READY',            cta: 'Create my first diary' },
];

// ─────────────────────────────────────────────────────────────────
// shared chrome
// ─────────────────────────────────────────────────────────────────

function OnbHeader({ tokens, step, total = 4, onDark = false }) {
  const fg = onDark ? 'rgba(255,255,255,0.92)' : tokens.muted;
  const trackEmpty = onDark ? 'rgba(255,255,255,0.22)' : tokens.chipOutline;
  const trackFill  = onDark ? '#FFFFFF' : tokens.accentMuted;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '4px 22px 0', height: 28,
    }}>
      <div style={{
        flex: 1, display: 'flex', gap: 5, alignItems: 'center',
      }}>
        {Array.from({ length: total }).map((_, i) => (
          <div key={i} style={{
            flex: 1, height: 3, borderRadius: 999,
            background: i < step ? trackFill : trackEmpty,
            transition: 'background 0.2s',
          }}/>
        ))}
      </div>
      <button style={{
        background: 'transparent', border: 'none', cursor: 'pointer',
        padding: '4px 2px',
        fontSize: 13, fontWeight: 600, letterSpacing: 0.1, color: fg,
        fontFamily: 'inherit',
      }}>Skip</button>
    </div>
  );
}

function OnbEyebrow({ children, color }) {
  return (
    <div style={{
      fontSize: 11, fontWeight: 700, letterSpacing: 1.4,
      textTransform: 'uppercase', color,
      fontFeatureSettings: '"tnum"',
    }}>{children}</div>
  );
}

function OnbHeadline({ children, color, size = 30 }) {
  return (
    <div style={{
      fontSize: size, fontWeight: 700, lineHeight: 1.12,
      letterSpacing: -0.5, color, textWrap: 'balance',
    }}>{children}</div>
  );
}

function OnbBody({ children, color, size = 15 }) {
  return (
    <div style={{
      fontSize: size, lineHeight: 1.55, color,
      textWrap: 'pretty', fontWeight: 400,
    }}>{children}</div>
  );
}

function PrimaryCTA({ tokens, label, icon }) {
  return (
    <button style={{
      width: '100%', height: 52, borderRadius: 14, border: 'none',
      background: '#8E6450',
      color: '#FFFFFF', fontSize: 15, fontWeight: 700,
      letterSpacing: 0.1, cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      fontFamily: 'inherit',
      boxShadow: '0 10px 28px rgba(142,100,80,0.35), 0 2px 6px rgba(142,100,80,0.18)',
    }}>
      {label}
      {icon && (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <path d="M5 12h14M13 6l6 6-6 6" stroke="#FFFFFF" strokeWidth="2.2"
            strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      )}
    </button>
  );
}

// ─────────────────────────────────────────────────────────────────
// shared content visuals (used by both directions)
// ─────────────────────────────────────────────────────────────────

// Photo-stack motif: 3 overlapping diary photos forming a soft fan.
// Hints "your photos / your stories" without leaning on the app icon.
function PhotoStack({ tokens }) {
  const Tile = ({ src, x, y, rot, w = 152, h = 196, z = 1 }) => (
    <div style={{
      position: 'absolute',
      left: '50%', top: '50%',
      transform: `translate(${x - w / 2}px, ${y - h / 2}px) rotate(${rot}deg)`,
      width: w, height: h, borderRadius: 18,
      overflow: 'hidden', zIndex: z,
      background: tokens.photoFallback,
      boxShadow: '0 12px 40px rgba(35,30,26,0.18), 0 2px 6px rgba(35,30,26,0.08)',
      border: '3px solid #FFFFFF',
    }}>
      <img src={src} alt="" loading="lazy"
        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
    </div>
  );
  return (
    <div style={{
      position: 'relative', width: '100%', height: 280,
    }}>
      <Tile src={ONB_PHOTO.sunset}    x={-86} y={6}   rot={-12} z={1}/>
      <Tile src={ONB_PHOTO.cat}       x={86}  y={6}   rot={10}  z={2}/>
      <Tile src={ONB_PHOTO.cathedral} x={0}   y={-10} rot={-2}  z={3}/>
    </div>
  );
}

// Mini-Hero diary card preview — same vocabulary as the redesigned
// list card but compressed to feel like a sample.
function MiniHeroCard({ tokens }) {
  return (
    <div style={{
      background: tokens.cardBg, borderRadius: 18,
      overflow: 'hidden', boxShadow: tokens.cardShadow,
      border: tokens.cardBorder,
      position: 'relative',
    }}>
      <div style={{ position: 'relative', width: '100%', aspectRatio: '3 / 2' }}>
        <img src={ONB_PHOTO.cat} alt="" loading="lazy"
          style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
        <div style={{
          position: 'absolute', top: 10, left: 10,
          padding: '4px 9px', borderRadius: 999,
          background: 'rgba(255,255,255,0.9)',
          backdropFilter: 'blur(10px)',
          color: '#8E6450', fontSize: 10, fontWeight: 700, letterSpacing: 0.9,
          textTransform: 'uppercase',
        }}>Example entry</div>
      </div>
      <div style={{ padding: '14px 16px 16px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.7,
          textTransform: 'uppercase', color: tokens.accentMuted, marginBottom: 6,
        }}>Feb 17</div>
        <div style={{
          fontSize: 18, fontWeight: 700, lineHeight: 1.22,
          color: tokens.title, letterSpacing: -0.2, marginBottom: 6,
        }}>Comfort in a feline gaze</div>
        <div style={{
          fontSize: 13, lineHeight: 1.55, color: tokens.muted, marginBottom: 12,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>Seeing her so peaceful, eyes barely open, brought an immediate wave of calm…</div>
        <div style={{ display: 'flex', gap: 6 }}>
          <span style={{
            padding: '4px 9px', borderRadius: 7,
            background: tokens.tagAccentBg, color: tokens.tagAccentFg,
            fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
          }}>Morning</span>
          <span style={{
            padding: '4px 9px', borderRadius: 7,
            background: tokens.tagSecondaryBg, color: tokens.tagSecondaryFg,
            fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
          }}>Cat</span>
          <span style={{
            padding: '4px 9px', borderRadius: 7,
            background: tokens.tagPrimaryBg, color: tokens.tagPrimaryFg,
            fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
          }}>Warmth</span>
        </div>
      </div>
    </div>
  );
}

// Privacy promises rendered as the same grouped card vocabulary
// used in the redesigned Settings screen.
function PrivacyGroup({ tokens }) {
  const Row = ({ icon, title, subtitle, last = false }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '14px 16px',
      borderBottom: last ? 'none' : `0.5px solid ${tokens.divider}`,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: tokens.glyphBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 14.5, fontWeight: 600, color: tokens.title,
          letterSpacing: -0.1, lineHeight: 1.3, marginBottom: 1,
        }}>{title}</div>
        <div style={{
          fontSize: 12.5, lineHeight: 1.4, color: tokens.muted,
        }}>{subtitle}</div>
      </div>
    </div>
  );
  const ico = (path) => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
      <path d={path} stroke={tokens.accentMuted} strokeWidth="1.8"
        strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
  return (
    <div style={{
      background: tokens.cardBg, borderRadius: 16,
      boxShadow: tokens.cardShadowSoft,
      border: `0.5px solid ${tokens.cardSoftBorder}`,
      overflow: 'hidden',
    }}>
      <Row
        icon={ico('M6 11V8a6 6 0 0112 0v3M5 11h14v9a1 1 0 01-1 1H6a1 1 0 01-1-1v-9z')}
        title="On device only"
        subtitle="Your diary never leaves this phone."/>
      <Row
        icon={ico('M12 3l8 3v5c0 5-3.5 9-8 10-4.5-1-8-5-8-10V6l8-3z')}
        title="No account required"
        subtitle="No email, password or sign-up."/>
      <Row
        icon={ico('M21 12a9 9 0 11-18 0 9 9 0 0118 0zM9 12l2 2 4-4')}
        title="You own everything"
        subtitle="Export, delete or back up anytime."
        last/>
    </div>
  );
}

// 3×3 photo grid teaser — previews "your photo library" without
// requiring permission first. The most recent photo (top-left) is
// highlighted as the suggested starting point.
function PhotoGridTeaser({ tokens, highlight = true }) {
  const photos = [
    ONB_PHOTO.coffee,    ONB_PHOTO.flowers,   ONB_PHOTO.sunset,
    ONB_PHOTO.cat,       ONB_PHOTO.forest,    ONB_PHOTO.cathedral,
    ONB_PHOTO.pasta,     ONB_PHOTO.beach,     ONB_PHOTO.city,
  ];
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
      gap: 6, width: '100%',
    }}>
      {photos.map((src, i) => (
        <div key={i} style={{
          position: 'relative',
          aspectRatio: '1 / 1', borderRadius: 12, overflow: 'hidden',
          background: tokens.photoFallback,
          boxShadow: tokens.photoInner,
        }}>
          <img src={src} alt="" loading="lazy"
            style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
          {highlight && i === 0 && (
            <>
              <div style={{
                position: 'absolute', inset: 0, borderRadius: 12,
                border: '2px solid #8E6450', pointerEvents: 'none',
              }}/>
              <div style={{
                position: 'absolute', top: 6, right: 6,
                width: 18, height: 18, borderRadius: 999,
                background: '#8E6450', color: '#FFFFFF',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
                  <path d="M5 12l5 5 9-11" stroke="#FFFFFF" strokeWidth="3"
                    strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
            </>
          )}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────
// Direction A · Editorial
// ─────────────────────────────────────────────────────────────────

function EditorialOnboarding({ tokens, step }) {
  const meta = STEPS[step - 1];

  // Per-step body content
  let Visual = null, headline = '', body = '', subnote = null;
  if (step === 1) {
    Visual = <PhotoStack tokens={tokens}/>;
    headline = 'Your photos already hold the story.';
    body = 'We help you put it into words — a quiet two-paragraph diary entry, written in your tone.';
  } else if (step === 2) {
    Visual = <MiniHeroCard tokens={tokens}/>;
    headline = 'Pick a photo. We do the writing.';
    body = 'In about three seconds, an entry anchored to the moment — yours to keep, edit or share.';
  } else if (step === 3) {
    Visual = <PrivacyGroup tokens={tokens}/>;
    headline = 'Your diary stays here.';
    body = null;
  } else {
    Visual = <PhotoGridTeaser tokens={tokens}/>;
    headline = 'Start with today.';
    body = 'We\u2019ll ask for access to your photos to craft your first story.';
    subnote = 'Only the photos you choose are read — we never upload them anywhere.';
  }

  return (
    <div style={{
      display: 'flex', flexDirection: 'column', flex: 1,
      background: tokens.surface, color: tokens.title,
    }}>
      <OnbHeader tokens={tokens} step={step}/>

      {/* Hero visual area — fixed height so all 4 screens align */}
      <div style={{
        padding: '32px 22px 0',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        minHeight: 296,
      }}>
        <div style={{ width: '100%' }}>{Visual}</div>
      </div>

      {/* Text block */}
      <div style={{
        flex: 1,
        padding: '32px 22px 0',
        display: 'flex', flexDirection: 'column', gap: 14,
      }}>
        <OnbEyebrow color={tokens.accentMuted}>{meta.eyebrow}</OnbEyebrow>
        <OnbHeadline color={tokens.title}>{headline}</OnbHeadline>
        {body && <OnbBody color={tokens.muted}>{body}</OnbBody>}
        {subnote && (
          <div style={{
            marginTop: 4, padding: '10px 12px 10px 14px', borderRadius: 10,
            background: tokens.glyphBg,
            display: 'flex', gap: 10, alignItems: 'flex-start',
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
              style={{ marginTop: 2, flexShrink: 0 }}>
              <circle cx="12" cy="12" r="9" stroke={tokens.accentMuted} strokeWidth="1.8"/>
              <path d="M12 8v5M12 16h.01" stroke={tokens.accentMuted}
                strokeWidth="1.8" strokeLinecap="round"/>
            </svg>
            <div style={{
              fontSize: 12, lineHeight: 1.45, color: tokens.muted,
            }}>{subnote}</div>
          </div>
        )}
      </div>

      {/* CTA */}
      <div style={{
        padding: '20px 22px 28px',
      }}>
        <PrimaryCTA tokens={tokens} label={meta.cta} icon={step === 4}/>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────
// Direction B · Photo-led
// ─────────────────────────────────────────────────────────────────
// Top ~58% is a full-bleed photo (or photo-collage) with an editorial
// overlay: eyebrow + headline in white over a soft bottom scrim.
// Bottom ~42% is a surface tray carrying body + CTA.

function PhotoLedOnboarding({ tokens, step }) {
  const meta = STEPS[step - 1];

  // Pick the cover photo + body per step
  let cover, overlayTitle, trayBody, trayExtra = null;
  if (step === 1) {
    cover = ONB_PHOTO.cathedral;
    overlayTitle = 'Your photos already hold the story.';
    trayBody = 'A quiet two-paragraph diary entry, written in your tone.';
  } else if (step === 2) {
    cover = ONB_PHOTO.cat;
    overlayTitle = 'Pick a photo. We do the writing.';
    trayBody = 'In about three seconds, an entry anchored to the moment — yours to edit, keep or share.';
  } else if (step === 3) {
    cover = ONB_PHOTO.forest;
    overlayTitle = 'Your diary stays on this device.';
    trayBody = 'No account, no upload, no sync. You own every word.';
    trayExtra = (
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 10 }}>
        <span style={{
          padding: '4px 9px', borderRadius: 7,
          background: tokens.tagAccentBg, color: tokens.tagAccentFg,
          fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
        }}>On device only</span>
        <span style={{
          padding: '4px 9px', borderRadius: 7,
          background: tokens.tagSecondaryBg, color: tokens.tagSecondaryFg,
          fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
        }}>No account</span>
        <span style={{
          padding: '4px 9px', borderRadius: 7,
          background: tokens.tagPrimaryBg, color: tokens.tagPrimaryFg,
          fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
        }}>You own everything</span>
      </div>
    );
  } else {
    cover = ONB_PHOTO.sunset;
    overlayTitle = 'Start with today.';
    trayBody = 'We\u2019ll ask for access to your photos to craft your first story. Only what you select is read.';
  }

  return (
    <div style={{
      display: 'flex', flexDirection: 'column', flex: 1,
      background: tokens.surface, color: tokens.title,
      position: 'relative',
    }}>
      {/* full-bleed cover */}
      <div style={{
        position: 'relative', width: '100%',
        height: 510, overflow: 'hidden',
      }}>
        <img src={cover} alt="" loading="lazy"
          style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}/>
        {/* top scrim (legibility for header) */}
        <div style={{
          position: 'absolute', left: 0, right: 0, top: 0, height: 140,
          background: 'linear-gradient(180deg, rgba(0,0,0,0.45) 0%, rgba(0,0,0,0) 100%)',
          pointerEvents: 'none',
        }}/>
        {/* bottom scrim (legibility for overlay text) */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, height: 280,
          background: 'linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(0,0,0,0.65) 100%)',
          pointerEvents: 'none',
        }}/>

        {/* header (progress + skip), on the scrim */}
        <div style={{ position: 'absolute', left: 0, right: 0, top: 0 }}>
          <OnbHeader tokens={tokens} step={step} onDark/>
        </div>

        {/* overlay text */}
        <div style={{
          position: 'absolute', left: 22, right: 22, bottom: 24,
          color: '#FFFFFF',
        }}>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1.4,
            textTransform: 'uppercase', color: 'rgba(255,255,255,0.85)',
            marginBottom: 10,
          }}>{meta.eyebrow}</div>
          <div style={{
            fontSize: 30, fontWeight: 700, lineHeight: 1.12,
            letterSpacing: -0.5, textShadow: '0 1px 24px rgba(0,0,0,0.35)',
            textWrap: 'balance',
          }}>{overlayTitle}</div>
        </div>
      </div>

      {/* tray */}
      <div style={{
        flex: 1, marginTop: -22, position: 'relative',
        background: tokens.surface,
        borderTopLeftRadius: 24, borderTopRightRadius: 24,
        padding: '22px 22px 28px',
        display: 'flex', flexDirection: 'column',
      }}>
        <OnbBody color={tokens.muted}>{trayBody}</OnbBody>
        {trayExtra}
        <div style={{ flex: 1 }}/>
        <PrimaryCTA tokens={tokens} label={meta.cta} icon={step === 4}/>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────
// public entrypoint
// ─────────────────────────────────────────────────────────────────

function OnboardingScreen({ tokens, step = 1, variant = 'editorial' }) {
  return variant === 'photo'
    ? <PhotoLedOnboarding tokens={tokens} step={step}/>
    : <EditorialOnboarding tokens={tokens} step={step}/>;
}

// ─────────────────────────────────────────────────────────────────
// notes card (sits at the head of the canvas section, like every
// other screen's "What changed" card)
// ─────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────
// Flutter handoff — Editorial direction
// ─────────────────────────────────────────────────────────────────

const ONBOARDING_FLUTTER_CODE = `// Refactored onboarding_screen.dart — Editorial direction.
//
// Drop-in replacement for the current 4-page onboarding. Keeps the
// existing route, navigation entry-point, and \"skip / advance / finish\"
// callbacks; only the page composition and per-page visuals change.
//
// Reuses widgets from the rest of the Hero redesign so the user lands
// on a Diaries list whose vocabulary is already familiar:
//   - SettingsRow            — used for the privacy list (step 3)
//   - DiaryHeroPhoto         — used for the mini sample card (step 2)
//   - _DiaryTagRow           — same 3-tone filled chips
//   - AppColors, AppTypography, AppSpacing tokens throughout

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  static const _total = 4;

  void _advance() {
    if (_index < _total - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(children: [
          _OnboardingHeader(
            step: _index + 1, total: _total,
            onSkip: widget.onFinished,
          ),
          Expanded(child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: [
              _PageWelcome(l10n: l10n),
              _PageHowItWorks(l10n: l10n),
              _PagePrivacy(l10n: l10n),
              _PageReady(l10n: l10n),
            ],
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: _PrimaryCTA(
              label: _ctaLabel(_index, l10n),
              showArrow: _index == _total - 1,
              onPressed: _advance,
            ),
          ),
        ]),
      ),
    );
  }

  String _ctaLabel(int i, AppLocalizations l10n) => switch (i) {
    0 => l10n.onboardingCtaBegin,
    1 => l10n.onboardingCtaNext,
    2 => l10n.onboardingCtaContinue,
    _ => l10n.onboardingCtaCreateFirstDiary,
  };
}

// ─── header (progress segments + skip) ─────────────────────────
class _OnboardingHeader extends StatelessWidget {
  final int step, total;
  final VoidCallback onSkip;
  const _OnboardingHeader({
    required this.step, required this.total, required this.onSkip,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.accentLight : AppColors.accentDark;
    final empty = cs.outlineVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 14, 8),
      child: Row(children: [
        for (int i = 0; i < total; i++) ...[
          Expanded(child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            height: 3,
            decoration: BoxDecoration(
              color: i < step ? fill : empty,
              borderRadius: BorderRadius.circular(999),
            ),
          )),
          if (i < total - 1) const SizedBox(width: 5),
        ],
        const SizedBox(width: 14),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: Text(context.l10n.onboardingSkip),
        ),
      ]),
    );
  }
}

// ─── shared page scaffold (visual + eyebrow + headline + body) ──
class _PageScaffold extends StatelessWidget {
  final Widget visual;
  final String eyebrow, headline;
  final String? body;
  final Widget? subnote;
  const _PageScaffold({
    required this.visual, required this.eyebrow,
    required this.headline, this.body, this.subnote,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: 296, child: Center(child: visual)),
        const SizedBox(height: 32),
        Text(eyebrow.toUpperCase(), style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4,
          color: accent,
        )),
        const SizedBox(height: 14),
        Text(headline, style: TextStyle(
          fontSize: 30, fontWeight: FontWeight.w700, height: 1.12,
          letterSpacing: -0.5, color: cs.onSurface,
        )),
        if (body != null) ...[
          const SizedBox(height: 14),
          Text(body!, style: TextStyle(
            fontSize: 15, height: 1.55, color: cs.onSurfaceVariant,
          )),
        ],
        if (subnote != null) ...[const SizedBox(height: 12), subnote!],
      ]),
    );
  }
}

// ─── page 1 — welcome + photo-stack motif ──────────────────────
class _PageWelcome extends StatelessWidget {
  final AppLocalizations l10n;
  const _PageWelcome({required this.l10n});
  @override
  Widget build(BuildContext context) => _PageScaffold(
    eyebrow: l10n.onboardingStep1Eyebrow,
    headline: l10n.onboardingStep1Headline,
    body: l10n.onboardingStep1Body,
    visual: const _PhotoStack(),
  );
}

class _PhotoStack extends StatelessWidget {
  const _PhotoStack();
  @override
  Widget build(BuildContext context) {
    final assets = OnboardingSampleAssets.welcomeStack;
    Widget tile({required String src, required double dx, required double dy,
        required double rot}) {
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rot * math.pi / 180,
          child: Container(
            width: 152, height: 196,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Color(0x2E231E1A),
                  blurRadius: 40, offset: Offset(0, 12)),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(src, fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: 320, height: 220,
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        tile(src: assets[0], dx: -86, dy: 0,   rot: -12),
        tile(src: assets[1], dx:  86, dy: 0,   rot:  10),
        tile(src: assets[2], dx:   0, dy: -16, rot:  -2),
      ]),
    );
  }
}

// ─── page 2 — sample Hero diary card ───────────────────────────
class _PageHowItWorks extends StatelessWidget {
  final AppLocalizations l10n;
  const _PageHowItWorks({required this.l10n});
  @override
  Widget build(BuildContext context) => _PageScaffold(
    eyebrow: l10n.onboardingStep2Eyebrow,
    headline: l10n.onboardingStep2Headline,
    body: l10n.onboardingStep2Body,
    visual: _MiniHeroCard(l10n: l10n),
  );
}

class _MiniHeroCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _MiniHeroCard({required this.l10n});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.cardShadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 3 / 2,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(OnboardingSampleAssets.sampleEntry, fit: BoxFit.cover),
            Positioned(top: 10, left: 10, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(l10n.onboardingExampleEntryPill.toUpperCase(),
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.9,
                  color: AppColors.accentDark, height: 1.0,
                )),
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.onboardingSampleDate.toUpperCase(), style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7,
              color: accent,
            )),
            const SizedBox(height: 6),
            Text(l10n.onboardingSampleTitle, style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, height: 1.22,
              letterSpacing: -0.2, color: cs.onSurface,
            )),
            const SizedBox(height: 6),
            Text(l10n.onboardingSampleExcerpt, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, height: 1.55,
                color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            _DiaryTagRow(tags: [
              l10n.onboardingSampleTag1,
              l10n.onboardingSampleTag2,
              l10n.onboardingSampleTag3,
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── page 3 — privacy promises (grouped card like Settings) ────
class _PagePrivacy extends StatelessWidget {
  final AppLocalizations l10n;
  const _PagePrivacy({required this.l10n});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return _PageScaffold(
      eyebrow: l10n.onboardingStep3Eyebrow,
      headline: l10n.onboardingStep3Headline,
      visual: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: l10n.onboardingPrivacyOnDeviceTitle,
            subtitle: l10n.onboardingPrivacyOnDeviceSubtitle,
          ),
          const _RowDivider(),
          SettingsRow(
            icon: Icons.shield_outlined,
            title: l10n.onboardingPrivacyNoAccountTitle,
            subtitle: l10n.onboardingPrivacyNoAccountSubtitle,
          ),
          const _RowDivider(),
          SettingsRow(
            icon: Icons.verified_outlined,
            title: l10n.onboardingPrivacyYouOwnTitle,
            subtitle: l10n.onboardingPrivacyYouOwnSubtitle,
          ),
        ]),
      ),
    );
  }
}

// ─── page 4 — permission preview (3×3 grid teaser) ─────────────
class _PageReady extends StatelessWidget {
  final AppLocalizations l10n;
  const _PageReady({required this.l10n});
  @override
  Widget build(BuildContext context) => _PageScaffold(
    eyebrow: l10n.onboardingStep4Eyebrow,
    headline: l10n.onboardingStep4Headline,
    body: l10n.onboardingStep4Body,
    subnote: _Subnote(text: l10n.onboardingStep4Note),
    visual: const _PhotoGridTeaser(),
  );
}

class _PhotoGridTeaser extends StatelessWidget {
  const _PhotoGridTeaser();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final assets = OnboardingSampleAssets.gridTeaser;
    return SizedBox(
      width: 280,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
        ),
        itemBuilder: (context, i) => Stack(children: [
          Positioned.fill(child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(assets[i], fit: BoxFit.cover),
          )),
          if (i == 0)
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent, width: 2),
              ),
            )),
          if (i == 0)
            Positioned(top: 6, right: 6, child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: accent, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                size: 12, color: Colors.white),
            )),
        ]),
      ),
    );
  }
}

class _Subnote extends StatelessWidget {
  final String text;
  const _Subnote({required this.text});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3633) : const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 14, color: accent),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(
          fontSize: 12, height: 1.45, color: cs.onSurfaceVariant,
        ))),
      ]),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 66),
    child: Container(
      height: 0.5, color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

// ─── primary CTA (matches prompt modal / filter sheet / home) ──
class _PrimaryCTA extends StatelessWidget {
  final String label;
  final bool showArrow;
  final VoidCallback onPressed;
  const _PrimaryCTA({
    required this.label, required this.showArrow,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        elevation: 6,
        shadowColor: accent.withValues(alpha: 0.35),
      ),
      child: Row(mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label),
        if (showArrow) ...[
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 16),
        ],
      ]),
    );
  }
}

// ─── shipped sample assets ─────────────────────────────────────
// Bundle ~9 neutral, royalty-free photos with the app so the
// pre-permission previews always have something to show.
class OnboardingSampleAssets {
  static const welcomeStack = [
    'assets/onboarding/sunset.jpg',
    'assets/onboarding/cat.jpg',
    'assets/onboarding/cathedral.jpg',
  ];
  static const sampleEntry = 'assets/onboarding/cat.jpg';
  static const gridTeaser = [
    'assets/onboarding/coffee.jpg',  'assets/onboarding/flowers.jpg', 'assets/onboarding/sunset.jpg',
    'assets/onboarding/cat.jpg',     'assets/onboarding/forest.jpg',  'assets/onboarding/cathedral.jpg',
    'assets/onboarding/pasta.jpg',   'assets/onboarding/beach.jpg',   'assets/onboarding/city.jpg',
  ];
}`;

function OnboardingCodeCard() {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: '#1F1B17', color: '#E8E2DC', borderRadius: 18,
      padding: 24, boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column', gap: 16,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui, sans-serif',
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
        <div style={{ fontSize: 22, fontWeight: 700, color: '#FAF8F5', letterSpacing: -0.3 }}>
          Flutter handoff · onboarding
        </div>
        <div style={{ fontSize: 13, color: '#9E9891' }}>
          onboarding_screen.dart · editorial direction
        </div>
      </div>
      <div style={{ fontSize: 13, lineHeight: 1.55, color: '#C7C0B8' }}>
        Drop-in replacement for <code style={{ background: '#2E2A27', padding: '1px 6px', borderRadius: 4, color: '#E4BEA3' }}>OnboardingScreen</code>.
        Reuses three widgets already in the Hero redesign:
        <code style={{ background: '#2E2A27', padding: '1px 6px', borderRadius: 4, color: '#E4BEA3', marginLeft: 4 }}>SettingsRow</code> for the privacy list,
        <code style={{ background: '#2E2A27', padding: '1px 6px', borderRadius: 4, color: '#E4BEA3', marginLeft: 4 }}>_DiaryTagRow</code> for the sample card chips,
        and the same accent <code style={{ background: '#2E2A27', padding: '1px 6px', borderRadius: 4, color: '#E4BEA3' }}>FilledButton</code> styling
        used across the prompt modal / filter sheet / home selection bar.
        Ship ~9 sample photos under <code style={{ background: '#2E2A27', padding: '1px 6px', borderRadius: 4, color: '#E4BEA3' }}>assets/onboarding/</code> for
        the welcome stack + grid teaser. Add new l10n keys
        <code style={{ background: '#2E2A27', padding: '1px 6px', borderRadius: 4, color: '#E4BEA3', marginLeft: 4 }}>onboardingStep1…onboardingStep4…</code>
        to the existing ARB files.
      </div>
      <pre style={{
        flex: 1, margin: 0, overflow: 'auto',
        background: '#15120F', borderRadius: 12, padding: 18,
        fontFamily: '"JetBrains Mono", ui-monospace, "SF Mono", Menlo, monospace',
        fontSize: 11.5, lineHeight: 1.55, color: '#E8E2DC',
      }}>{ONBOARDING_FLUTTER_CODE}</pre>
    </div>
  );
}

function OnboardingNotesCard() {
  const Bullet = ({ title, body }) => (
    <div style={{ display: 'flex', gap: 14 }}>
      <div style={{ width: 6, height: 6, borderRadius: 999, background: '#B8856C',
        marginTop: 9, flexShrink: 0 }}/>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700, color: '#2C2825', marginBottom: 2 }}>{title}</div>
        <div style={{ fontSize: 13, lineHeight: 1.55, color: '#6B6560' }}>{body}</div>
      </div>
    </div>
  );
  return (
    <div style={{
      width: '100%', height: '100%', background: '#FAF8F5', borderRadius: 18,
      padding: 26, boxSizing: 'border-box', border: '0.5px solid rgba(0,0,0,0.05)',
      display: 'flex', flexDirection: 'column', gap: 16,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui, sans-serif',
    }}>
      <div>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1,
          textTransform: 'uppercase', color: '#8E6450', marginBottom: 6 }}>
          Onboarding
        </div>
        <div style={{ fontSize: 22, fontWeight: 700, color: '#2C2825',
          letterSpacing: -0.3, lineHeight: 1.25 }}>
          Same dialect as the rest of the app
        </div>
      </div>
      <Bullet title="Header tier, finally consistent"
        body="The four screens were the only place in the app missing the accent eyebrow → bold headline ramp. They now lead with 01–04 / category labels in 11 / w700 accent terracotta, then a 30 / w700 / −0.5 tracking headline — exactly the type system used on the Diaries list, Settings, Statistics and Generation screens."/>
      <Bullet title="Page indicator promoted to the top"
        body="The four bottom dots become a slim 4-segment progress track at the top, alongside Skip. It reads as progress, not decoration, and pairs the Skip action with the navigation cue instead of orphaning it. Same vocabulary as the plan-card progress in Settings."/>
      <Bullet title="Decorative glyphs replaced with product previews"
        body="The app-icon, the shield, and the empty space on screens 1, 3 and 4 are doing nothing — onboarding is the only chance to preview the product, and they spend it on ornament. They become: a three-photo fan (1, hints at the diary), a grouped privacy card lifted straight from Settings (3, shows the actual UI), and a 3×3 photo-grid teaser with the most recent photo pre-selected (4, sets expectations for what permission unlocks)."/>
      <Bullet title="The example diary card is the real Hero card"
        body="Screen 2 currently renders a card in the old CardBaseline vocabulary — outlined chip, regular-weight title, no real hero photo. It now uses the redesigned Hero card (3:2 photo, accent date label, w700 title, filled 3-tone chips) with a small 'EXAMPLE ENTRY' pill so onboarding teaches the same vocabulary the rest of the app uses."/>
      <Bullet title="Primary CTA matches the system"
        body="Was: 56-tall pill in a flat brown. Now: 52 / 14 radius / accent terracotta with a soft accent-tinted shadow — same button used in the prompt modal, generation flow, filter sheet and home selection bar. The final step's button carries a → glyph to signal commit."/>
      <Bullet title="Two directions to compare"
        body="A · Editorial (recommended) keeps the four-screen structure and the Quiet Luxury restraint — strongest fit with the rest of the redesign. B · Photo-led pushes harder: each screen is anchored by a full-bleed photo carrying the headline in white over a scrim, with the body + CTA on a tray below. More dramatic; useful as a future App Store screenshot story."/>
    </div>
  );
}

Object.assign(window, {
  OnboardingScreen, OnboardingNotesCard, OnboardingCodeCard, STEPS,
});
