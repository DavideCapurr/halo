# SWARM v1 - Halo adoption brief

> **ARCHIVIATO (2026-06-12).** Questo brief (mono platinum · 3 activation
> lime/purple/magenta · Satoshi display) **non è più la direzione canonica**.
> La direzione confermata per Halo è **swarm-halo (warm/bronze)**: vedi
> `docs/design-system/swarm-halo-v1.md` e la raccomandazione in
> `docs/research/aesthetic-directions.md`. Documento tenuto solo come
> riferimento storico della famiglia SWARM. In caso di conflitto, vince
> swarm-halo.

This is the canonical design brief for Halo Fase A.

Halo is a consumer extension of SWARM, not a literal operator surface. The
result should sit between the SWARM parent system and the warmer Halo social
surface, while still reading unmistakably as SWARM at first glance.

Fase A establishes the SWARM family anchors before the larger product gaps
from the HALO strategy PDF. The consumer notes in
`docs/design-system/swarm-halo-v1.md` can inform Halo-specific warmth,
living surfaces and voice, but they cannot override the SWARM anchors in this
brief.

## Gap to close

The current iOS codebase leans too far toward warm surfaces, cream ink and
bronze activation. Fase A pulls it back into the SWARM family:

- Palette: mono 14-step scale from `absolute-black` to `platinum`.
- Activation: `orbital-blue` lime, `signal-green` purple and `launch-amber`
  magenta.
- Type: Cormorant Garamond, Satoshi, IBM Plex Mono and Space Grotesk.
- Type scale: 144, 64, 40, 28, 17, 15, 13 and 11.
- Radii: 6, 4, 2 and 999.
- Motion easing: `cubic-bezier(0.2, 0.7, 0.1, 1)`.
- Halo state mapping must be explicit in tokens and components.

## Palette

### Mono

Tokenize the full 14-step mono ramp before component refactors:

- `absolute-black` at the low end.
- Intermediate ink/surface/stroke steps for panels, hairlines and text
  hierarchy.
- `platinum` at the high end.

Components should consume semantic tokens from `Tokens.swift`, not literal
hex values.

### Activation

| Token | Color role | Reference |
|---|---|---|
| `orbital-blue` | lime connected state | `#B8FF00` |
| `signal-green` | purple operational state | `#7B2BFF` |
| `launch-amber` | magenta attention state | `#FF2BB8` |

## Type

| Role | Family |
|---|---|
| Hero / editorial display | Cormorant Garamond |
| Display / UI / body | Satoshi |
| Telemetry / timestamps | IBM Plex Mono |
| Eyebrow / system labels | Space Grotesk |

Bundle the required font files in the app when licensing allows it. Keep
system fallbacks wired in `HaloTypography.swift` so the app remains readable
when a font is unavailable.

## Scale and primitives

| Primitive | Values |
|---|---|
| Type scale | 144 / 64 / 40 / 28 / 17 / 15 / 13 / 11 |
| Spacing | 4 / 8 rhythm |
| Radii | 6 card / 4 input / 2 chip / 999 pill |
| Motion | `cubic-bezier(0.2, 0.7, 0.1, 1)` |

## Halo state mapping

| Halo state | SWARM state | Visual mapping |
|---|---|---|
| Inner | connected | `orbital-blue` lime |
| Close | operational | `signal-green` purple |
| Orbit | rest | `platinum` hairline |
| Nebula | far rest | `absolute-black` |
| Vibe attention | attention | `launch-amber` magenta |

## Fase A implementation checklist

1. Tokenize the mono ramp, activation colors, spacing, radii and motion in
   `HaloApp/DesignSystem/Tokens.swift`.
2. Replace the current typography wrapper with the four SWARM families and
   the SWARM type scale.
3. Express the Halo state mapping in shared design APIs before restyling
   screens.
4. Refactor the key components:
   `SelfCenterView`, `BubbleView`, `OrbitalRing`, `MomentCard`,
   `PresenceBar` and `HaloTabBar`.
5. Sweep visible voice and copy:
   sentence case, sharp periods and the welcome manifesto
   "Your people, not your audience".
6. Lint literal hex values in UI code and move them behind tokens.

## Consumerization guardrail

Halo can be softer than SWARM operator UI in copy, social rhythm and living
surfaces. It should not lose the SWARM family signal in palette structure,
activation colors, typography categories, token naming, stroke discipline or
motion grammar.
