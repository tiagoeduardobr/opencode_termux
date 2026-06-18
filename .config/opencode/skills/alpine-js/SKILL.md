---
name: alpine-js
description: Use this skill ANY time the user is wiring small client-side reactivity into server-rendered HTML (Blade, Livewire, Rails, Django, plain HTML) and reaching for Alpine.js. Trigger on "Alpine directive", "x-data", "x-show", "x-if", "x-for", "x-bind", "x-on", "x-model", "x-transition", "x-cloak", "x-init", "x-ref", "x-effect", "x-teleport", "x-modelable", "$store", "$dispatch", "$watch", "$nextTick", "$refs", "$persist", "Alpine.data", "Alpine.store", "Alpine.bind", "Alpine.magic", "Persist/Intersect/Mask/Anchor/Focus/Morph/Collapse plugin", "wire:model + Alpine", "@entangle", "$wire", "Livewire + Alpine", "small reactive component", "client-side state without React", "sprinkle of JavaScript", or "why is my x-cloak flashing". Even when Alpine is not named, treat "add a dropdown / modal / accordion / tabs / toggle to my Blade view without React/Vue" as an Alpine trigger when the project already uses Tailwind, Livewire, Hotwire, htmx, or vanilla server rendering. Covers the full directive surface, every magic helper, the four globals, all official plugins, and Livewire interop ordering / hydration timing.
---

# Alpine.js — Reactive Sprinkles for Server-Rendered HTML

Use this skill whenever the user is wiring small interactive behaviors into
server-rendered HTML (Blade, Livewire, Rails, Django, plain HTML) without
spinning up a React/Vue/Svelte SPA. Alpine is **reactivity bound to the
existing DOM** — no virtual DOM, no build step required, and scope is
per-element via `x-data`.

## Mental model

```
Alpine = Vue's reactivity (Proxy-based) + Vue-style template directives
         applied directly to your existing HTML.

No virtual DOM. Alpine walks the DOM, sees x-* attributes, wires reactive
effects, and mutates real nodes in place.

Scope is rooted at every element with x-data. A nested x-data creates a
CHILD scope that inherits read-access to its parent but writes shadow.

Directives are evaluated as plain JavaScript expressions (not a templating
DSL) — `this` inside x-data refers to the component, but inside directives
you access properties directly (no `this.`).
```

```
<div x-data="counter">                  ← component scope
   <button @click="inc()">+</button>    ← directive on a child element
   <span x-text="count"></span>         ← reactive text binding
</div>
```

When `count` changes, only the bindings that read `count` re-run — not the
whole subtree.

## Install

**CDN (zero build):**

```html
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

`defer` is required so the DOM is ready when Alpine boots. Alpine
auto-initializes on `DOMContentLoaded`.

**npm (bundler):**

```js
import Alpine from 'alpinejs'
window.Alpine = Alpine
Alpine.start()
```

Register plugins (`Alpine.plugin(...)`) and named components
(`Alpine.data(...)`) **before** `Alpine.start()`.

## When to use this skill (decision flow)

| User intent | Reach for |
|---|---|
| Toggle a dropdown / modal / accordion | `x-data`, `x-show`, `@click.outside` → see `references/directives.md` |
| Two-way bind a form input | `x-model` (+ `.number`, `.debounce`) → see `references/directives.md` |
| Conditionally render (mount/unmount) a block | `x-if` on `<template>` → see `references/directives.md` |
| Loop over a list | `x-for` on `<template>` with `:key` → see `references/directives.md` |
| Animate enter/leave | `x-transition` → see `references/directives.md` |
| Render a tooltip/popover into `<body>` | `x-teleport` + Anchor plugin → see `references/directives.md`, `references/plugins.md` |
| Persist a UI flag across page loads | `$persist` (Persist plugin) → see `references/plugins.md` |
| Lazy-load on scroll into view | `x-intersect` (Intersect plugin) → see `references/plugins.md` |
| Format a phone/credit-card input | `x-mask` (Mask plugin) → see `references/plugins.md` |
| Position a popover next to its trigger | `x-anchor` (Anchor plugin) → see `references/plugins.md` |
| Trap focus inside a modal | `x-trap` (Focus plugin) → see `references/plugins.md` |
| DOM-diff after server re-render (Livewire/Turbo) | `Alpine.morph()` (Morph plugin) → see `references/plugins.md` |
| Smooth height transition for collapse | `x-collapse` (Collapse plugin) → see `references/plugins.md` |
| Share state across multiple components | `Alpine.store()` + `$store` → see `references/magics.md`, `references/globals.md` |
| Custom event between scopes | `$dispatch('x', detail)` + `@x.window` → see `references/magics.md` |
| Watch a property change | `$watch('foo', val => ...)` → see `references/magics.md` |
| Reusable named component logic | `Alpine.data('name', () => ({...}))` → see `references/globals.md` |
| Reusable bag of bindings | `Alpine.bind('name', () => ({...}))` → see `references/globals.md` |
| Mix Alpine inside a Livewire component | wire:* before x-* on the same element, use `$wire` and `@entangle` → see `references/livewire-interop.md` |

## Core directives quick reference

Full deep dive in `references/directives.md`. The 18 you must know:

```
x-data        → declare component scope (the root)
x-init        → run JS once after init (fires before child renders)
x-show        → toggle display:none reactively (DOM stays mounted)
x-if          → mount/unmount a <template> block reactively
x-for         → loop a <template> block; needs :key for non-trivial lists
x-bind / :    → reactively set any attribute (incl. :class object syntax)
x-on   / @    → event listener with modifiers (.prevent, .stop, .outside,
                .window, .document, .self, .once, .passive, .capture,
                .debounce.500ms, .throttle.250ms, key mods .enter .esc .ctrl)
x-model       → two-way bind to input/select/textarea/checkbox/radio
                modifiers: .number .boolean .debounce.500ms .lazy .fill
x-text        → set element textContent reactively
x-html        → set innerHTML reactively (XSS — only with trusted input)
x-ref         → name a DOM node so you can grab it via $refs.name
x-cloak       → hide element until Alpine boots (anti-FOUC)
x-ignore      → tell Alpine to NOT process this subtree
x-effect      → run a JS expression whenever its reactive deps change
x-transition  → enter/leave animations (six sub-attrs or single helper)
x-teleport    → move this element to another part of the DOM at boot
x-id          → declare unique id scope; pair with $id for a11y wiring
x-modelable   → expose an x-data property as a target for the parent's x-model
```

### x-cloak — set this CSS once globally, always

Without it you get a flash of un-Alpine-ified HTML on first paint:

```css
[x-cloak] { display: none !important; }
```

Then put `x-cloak` on any root that contains directives that would
otherwise show pre-init content (e.g., a dropdown that defaults to open
because `x-show="open"` hasn't evaluated yet).

### x-show vs x-if — the most common mistake

| | `x-show` | `x-if` |
|---|---|---|
| Toggles | `display: none` style | DOM mount/unmount |
| Element required | any | **must** be `<template>` |
| State retained inside? | **yes** (inputs keep value) | no (rebuilt on remount) |
| Cost when hidden | minimal (still in DOM) | zero (not in DOM) |
| Use for | toggles, dropdowns, tabs you re-show often | rarely-used heavy blocks, conditional forms |

### x-for must wrap a `<template>` and (almost always) needs `:key`

```html
<template x-for="item in items" :key="item.id">
  <li x-text="item.name"></li>
</template>
```

Without `:key` Alpine reorders by index — fine for static lists, broken
for lists that get inserted/removed/reordered (e.g., to-do items).

## Magic helpers quick reference

Full deep dive in `references/magics.md`.

```
$el        → the current DOM element
$refs      → object of x-ref names → DOM nodes (within nearest x-data scope)
$store     → global stores registered via Alpine.store()
$watch     → observe a scope property: $watch('open', v => ...)
$dispatch  → fire a custom DOM event: $dispatch('saved', { id })
$nextTick  → run callback after Alpine has flushed pending DOM updates
$root      → the nearest x-data root element
$id        → generate a stable unique id (paired with x-id) for a11y
$data      → the current x-data scope object (rarely used directly)
$persist   → (Persist plugin) reactive value backed by localStorage
$focus     → (Focus plugin) imperative focus helper
```

## Globals quick reference

Full deep dive in `references/globals.md`.

```
Alpine.data('counter', () => ({          // named, reusable component
  count: 0,
  init() { /* lifecycle */ },
  inc() { this.count++ }
}))
// then: <div x-data="counter">…</div>

Alpine.store('cart', { items: [], add(i){ this.items.push(i) } })
// then: <span x-text="$store.cart.items.length"></span>

Alpine.bind('Tooltip', () => ({          // reusable bundle of attributes
  ['x-data']() { return { show: false } },
  ['@mouseenter']() { this.show = true },
  ['@mouseleave']() { this.show = false },
  ['x-show']() { return this.show },
}))
// then: <div x-bind="Tooltip">…</div>

Alpine.magic('clipboard', () => subject => navigator.clipboard.writeText(subject))
// then: <button @click="$clipboard('hello')">Copy</button>
```

All four must be called **before** `Alpine.start()` (or before the
`alpine:init` event in CDN mode):

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('counter', () => ({ count: 0, inc() { this.count++ } }))
  Alpine.store('cart', { items: [] })
})
</script>
```

## Plugins quick survey

Full deep dive in `references/plugins.md`.

| Plugin | Bring in when… | Headline API |
|---|---|---|
| **Persist** | A UI flag must survive page reloads (sidebar open, theme). | `count: $persist(0)` (auto-syncs to `localStorage`). |
| **Intersect** | Lazy-load, animate-on-scroll, infinite scroll. | `x-intersect="loaded = true"`, `.once`, `.half`, `.full`, `.margin`. |
| **Mask** | Format inputs as the user types (phone, card, date). | `x-mask="(999) 999-9999"`, dynamic `x-mask:dynamic`. |
| **Anchor** | Position a popover/tooltip relative to a trigger (Floating UI under the hood). | `x-anchor="$refs.button"`, `.bottom-start`, `.offset.10`. |
| **Focus** | Modals, command palettes — trap focus, restore on close. | `x-trap="open"`, `.noscroll`, `.inert`; `$focus.focus(el)`. |
| **Morph** | Server-rendered HTML re-arrives (Livewire/Turbo) and you want to diff into existing DOM. | `Alpine.morph(el, newHtml)` — preserves Alpine state. |
| **Collapse** | Smooth height transition for accordion. | `x-collapse` (paired with `x-show`); `.duration.500ms`. |

## Alpine + Livewire interop (most common pairing)

Full deep dive in `references/livewire-interop.md`. Headlines:

1. **Order matters.** When stacking `wire:*` and `x-*` on the same
   element, put **`wire:*` first**, then `x-*`. Livewire's morphdom
   needs to see its directives before Alpine's do their thing.
2. **`$wire`** is Alpine-side magic that talks to the underlying
   Livewire component — `$wire.set('foo', 1)`, `$wire.$call('save')`,
   `$wire.foo` (reactive read).
3. **`@entangle`** wires a Livewire property and an Alpine property
   together (both directions). Use `@entangle('open').live` for
   real-time round-trip, `@entangle('open')` for deferred.
4. **Persistent Alpine scope.** Alpine state inside a Livewire
   component is preserved across re-renders (Livewire morphs the DOM,
   not full-replace). Don't fight that — initialize once via
   `Alpine.data()` rather than re-running heavy `init()`.
5. **Hydration timing.** Alpine boots first; Livewire then morphs in
   server-rendered HTML; Alpine re-binds to morphed nodes
   automatically (this is why Morph plugin behavior matches what
   Livewire does internally).

## Common pitfalls

1. **Multiple `x-data` create child scopes.** Putting `x-data` on a
   nested element creates a NEW scope; the parent's `x-data` is not
   merged. To extend, use `x-data="{ ...$data, foo: 1 }"` deliberately.
2. **`x-show` does NOT unmount.** Heavy components (videos, iframes,
   third-party widgets) are still alive when hidden. Use `x-if` if you
   need the DOM gone.
3. **`x-cloak` flash.** Forgot the global CSS rule
   `[x-cloak]{display:none!important}`? You will see a flash of
   un-evaluated state. Always ship that rule.
4. **`x-init` runs once; `x-effect` runs reactively.** Use `x-init` for
   imperative setup. Use `x-effect` (or `init() { this.$watch(...) }`)
   for reactive reaction.
5. **`:class` object syntax vs string.** `:class="{ 'is-open': open }"`
   merges with existing static `class="…"`. `:class="open ? 'a' : 'b'"`
   replaces the bound class only — both static and string-bound classes
   coexist. Don't mix the two patterns on the same attribute.
6. **Key modifiers are `.kebab-case`.** `@keyup.enter`, `@keyup.esc`,
   `@keyup.arrow-up`, `@keyup.ctrl.k`. Stacking modifiers ANDs them
   (`.ctrl.k` = ctrl AND k).
7. **`$el` scope leak.** Inside an `x-on` handler `$el` is the element
   the listener is attached to, NOT the `x-data` root. Use `$root` or
   `$refs.something` if you need the component root.
8. **`x-for` on the wrong element.** `x-for` MUST be on a `<template>`
   tag with exactly one root child element inside.
9. **`$refs` empty during `x-init`.** `x-init` may run before child
   `x-ref` registrations. Wrap in `$nextTick(() => …)` if you need
   refs in init.
10. **Reactivity on plain getters/setters needs `get`/`set`.** Computed
    properties must be JS getters: `get total() { return this.qty *
    this.price }` — not methods, or `x-text` won't re-evaluate when
    deps change.
11. **Ordering with Livewire.** Wrong: `<input x-model="q"
    wire:model="q">`. Right: `<input wire:model="q" x-model="q">` —
    or just use one (prefer `wire:model.live` if real-time, plus
    `@entangle` for shared state).
12. **Don't put a build step in front of `x-data` JS.** The expression
    in `x-data="…"` is evaluated at runtime as a JS expression — TS,
    Babel, and bundlers don't see it. Move complex logic into a
    registered `Alpine.data('name', () => ({...}))` instead.

## Workflow checklist for shipping an Alpine component

1. Decide scope: single `x-data` per component root.
2. Move logic > 5 lines into `Alpine.data('name', () => ({...}))`.
3. Use `:` and `@` shorthand (not `x-bind:` / `x-on:`) for readability.
4. Always ship the `[x-cloak]{display:none!important}` CSS rule.
5. Pick `x-show` (cheap toggle, state retained) vs `x-if` (mount/unmount).
6. `x-for` with `:key` for any list that mutates.
7. For cross-component state, use `Alpine.store()`; for cross-component
   events, use `$dispatch` + `@event.window`.
8. Reach for plugins instead of hand-rolling: `$persist` over `localStorage`
   plumbing, `x-intersect` over `IntersectionObserver`, `x-trap` over
   focus-trap libraries, `x-anchor` over Floating UI calls, `x-mask`
   over input regex hacks, `x-collapse` over manual height transitions.
9. Inside Livewire: `wire:*` first, then `x-*`; use `$wire` / `@entangle`
   to bridge state.
10. Test with the browser console: `Alpine.raw($0._x_dataStack[0])` on a
    selected element shows current scope.

## References

- `references/directives.md` — every directive, modifiers, gotchas, idiomatic
  examples.
- `references/magics.md` — every `$magic`, when to reach for it,
  cross-scope patterns.
- `references/globals.md` — `Alpine.data` / `Alpine.store` / `Alpine.bind`
  / `Alpine.magic`, lifecycle order.
- `references/plugins.md` — Persist, Intersect, Mask, Anchor, Focus, Morph,
  Collapse — when to use each, options matrix.
- `references/livewire-interop.md` — wire/Alpine ordering, `$wire`,
  `@entangle`, hydration timing, morph behavior.

> **Assumption notice.** This skill targets Alpine.js v3.x. v2 differs
> notably (e.g. `x-spread` instead of `Alpine.bind`, no `Alpine.data`
> registration, different transition syntax). Plugin option names below
> reflect each plugin's documented surface at skill authoring time —
> if a name looks unfamiliar, verify on https://alpinejs.dev/plugins/<plugin>
> before relying on it. Livewire interop notes assume Livewire v3.
