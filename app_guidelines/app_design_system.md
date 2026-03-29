# The Design System: Tactical Serenity

## 1. Overview & Creative North Star

The Creative North Star for this system is **"The Vigilant Guardian."** In high-stress safety scenarios, the UI must transition seamlessly from a state of "Calm Oversight" to "Urgent Action." We reject the cluttered, boxy aesthetic of traditional utility apps in favor of a high-end editorial approach. 

This system breaks the "template" look through **Intentional Asymmetry** and **Tonal Depth**. By utilizing wide margins, overlapping map layers, and a sophisticated typographic scale, we create an environment that feels authoritative yet approachable. We use breathing room not just for aesthetics, but as a cognitive tool to lower the user's heart rate during potential encounters.

---

## 2. Colors & Surface Logic

The palette is rooted in high-visibility safety standards but refined through Material Design 3 logic to ensure a premium, intentional feel.

*   **Primary (`#ac2d00`):** Our "Safety Signal." Used exclusively for high-stakes actions like "Repel" or "Panic."
*   **Secondary (`#3d627d`):** Our "Reliable Anchor." Used for navigation, mapping interfaces, and community reporting.
*   **Tertiary (`#765700`):** The "Cautionary Tone." Reserved for moderate-risk hotspots and warnings.

### The "No-Line" Rule

**Strict Mandate:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a "Safe Route" card should sit as a `surface-container-lowest` element against a `surface-container-low` background.

### Surface Hierarchy & Nesting

Treat the UI as a physical stack of premium materials. 
*   **Base:** `surface` (#f9f9f9)
*   **De-emphasized Zones:** `surface-container-low` (#f3f3f3)
*   **Interactive Cards:** `surface-container-lowest` (#ffffff)
*   **Active Overlays:** `surface-container-high` (#e8e8e8)

### The "Glass & Gradient" Rule

To avoid a flat "out-of-the-box" look, floating action buttons (FABs) and navigation bars should utilize **Glassmorphism**. Apply a semi-transparent version of the surface color with a `20px` backdrop blur. 
*   **Signature Textures:** Main CTAs should use a subtle linear gradient from `primary` (#ac2d00) to `primary_container` (#d53e0b) at a 135° angle to provide tactile "soul" and professional polish.

---

## 3. Typography: The Editorial Voice

We use a dual-typeface system to balance authority with extreme legibility.

*   **Public Sans (Display & Headlines):** An authoritative, geometric sans-serif that commands attention without aggression. Used for status updates (e.g., "ZONE: CAUTION") and large titles.
*   **Inter (Body & Labels):** A highly legible workhorse optimized for small screens and stressful outdoor use.

**Hierarchy of Intent:**
- **Display-LG (3.5rem):** Reserved for immediate status alerts.
- **Title-MD (1.125rem):** Used for primary card headings to ensure quick scanning while walking.
- **Label-MD (0.75rem):** All-caps with 5% letter-spacing for metadata (e.g., "DISTANCE: 200M").

---

## 4. Elevation & Depth

We achieve hierarchy through **Tonal Layering** rather than structural lines.

*   **The Layering Principle:** Depth is "stacked." Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, natural lift.
*   **Ambient Shadows:** For "Emergency" floating elements, use extra-diffused shadows: `0px 12px 32px rgba(26, 28, 28, 0.06)`. The shadow must be a tinted version of the `on-surface` color to mimic natural light.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline_variant` token at **20% opacity**. 100% opaque borders are strictly forbidden.

---

## 5. Components

### Buttons (The Tactile Engine)

*   **Panic/Repel (Primary):** Large, `xl` (1.5rem) rounded corners. Uses the Primary Gradient. High-contrast white text (`on_primary`).
*   **Report (Secondary):** `surface-container-highest` background with `secondary` text. Non-aggressive but clear.
*   **Ghost (Tertiary):** No container. Text-only with `label-md` styling for low-priority actions like "View History."

### Input Fields

*   **Style:** No bottom lines or full borders. Use `surface-container-high` as a solid background fill with `md` (0.75rem) rounding. 
*   **Focus State:** A 2px "Ghost Border" using `secondary` at 40% opacity.

### Cards & Lists (The Divider-Free Rule)

*   **Cards:** Use `xl` (1.5rem) corner radius. Separation is achieved via a `16` (4rem) vertical spacing scale gap or a subtle shift from `surface` to `surface-container-low`.
*   **Lists:** Forbid divider lines. Use `8` (2rem) padding between items to let the negative space act as the separator.

### Specialized Components

*   **Status Halo:** A pulsing, semi-transparent ring around the user's location on the map, using `secondary` (Safe) or `primary` (Danger) to indicate the current safety perimeter.
*   **Haptic Trigger:** A large-format slider for "Confirm Repel" to prevent accidental triggers while maintaining high-speed access.

---

## 6. Do's and Don'ts

### Do

*   **Do** prioritize "Thumb-Zone" ergonomics. Place the Panic button within the bottom 25% of the screen.
*   **Do** use high-contrast text (`on_surface` on `surface`) to ensure the app is usable in direct sunlight or at night.
*   **Do** use asymmetrical layouts for map overlays to keep the interface feeling custom and high-end.

### Don't

*   **Don't** use 1px dividers. If you feel the need for a line, increase the white space instead.
*   **Don't** use pure black (#000000). Use `on_surface` (#1a1c1c) for a softer, more premium feel.
*   **Don't** use sharp corners. Everything must feel "friendly but firm," utilizing the `xl` and `lg` rounding tokens.
*   **Don't** clutter the screen during an active "Repel" state. Hide all non-essential navigation.