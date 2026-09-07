```yaml
version: alpha
name: ScanSafe
description: A calm, high-contrast dark interface for an on-device QR phishing detector, where colour carries a safety verdict and must never be decorative.

colors:
  background: "#000000"
  on-background: "#FAFAFA"
  surface: "#141414"
  on-surface: "#F5F5F5"
  surface-variant: "#1E1E1E"
  on-surface-variant: "#8A8A8A"
  outline: "#2A2A2A"
  outline-strong: "#3D3D3D"
  primary: "#2FE98A"
  on-primary: "#04160D"
  success: "#2FE98A"
  success-container: "#0C2A1B"
  on-success-container: "#7CF3BB"
  warning: "#FFC933"
  warning-container: "#2E2408"
  on-warning-container: "#FFDD84"
  error: "#FF4038"
  error-container: "#2E0F0D"
  on-error-container: "#FF9C97"

typography:
  verdict:
    fontFamily: system-sans
    fontSize: 34px
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: -0.01em
  headline:
    fontFamily: system-sans
    fontSize: 26px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.01em
  title:
    fontFamily: system-sans
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: system-sans
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  body-muted:
    fontFamily: system-sans
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.5
  label-caps:
    fontFamily: system-sans
    fontSize: 12px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: 0.12em
  button:
    fontFamily: system-sans
    fontSize: 17px
    fontWeight: 700
    lineHeight: 1.2
  mono-url:
    fontFamily: system-mono
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.45
  mono-detail:
    fontFamily: system-mono
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.55

rounded:
  sm: 8px
  md: 12px
  lg: 18px
  pill: 999px

spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  xxl: 32px

components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
    height: 52px
  button-primary-disabled:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
    height: 52px
  button-scan:
    backgroundColor: "{colors.success-container}"
    textColor: "{colors.primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
    height: 56px
  button-text:
    backgroundColor: "{colors.background}"
    textColor: "{colors.primary}"
    typography: "{typography.body-muted}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm}"
    height: 36px
  input-url:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
    height: 56px
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  section-label:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.label-caps}"
    rounded: "{rounded.sm}"
    padding: "{spacing.xs}"
  verdict-safe:
    backgroundColor: "{colors.success-container}"
    textColor: "{colors.success}"
    typography: "{typography.verdict}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  verdict-suspicious:
    backgroundColor: "{colors.warning-container}"
    textColor: "{colors.warning}"
    typography: "{typography.verdict}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  verdict-high-risk:
    backgroundColor: "{colors.error-container}"
    textColor: "{colors.error}"
    typography: "{typography.verdict}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  finding-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  finding-detail:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.mono-detail}"
    rounded: "{rounded.sm}"
    padding: "{spacing.md}"
  url-display:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.mono-url}"
    rounded: "{rounded.sm}"
    padding: "{spacing.md}"
  history-row:
    backgroundColor: "{colors.background}"
    textColor: "{colors.on-surface}"
    typography: "{typography.mono-url}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
  scan-reticle:
    backgroundColor: "{colors.background}"
    textColor: "{colors.primary}"
    typography: "{typography.body-muted}"
    rounded: "{rounded.lg}"
    padding: "{spacing.xl}"
    size: 260px
```

## Overview

ScanSafe is a security instrument that has to stay calm. It is used in the two seconds
between seeing a QR code and deciding whether to trust it, often outdoors, often
one-handed, often on a phone at 15% battery. The interface is derived directly from the
working Flask prototype: pure black ground, a single neon-green accent, and generous
card separation. The emotional target is *steadiness* — the app should feel like a
careful friend who checked something for you, not an alarm going off.

Two anti-patterns to avoid. First, security theatre: no shields, no padlock iconography,
no red pulsing borders. The verdict earns attention through typographic weight and
contrast, not motion. Second, decorative colour: green, amber and red mean exactly one
thing in this product, and using any of them for a non-verdict purpose destroys the only
signal that matters.

## Colors

The ground is true black rather than dark grey. It is honest on OLED phones, it saves
battery on the device this app is most used on, and it makes the verdict colours read at
a glance in daylight. Cards sit at `surface` `#141414` with a `outline` `#2A2A2A` hairline
— separation comes from that one-pixel border, not from shadow.

`primary` `#2FE98A` is the accent inherited from the prototype and it does double duty as
`success`. That is deliberate: the safest thing in the product and the primary action are
the same green, so the palette only ever teaches the user three meanings. `warning`
`#FFC933` and `error` `#FF4038` complete the verdict triad. Each verdict also has a deep
`*-container` background for its badge, so the badge tints without the text losing contrast.

All three verdict colours clear WCAG AA against `background` at the sizes they are used
(`verdict` is 34px/800, comfortably large text). Body copy always uses `on-surface`
`#F5F5F5`, never a verdict colour — a red paragraph is much harder to read than a red
heading, and the reasoning matters more than the alarm.

## Typography

The system sans (SF Pro on iOS, Roboto on Android) carries the interface, and the system
monospace carries anything the user might need to inspect character by character. That
split is the core typographic idea: prose is for understanding, monospace is for evidence.

`verdict` at 34px/800 is the loudest thing on any screen and appears exactly once per
result. `headline` and `title` structure the screens. `body` at 16px/1.5 is the
plain-English finding text and is the most-read style in the product, so it gets the
comfortable line height. `label-caps` — 12px, 700, 0.12em tracking, uppercase — marks
sections like PLAIN-ENGLISH SUMMARY and TECHNICAL DETAIL, straight from the prototype.

`mono-url` renders every URL. Users need to compare `paypa1` against `paypal` character
by character, and a proportional font actively hides that difference. `mono-detail` at
13px carries rule output. Never render a URL in the sans stack.

## Layout

Spacing is a 4px base scale: 4, 8, 12, 16, 24, 32. Screen gutters are `spacing.lg` (16px),
which is the standard comfortable phone margin. Cards stack vertically with `spacing.md`
(12px) between them and `spacing.xl` (24px) between distinct groups.

The layout model is a single scrolling column. There is no grid, no multi-column
arrangement, and no horizontal scrolling anywhere in the app — a security verdict that
requires the user to scroll sideways to find the reason is a broken verdict. Density is
deliberately loose: this app is read under stress and skim-ability beats information
density every time.

Touch targets are minimum 44px, and the two primary actions (scan a link, scan a code)
are full-width so they can be hit one-handed without looking.

## Elevation & Depth

There are no shadows. On a true-black ground, shadow is invisible and any attempt to fake
it produces muddy grey halos. Depth is expressed entirely through surface lightness plus a
hairline border: `background` `#000000` → `surface` `#141414` → `surface-variant` `#1E1E1E`,
each with an `outline` border where a boundary needs to be unambiguous.

This gives three usable depth levels, which is enough. If something needs to feel
"higher" than a card, it becomes a full screen rather than a floating panel. Modals are
reserved for destructive confirmation only.

## Shapes

Corners are generous and consistent: `rounded.lg` (18px) for cards and verdict badges,
`rounded.md` (12px) for buttons and inputs, `rounded.sm` (8px) for inline code blocks and
detail panels. Nothing in the product is fully square — hard corners read as system alerts
and system alerts read as panic.

`rounded.pill` (999px) is reserved for the compact verdict chip in scan history, where a
pill shape distinguishes a summary badge from a tappable card.

One deliberate exception to the flat-fill rule: the QR scan button uses a dashed border.
It is the one piece of visual wit in the product — the dashes read as a viewfinder, and it
separates the camera action from the primary filled button without introducing a second
accent colour.

## Components

`button-primary` is the filled green action — one per screen, maximum. `button-scan` is
the dashed-border camera affordance on `success-container`, visually secondary but
physically the largest target, because scanning a code is the main path and typing a URL
is the fallback. `button-primary-disabled` drops to `surface-variant` with muted text;
disabled states must never keep the green, since green means safe.

`card` is the workhorse container: `surface` fill, `outline` hairline, 18px radius, 16px
padding. Every result section is a card. `section-label` sits at the top of a card in
`label-caps` and `on-surface-variant`.

The three `verdict-*` components share a structure and differ only in colour token, so a
single widget takes the verdict as a parameter rather than branching into three
implementations. Each renders an icon and the verdict word alongside the colour — colour
is never the only carrier of meaning.

`finding-row` holds one fired rule: plain-English text in `body`, an optional `+N` weight
in `on-surface-variant`, and a "See details" text button revealing a `finding-detail`
monospace panel. `url-display` and `history-row` both render URLs in `mono-url`, always
selectable and never tappable as a link.

## Do's and Don'ts

**Do**
- Use green, amber and red only to communicate a scan verdict.
- Render every URL and every rule output in the monospace stack.
- Pair every verdict colour with an icon and a text label, so the meaning survives in
  greyscale and for colour-blind users.
- Keep the plain-English layer visible by default and the technical layer one tap away.
- Let cards breathe — 16px padding minimum, even when it costs a scroll.

**Don't**
- Don't make a scanned URL tappable. The app explains links; it never navigates to them.
- Don't add shadows, glows, or pulsing borders to convey risk. Weight and contrast do it.
- Don't use the accent green for a disabled, neutral, or decorative element.
- Don't write a finding that could apply to any URL — always name the pattern actually
  detected, matching the voice in `docs/product-vision.md`.
- Don't introduce a second accent hue. The palette is three verdict colours and one
  neutral ramp; anything more dilutes the only signal the product has.
- Don't set body copy in a verdict colour. Headings carry the alarm, prose carries the
  explanation.
