---
name: <design system name>
description: <one line>
colors:
  ground: "#0f1115"
  surface: "#161a20"
  line: "#2a303a"
  fg: "#d6dbe3"
  fg-lo: "#8b93a1"
  accent: "#e0a526"
  ok: "#5fb58a"
  warn: "#d9a441"
  err: "#e06c6c"
typography:
  ui: { fontFamily: "Inter, system-ui, sans-serif" }
  mono: { fontFamily: "JetBrains Mono, ui-monospace, monospace" }
rounded: { sm: 4px, md: 6px, lg: 10px }
spacing: { xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 24px, xxl: 40px }
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.ground}"
    rounded: "{rounded.md}"
---

# Design System: <name>

Status: Draft. Tokens above are the source; apps map them to CSS variables (`--ground`, `--fg-lo`, …) and
Tailwind `@theme inline`. Components never use raw hex.

## Overview
1. <philosophy, e.g. dark first, calm ink ladder, accent for signal only>

## Colors
### Neutral
| token | hex | role |
|-------|-----|------|
| ground | #0f1115 | page background |

### Semantic
| token | role |
|-------|------|
| ok / warn / err | status only, never decoration |

### Light variant
<same tokens, light values; contrast table: every text/background pair ≥ 4.5:1>

### Named rules
- **The Accent Rule.** If more than ~5% of a screen is accent, something is decoration.

## Typography
## Layout
## Elevation & depth
## Shapes
## Components
### Buttons
### Inputs
### Tables
### Navigation
## Do's and don'ts
