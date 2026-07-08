---
name: code-architecture-tailwind-v4-best-practices
description: "Guides Tailwind CSS v4 patterns for buttons and components. Use this skill when creating components with variants, choosing between CVA/tailwind-variants, or configuring Tailwind v4's CSS-first approach."
---

# Code Architecture Tailwind v4 Best Practices

Guidance for building maintainable, scalable UI components with Tailwind CSS v4's CSS-first architecture and variant libraries (CVA, tailwind-variants).

## When to Use This Skill

| Use this skill when... | Use another skill instead when... |
|------------------------|-----------------------------------|
| Creating components with size/color/variant prop systems | General layout or responsive design |
| Choosing between CVA and tailwind-variants | Design token creation (use design-system) |
| Configuring Tailwind v4 CSS-first approach | Framework-specific component patterns |
| Building button, input, or card component families | Accessibility auditing |
| Refactoring variant logic from config to CSS | — |
| Optimizing class merging and deduplication | — |

## Core Concepts

### Tailwind CSS v4: CSS-First Configuration

Tailwind v4 replaces `tailwind.config.js` with CSS-native configuration using `@theme` and `@import`.

```css
/* app.css */
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.55 0.2 260);
  --color-primary-foreground: oklch(0.98 0.01 260);
  --color-secondary: oklch(0.7 0.15 180);
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --breakpoint-xs: 20rem;
}
```

**Key changes from v3:**
- No more `tailwind.config.js` — configure directly in CSS
- `@theme` block defines design tokens as CSS custom properties
- `@import "tailwindcss"` replaces `@tailwind base/components/utilities`
- Built-in CSS-native dark mode via `@media (prefers-color-scheme: dark)`
- No JIT engine — styles are generated on-demand by default

### Variant Libraries: CVA vs tailwind-variants

#### Class Variance Authority (CVA)

Best for: **Simple to medium variant systems**, maximum ecosystem compatibility.

```typescript
import { cva, type VariantProps } from "class-variance-authority";

const buttonVariants = cva(
  // Base classes
  "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        primary: "bg-primary text-primary-foreground hover:bg-primary/90",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        sm: "h-9 px-3 text-sm",
        md: "h-10 px-4 text-sm",
        lg: "h-11 px-8 text-base",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  }
);

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean;
  };

function Button({ className, variant, size, ...props }: ButtonProps) {
  return (
    <button
      className={buttonVariants({ variant, size, className })}
      {...props}
    />
  );
}
```

#### tailwind-variants

Best for: **Complex variant systems**, responsive variants, compound variants, TV-specific features.

```typescript
import { tv, type VariantProps } from "tailwind-variants";

const button = tv({
  base: "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  variants: {
    variant: {
      primary: "bg-primary text-primary-foreground hover:bg-primary/90",
      secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
      outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
      ghost: "hover:bg-accent hover:text-accent-foreground",
      link: "text-primary underline-offset-4 hover:underline",
    },
    size: {
      sm: "h-9 px-3 text-sm",
      md: "h-10 px-4 text-sm",
      lg: "h-11 px-8 text-base",
      icon: "h-10 w-10",
    },
    isDisabled: {
      true: "pointer-events-none opacity-50",
    },
  },
  compoundVariants: [
    {
      variant: "primary",
      size: "lg",
      class: "text-lg font-semibold",
    },
  ],
  defaultVariants: {
    variant: "primary",
    size: "md",
  },
});

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> &
  VariantProps<typeof button> & {
    asChild?: boolean;
  };

function Button({ className, variant, size, isDisabled, ...props }: ButtonProps) {
  return (
    <button
      className={button({ variant, size, isDisabled, className })}
      disabled={isDisabled}
      {...props}
    />
  );
}
```

### Decision Matrix: CVA vs tailwind-variants

| Criteria | CVA | tailwind-variants |
|----------|-----|-------------------|
| Bundle size | ~1KB | ~2KB |
| Learning curve | Low | Medium |
| Compound variants | Basic | Advanced |
| Responsive variants | Manual | Built-in (`slots`, `responsiveVariants`) |
| Slots (multi-element) | No | Yes |
| TypeScript inference | Good | Excellent |
| Ecosystem adoption | Higher | Growing |
| Tailwind v4 support | Yes | Yes |

**Recommendation:** Start with CVA for simple components. Switch to tailwind-variants when you need compound variants, responsive variants, or slot-based multi-element components.

## Component Architecture Patterns

### 1. Polymorphic Components (as prop)

```typescript
import { type ComponentPropsWithRef, type ElementType } from "react";

type PolymorphicProps<T extends ElementType> = {
  as?: T;
} & ComponentPropsWithRef<T>;

function Card<T extends ElementType = "div">({
  as,
  className,
  ...props
}: PolymorphicProps<T>) {
  const Component = as || "div";
  return (
    <Component
      className={cn("rounded-lg border bg-card p-6 shadow-sm", className)}
      {...props}
    />
  );
}

// Usage
<Card as="article" className="..." />
<Card as="section" className="..." />
```

### 2. Compound Components

```typescript
// Card.tsx
const CardContext = React.createContext<{ variant?: string }>({});

function Card({ children, variant, className, ...props }) {
  return (
    <CardContext.Provider value={{ variant }}>
      <div className={cn("rounded-lg border bg-card shadow-sm", className)} {...props}>
        {children}
      </div>
    </CardContext.Provider>
  );
}

function CardHeader({ className, ...props }) {
  return <div className={cn("flex flex-col space-y-1.5 p-6", className)} {...props} />;
}

function CardTitle({ className, ...props }) {
  return <h3 className={cn("text-2xl font-semibold leading-none tracking-tight", className)} {...props} />;
}

// Usage
<Card variant="elevated">
  <CardHeader>
    <CardTitle>Title</CardTitle>
  </CardHeader>
</Card>
```

### 3. Slot Pattern (tailwind-variants)

```typescript
const card = tv({
  slots: {
    base: "rounded-lg border bg-card shadow-sm",
    header: "flex flex-col space-y-1.5 p-6",
    title: "text-2xl font-semibold leading-none tracking-tight",
    content: "p-6 pt-0",
    footer: "flex items-center p-6 pt-0",
  },
  variants: {
    variant: {
      elevated: {
        base: "shadow-md",
      },
      outlined: {
        base: "border-2",
      },
    },
  },
});

const { base, header, title, content, footer } = card({ variant });

function Card({ children, className, variant }) {
  return <div className={base({ className })}>{children}</div>;
}

function CardHeader({ children, className }) {
  return <div className={header({ className })}>{children}</div>;
}
```

## Best Practices

### 1. Always Use `cn()` Utility

Merge Tailwind classes without conflicts using `clsx` + `tailwind-merge`:

```typescript
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### 2. Extract Variant Config to Separate Files

```typescript
// components/ui/button-variants.ts
import { cva } from "class-variance-authority";

export const buttonVariants = cva(/* ... */);

// components/ui/button.tsx
import { buttonVariants } from "./button-variants";
```

### 3. Use Semantic Token Names

```css
@theme {
  /* ✅ Good: Semantic names */
  --color-destructive: oklch(0.55 0.2 25);
  --color-destructive-foreground: oklch(0.98 0.01 25);

  /* ❌ Avoid: Raw color values in components */
  /* red-500, red-600 — use semantic tokens instead */
}
```

### 4. Component API Design

```typescript
// ✅ Good: Clear, predictable API
<Button variant="primary" size="lg" disabled />

// ❌ Avoid: Boolean explosion
<Button primary large disabled />

// ❌ Avoid: String unions that are hard to discover
<Button style="primary-large" />
```

### 5. Class Composition Order

Follow Tailwind's recommended ordering:

1. Layout (display, position, overflow)
2. Flexbox/Grid
3. Spacing (margin, padding)
4. Sizing (width, height)
5. Typography
6. Visual (background, border, shadow)
7. Interactive (focus, hover states)

```typescript
// Good order
className="flex items-center gap-2 px-4 py-2 w-full text-sm font-medium bg-primary text-primary-foreground rounded-md hover:bg-primary/90 focus-visible:ring-2"
```

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Class name conflicts | Always use `cn()` utility |
| Variant prop drilling | Use compound components or context |
| Massive variant files | Extract to separate `*-variants.ts` files |
| Inconsistent spacing | Define spacing tokens in `@theme` |
| Missing responsive variants | Use tailwind-variants' `responsiveVariants` |
| Hardcoded colors | Use semantic CSS custom properties |

## Quick Reference

### Install Dependencies

```bash
# CVA approach
npm install class-variance-authority clsx tailwind-merge

# tailwind-variants approach
npm install tailwind-variants clsx tailwind-merge
```

### Tailwind v4 Setup

```css
/* app.css */
@import "tailwindcss";

@theme {
  /* Your design tokens */
}
```

### Minimal Button Component

```typescript
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        primary: "bg-primary text-primary-foreground hover:bg-primary/90",
        outline: "border border-input bg-background hover:bg-accent",
      },
      size: {
        sm: "h-9 px-3",
        md: "h-10 px-4",
        lg: "h-11 px-8",
      },
    },
    defaultVariants: { variant: "primary", size: "md" },
  }
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export function Button({ className, variant, size, ...props }: ButtonProps) {
  return (
    <button className={cn(buttonVariants({ variant, size, className }))} {...props} />
  );
}
```

## References

- Tailwind CSS v4 Docs: https://tailwindcss.com/docs
- Class Variance Authority: https://cva.style/docs
- tailwind-variants: https://www.tailwind-variants.com/
- tailwind-merge: https://github.com/dcastil/tailwind-merge
- Radix UI: https://www.radix-ui.com/primitives
- shadcn/ui (component patterns): https://ui.shadcn.com

---

> **Fonte original:** flpbalada/my-opencode-config
