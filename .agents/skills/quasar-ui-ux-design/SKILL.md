---
name: quasar-ui-ux-design
description: Guidelines and best practices for creating modern, minimal, and highly responsive UI/UX designs using Quasar Framework v2 (Vue 3) for Web and Android.
---

# Quasar Framework v2 (Vue 3) UI/UX Design System

This guide outlines the core design system principles, responsive standards, and minimal aesthetics for building premium Web and Android layouts using Quasar Framework v2.

---

## 1. Component Density & Elevation
Avoid flat, stark white designs and heavy default box-shadows. Maintain a clean, structure-defined card/container strategy.
- **Elevation**: Favor `flat` or `unelevated` combined with subtle, clean border classes like `bordered` instead of relying on default shadows (`shadow-0` to `shadow-24`).
- **Card Design**: Prefer `flat bordered` cards for sections. Use extremely subtle custom shadows if elevation is necessary.
- **Enterprise Density**: Use the `dense` prop on components where heavy data display or dense information architecture is required (e.g., `QTable`, `QInput`, `QSelect`, `QList`, `QItem`, `QBtn`). This maximizes data density without sacrificing scanning clarity.

---

## 2. Color Theory & Design Tokens
Never hardcode HEX values (e.g., `#FFFFFF` or `#1976D2`) directly in templates. Always rely on Quasar's dynamic utility classes and styling system.
- **Dynamic CSS Classes**:
  - Main colors: `bg-primary`, `text-primary`, `bg-secondary`, `text-secondary`, `bg-accent`.
  - Neutrals: `bg-grey-1` to `bg-grey-10`, `text-grey-8`, `bg-white`, `text-dark`.
  - Contrast containers: Use `bg-grey-2` or dynamic background selectors for layouts to give clean contrast between pages, bars, and cards.
- **Typography Tokens**: Use text weight and size helpers:
  - `text-subtitle2`, `text-caption`, `text-weight-medium`, `text-weight-bold`.
- **System Theme Resilience**: Ensure high color contrast under both Light and Dark modes.

---

## 3. Spacing Integrity & Layout Controls
Use Quasar's layout engine to create breathing room without breaking components.
- **Layout Multipliers**: Use uniform paddings and margins via class names (`q-pa-xs`, `q-pa-sm`, `q-pa-md`, `q-pa-lg`, `q-ma-md`, etc.).
- **Gutter Controls**: Use `q-col-gutter-xs`, `q-col-gutter-sm`, `q-col-gutter-md` on layout grids (`row` / `column`) to separate grid items cleanly.
- **Structural Safety**: Never apply margins or paddings directly to structural layout container wrappers (like `QLayout`, `QPageContainer`, `QDrawer`). Keep these wrappers clean to prevent layout calculation breakages, especially on mobile Web/Android.

---

## 4. Interactive Decoration
Enhance usability on desktop (web) and mobile (Android touch devices).
- **Interactive State Cues**: Ensure interactive elements use visual hover/focus/active states. Use `cursor-pointer` to indicate clickability.
- **Button & Control Shapes**: Utilize `square` controls where appropriate for toolbars/headers or specific utility boxes, and standard rounded structures elsewhere for consistency.
- **Touch-Friendly Hitboxes**: For Android/Mobile viewports, ensure interactive components have a minimum target size of `48px` to facilitate easy touch interaction.

---

## 5. Modern & Minimal UI Rules
To create an experience that feels premium and state of the art:
- **Clean Contrast**: Use modern backgrounds (like `bg-grey-2` or dynamic dark mode backgrounds) to contrast against flat, bordered content cards.
- **Micro-Animations**: Add subtle transition effects on page loads, tab switches, and hover interactions (e.g., transition classes, `q-hoverable`).
- **Premium Typography**: Rely on high-quality sans-serif typography (e.g., Inter, Outfit, Roboto) with correct scale hierarchies (`text-h5`, `text-subtitle1`, `text-subtitle2`, `text-caption`).
- **No Stark Gradients**: Ensure any gradients are extremely subtle, leveraging HSL-tailored colors rather than aggressive primary/secondary spectrums.
- **Clean Boundaries**: Keep dividers minimal (`q-separator` with `inset` or `spaced` where appropriate).

---

## 6. Mobile-First & Web Responsiveness (Multi-Platform)
Since the application targets both Web (desktop) and Android (mobile app/wrapper):
- **Flex Grid System**: Always design using Quasar's 12-column grid (`row`, `col-12`, `col-sm-6`, `col-md-4`).
- **Mobile Breakpoint Strategy**: Design mobile-first. Default classes should target mobile screen sizes (`xs`, `sm`), scaling up to `md` and `lg` for desktop.
  - *Example*: `<div class="col-12 col-md-6">`
- **Platform Visibility Helpers**: Use visibility helper classes to optimize screens:
  - `gt-xs` / `gt-sm` to show desktop-only side panels, extended tables, or multi-column layouts.
  - `lt-sm` / `lt-md` to display mobile-only headers, tabs, bottom navigation, or card-based views instead of heavy tables.
- **Gesture and Scroll Protection**: Keep layouts bounded. Avoid horizontal scroll bars on mobile viewports. Wrap table columns appropriately or transition to list cards on extra-small (`xs`) screens.
