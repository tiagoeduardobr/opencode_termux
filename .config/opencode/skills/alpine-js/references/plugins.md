# Plugins — Persist, Intersect, Mask, Anchor, Focus, Morph, Collapse

All official plugins live under `@alpinejs/<plugin>` on npm and as
`https://cdn.jsdelivr.net/npm/@alpinejs/<plugin>@3.x.x/dist/cdn.min.js`
on the CDN. Each must be loaded **before** the Alpine core script (CDN)
or passed to `Alpine.plugin()` (bundler) before `Alpine.start()`.

```html
<!-- CDN: plugin first, core second, both with defer -->
<script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/persist@3.x.x/dist/cdn.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

```js
// bundler
import Alpine from 'alpinejs'
import persist from '@alpinejs/persist'
import intersect from '@alpinejs/intersect'
import mask from '@alpinejs/mask'
import anchor from '@alpinejs/anchor'
import focus from '@alpinejs/focus'
import morph from '@alpinejs/morph'
import collapse from '@alpinejs/collapse'
Alpine.plugin([persist, intersect, mask, anchor, focus, morph, collapse])
Alpine.start()
```

Decision matrix:

| Need | Plugin |
|---|---|
| Survive page reloads | Persist |
| React on scroll-into-view | Intersect |
| Format inputs as user types | Mask |
| Position popover near a trigger | Anchor |
| Trap focus / focus utilities | Focus |
| Diff DOM after server re-render | Morph |
| Animated height collapse | Collapse |

## Persist — `$persist`

```html
<div x-data="{ open: $persist(false) }">…</div>
```

- Reads from `localStorage` on init; writes on every change.
- Default key: `_x_<propName>`. Override:
  `$persist(false).as('sidebar-open')`.
- Custom storage: `$persist(0).using(sessionStorage)`.
- Works with arrays, objects, primitives.
- Inside `Alpine.data`:

```js
Alpine.data('sidebar', () => ({
  open: Alpine.$persist(false).as('sidebar-open'),
  toggle() { this.open = !this.open },
}))
```

Gotchas: storage is **shared across tabs** (use `sessionStorage` if you
want per-tab); SSR'd different initial value will be overwritten by
persisted value on hydrate (this is usually what you want).

## Intersect — `x-intersect`

```html
<div x-data="{ shown: false }"
     x-intersect="shown = true">
  <p x-show="shown" x-transition>visible!</p>
</div>
```

### Modifiers

| Modifier | Effect |
|---|---|
| `.once` | Fire only the first time the element enters. Combine with `x-intersect:enter`. |
| `.half` | Fire when at least 50% visible. |
| `.full` | Fire when 100% visible. |
| `.threshold.<0..100>` | Custom percentage threshold. |
| `.margin.<n>px` | rootMargin (e.g., `.margin.200px` to pre-trigger). |

### Enter / leave

```html
<div x-intersect:enter="playing = true"
     x-intersect:leave="playing = false">…</div>
```

Common uses: lazy-load images, animate-on-scroll, infinite scroll
sentinel (`x-intersect.once="loadMore()"`).

## Mask — `x-mask`

```html
<input x-mask="(999) 999-9999" placeholder="(555) 123-4567">
<input x-mask="99/99/9999"     placeholder="MM/DD/YYYY">
<input x-mask="aaa-999"        placeholder="abc-123">  <!-- a = letter -->
<input x-mask="*****"          placeholder="any">       <!-- * = any -->
```

### Dynamic mask

```html
<input x-mask:dynamic="$input.startsWith('1') ? '1 (999) 999-9999' : '(999) 999-9999'">
```

### Money

```html
<input x-mask:dynamic="$money($input)">
<input x-mask:dynamic="$money($input, '.')">          <!-- decimal char -->
<input x-mask:dynamic="$money($input, '.', ',')">    <!-- thousands sep -->
```

Wildcards: `9` = digit, `a` = letter, `*` = any. Other characters are
typed literally.

> **Assumption:** the mask wildcard set above matches the documented
> Mask plugin. Verify on https://alpinejs.dev/plugins/mask if you see
> alternative tokens in the wild.

## Anchor — `x-anchor`

Floating-UI-powered positioning for popovers, tooltips, dropdowns.

```html
<div x-data="{ open: false }">
  <button @click="open = !open" x-ref="button">Toggle</button>

  <div x-show="open"
       x-anchor="$refs.button"
       x-anchor.bottom-start.offset.4>
    Menu contents
  </div>
</div>
```

### Placement modifiers

`.top`, `.top-start`, `.top-end`, `.bottom`, `.bottom-start`, `.bottom-end`,
`.left`, `.left-start`, `.left-end`, `.right`, `.right-start`, `.right-end`.

### Other modifiers

| Modifier | Effect |
|---|---|
| `.offset.<n>` | Distance from anchor in px. |
| `.flip` | Auto-flip when there's no room (default on). |

Pair with `x-teleport="body"` to escape `overflow:hidden` parents.

> **Assumption:** modifier names above mirror the Anchor plugin's
> public docs at skill authoring time. Verify on
> https://alpinejs.dev/plugins/anchor.

## Focus — `x-trap` and `$focus`

### x-trap — focus trap for modals

```html
<div x-data="{ open: false }">
  <button @click="open = true">Open modal</button>
  <div x-show="open" x-trap.noscroll="open" @keyup.escape="open = false">
    <input>
    <button @click="open = false">Close</button>
  </div>
</div>
```

- `x-trap="open"` traps focus while `open` is truthy; restores previous
  focus on close.
- `.noscroll` disables body scroll while trapped.
- `.inert` sets `inert` on siblings (a11y).
- `.noautofocus` skips auto-focusing the first focusable on open.

### $focus — programmatic focus utilities

```js
$focus.focus(el)                   // focus a node
$focus.focusable(el)               // → list of focusable descendants
$focus.focusable(el).first().focus()
$focus.focusable(el).last().focus()
$focus.focused()                   // → currently focused element
$focus.within(scope).focus(el)     // limit a focus call to a scope
```

> **Assumption:** the `$focus` API surface matches the public Focus
> plugin docs. Verify on https://alpinejs.dev/plugins/focus.

## Morph — `Alpine.morph(el, newHtml)`

```js
import morph from '@alpinejs/morph'
Alpine.plugin(morph)

// later — replace #app's contents with new server HTML, preserving
// reactive Alpine state in elements that survive the diff:
Alpine.morph(document.getElementById('app'), newHtml, {
  key(el) { return el.getAttribute('id') },   // optional matcher
  updating(from, to, childrenOnly, skip) {},  // optional hook
  updated(from, to) {},
})
```

- This is the same diff Livewire v3 uses internally — Morph plugin
  just exposes it for non-Livewire callers (Turbo, htmx, custom
  fetch-and-replace flows).
- Preserves Alpine scope on matched nodes (input values, open flags).
- Pair with a `key` matcher when you have lists with stable ids.

## Collapse — `x-collapse`

```html
<div x-data="{ open: false }">
  <button @click="open = !open">Toggle</button>
  <div x-show="open" x-collapse>
    Long content that should slide open / closed.
  </div>
</div>
```

- Animates `height: 0 ↔ height: auto` smoothly (CSS can't do this
  natively for `auto`).
- Pair with `x-show`. (Don't use with `x-if`.)
- Modifiers: `.duration.500ms`, `.min.32px` (preserve a min height,
  e.g., a peek of content even when "collapsed").

> **Assumption:** modifier names match the documented Collapse plugin.
> Verify on https://alpinejs.dev/plugins/collapse.

## Choosing a plugin (heuristics)

- **Reach for Persist** the moment you'd otherwise touch
  `localStorage` plumbing — even for one boolean, it's worth it.
- **Reach for Intersect** instead of hand-rolling
  `IntersectionObserver` for any in-Alpine reveal/scroll work. The
  modifier-driven config is much cleaner.
- **Reach for Mask** before regex-on-keyup. Especially for international
  phone inputs and currencies (`$money`).
- **Reach for Anchor** before pulling in Floating UI directly. It's
  Floating UI under the hood with an Alpine-friendly directive.
- **Reach for Focus** before any handcrafted focus trap — the a11y
  edge cases (Shift+Tab off the first element, scroll lock) are
  battle-tested.
- **Morph** is mostly invisible if you're on Livewire — Livewire uses it
  internally. Reach for it directly if you're on a non-Livewire stack
  doing fetch-and-replace.
- **Collapse** is the answer to "why doesn't `x-transition` animate
  height?" Use it for accordions and "show more" panels.
