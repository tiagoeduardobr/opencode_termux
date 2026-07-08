---
created: 2026-07-07
name: design-system
description: "Unified design system skill: design tokens, CSS custom properties, theming infrastructure, component architecture, Figma pipeline, Tailwind integration, and migration guides. Use when creating design tokens, implementing theme switching, building component libraries, or establishing design system foundations."
user-invocable: false
allowed-tools: Glob, Grep, Read, Edit, Write, Bash(npm *), Bash(npx *), TodoWrite
---

# Design System

Unified design system skill covering tokens, theming, component architecture, and design-to-code pipelines.

## When to Use This Skill

| Use this skill when... | Use another skill instead when... |
|------------------------|-----------------------------------|
| Creating design tokens for colors, typography, spacing, shadows | Writing individual component styles |
| Implementing light/dark theme switching with CSS custom properties | Accessibility auditing (use accessibility skills) |
| Building multi-brand theming systems | CSS layout or responsive design |
| Architecting component libraries with consistent APIs | Framework-specific component patterns |
| Setting up Figma-to-code pipelines (Style Dictionary) | General frontend design questions |
| Integrating tokens with Tailwind or other frameworks | Build tool or bundler configuration |
| Creating semantic token hierarchies (primitive, semantic, component) | — |
| Migrating from hardcoded values or Sass variables | — |

## Core Capabilities

### 1. Design Tokens

- Primitive tokens (raw values: colors, sizes, fonts)
- Semantic tokens (contextual meaning: text-primary, surface-elevated)
- Component tokens (specific usage: button-bg, card-border)
- Token naming conventions and organization
- Multi-platform token generation (CSS, iOS, Android)
- Three-tier architecture: Primitive → Semantic → Component

### 2. Theming Infrastructure

- CSS custom properties architecture
- Theme context providers in React
- Dynamic theme switching (light/dark/system)
- System preference detection (`prefers-color-scheme`)
- Persistent theme storage (`localStorage`)
- Reduced motion and high contrast modes
- FOUC prevention for SSR

### 3. Component Architecture

- Compound component patterns
- Polymorphic components (`as` prop)
- Variant and size systems (CVA)
- Slot-based composition (Radix Slot)
- Headless UI patterns (hooks for behavior without style)
- Responsive variants

### 4. Token Pipeline

- Figma to code synchronization
- Style Dictionary configuration
- Token transformation and formatting
- CI/CD integration for token updates
- Platform-specific outputs (CSS, SCSS, Swift, Android XML)

### 5. CSS Custom Properties & Tailwind Integration

- Variable patterns and inheritance
- Tailwind config mapping to CSS variables
- Responsive tokens via media queries
- Fallback values and token scoping

## Quick Start

```typescript
// Design tokens with CSS custom properties
const tokens = {
  colors: {
    // Primitive tokens
    gray: {
      50: "#fafafa",
      100: "#f5f5f5",
      900: "#171717",
    },
    blue: {
      500: "#3b82f6",
      600: "#2563eb",
    },
  },
  // Semantic tokens (reference primitives)
  semantic: {
    light: {
      "text-primary": "var(--color-gray-900)",
      "text-secondary": "var(--color-gray-600)",
      "surface-default": "var(--color-white)",
      "surface-elevated": "var(--color-gray-50)",
      "border-default": "var(--color-gray-200)",
      "interactive-primary": "var(--color-blue-500)",
    },
    dark: {
      "text-primary": "var(--color-gray-50)",
      "text-secondary": "var(--color-gray-400)",
      "surface-default": "var(--color-gray-900)",
      "surface-elevated": "var(--color-gray-800)",
      "border-default": "var(--color-gray-700)",
      "interactive-primary": "var(--color-blue-400)",
    },
  },
};
```

## Detailed Patterns and Worked Examples

Detailed pattern documentation lives in `references/`. Read these files when the navigation tier above is insufficient:

- **`references/details.md`** — Token hierarchy, theme switching with React, CVA variants, Style Dictionary config
- **`references/design-tokens.md`** — Token categories (color, typography, spacing, effects), semantic mapping, naming conventions, governance
- **`references/component-architecture.md`** — Compound components, polymorphic `as` prop, slot pattern, headless hooks, CVA, responsive variants
- **`references/theming-architecture.md`** — CSS custom properties setup, React ThemeProvider, multi-brand theming, accessibility, SSR, testing
- **`references/reference.md`** — Theme switching JS, React context, JSON format, Tailwind integration, fallback values, migration guides

## Best Practices

1. **Name Tokens by Purpose**: Use semantic names (`text-primary`) not visual descriptions (`dark-gray`)
2. **Maintain Token Hierarchy**: Primitives > Semantic > Component tokens
3. **Document Token Usage**: Include usage guidelines with token definitions
4. **Version Tokens**: Treat token changes as API changes with semver
5. **Test Theme Combinations**: Verify all themes work with all components
6. **Automate Token Pipeline**: CI/CD for Figma-to-code synchronization
7. **Provide Migration Paths**: Deprecate tokens gradually with clear alternatives
8. **Use Fallback Values**: Always provide fallbacks for critical styles (`var(--token, fallback)`)
9. **Scope Component Tokens**: Keep component-specific tokens in component scope, not global `:root`
10. **Consistent Naming**: Use kebab-case, be descriptive, include scale info

## Common Issues

- **Token Sprawl**: Too many tokens without clear hierarchy
- **Inconsistent Naming**: Mixed conventions (camelCase vs kebab-case)
- **Missing Dark Mode**: Tokens that don't adapt to theme changes
- **Hardcoded Values**: Using raw values instead of tokens
- **Circular References**: Tokens referencing each other in loops
- **Platform Gaps**: Tokens missing for some platforms (web but not mobile)
- **FOUC on SSR**: Flash of unstyled content when theme not set before paint
- **Transition Flash**: Jarring visual change when switching themes

## Agentic Optimizations

| Context | Command |
|---------|---------|
| Find all CSS variables | `grep -r '--[a-z]' styles/ --include='*.css'` |
| Check token usage | `grep -r 'var(--color-primary)' src/ --include='*.css' --include='*.tsx'` |
| Find hardcoded colors | `grep -rn '#[0-9a-fA-F]\{3,8\}' src/ --include='*.css'` |
| List all token files | `find styles/tokens -name '*.css'` |
| Validate CSS syntax | `npx stylelint 'styles/**/*.css'` |

## References

- CSS Custom Properties: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascading_variables
- Design Tokens Format: https://design-tokens.github.io/community-group/format/
- Style Dictionary: https://styledictionary.com/
- Tailwind CSS: https://tailwindcss.com/docs/customizing-colors
- Radix UI Primitives: https://www.radix-ui.com/primitives
- Headless UI: https://headlessui.com/
- Class Variance Authority: https://cva.style/docs

---

> **Inspirado em:** synapse-ai-hub/skills/design-system-patterns, synapse-ai-hub/skills/design-tokens
