# Globals — Alpine.data / Alpine.store / Alpine.bind / Alpine.magic

Alpine exposes four registration globals. Use them to extract logic out
of inline `x-data` once it grows past a few lines.

All four must be called **before** Alpine boots. In CDN mode that means
inside an `alpine:init` listener; in bundler mode just before
`Alpine.start()`.

```html
<script>
document.addEventListener('alpine:init', () => {
  // register here
})
</script>
<script defer src="…/alpinejs@3/dist/cdn.min.js"></script>
```

```js
// bundler
import Alpine from 'alpinejs'
import persist from '@alpinejs/persist'
Alpine.plugin(persist)
Alpine.data('counter', () => ({ count: 0, inc() { this.count++ } }))
Alpine.store('cart', { items: [], add(i){ this.items.push(i) } })
window.Alpine = Alpine
Alpine.start()
```

## Alpine.data(name, factory) — named, reusable component

```js
Alpine.data('dropdown', (initialOpen = false) => ({
  open: initialOpen,
  toggle() { this.open = !this.open },
  close() { this.open = false },
  init() {
    // optional lifecycle
    this.$watch('open', v => v && this.$nextTick(() => this.$refs.menu?.focus()))
  },
  destroy() {
    // cleanup when element leaves DOM
  },
}))
```

Usage:

```html
<div x-data="dropdown">…</div>
<div x-data="dropdown(true)">…</div>          <!-- pass arg -->
<div x-data="dropdown" x-init="open = true">…</div>
```

### Why this over inline x-data

- Real JS (linter, formatter, types).
- Reusable.
- Multiple lifecycle hooks (`init`, `destroy`).
- Works with bundlers (TS, tree-shaking).

### Composition ("mixins")

```js
const togglable = (initial = false) => ({
  open: initial,
  toggle() { this.open = !this.open },
})

Alpine.data('dropdown', () => ({
  ...togglable(false),
  selected: null,
  pick(item) { this.selected = item; this.open = false },
}))
```

Gotcha: spreading an object **does not** carry over `init()` across
mixins. If two mixins both define `init`, the later one wins; combine
them manually.

## Alpine.store(name, value) — global state

```js
Alpine.store('darkMode', {
  on: false,
  init() {                                      // optional: runs on boot
    this.on = matchMedia('(prefers-color-scheme: dark)').matches
  },
  toggle() { this.on = !this.on },
})
```

Access from any component:

```html
<button @click="$store.darkMode.toggle()"
        x-text="$store.darkMode.on ? 'Light' : 'Dark'"></button>
```

- Stores live for the lifetime of the page.
- Reactive end-to-end — any binding reading `$store.darkMode.on`
  re-evaluates on change.
- A store **value** can be a primitive too: `Alpine.store('count', 0)`
  → access as `$store.count`. Mutation requires `Alpine.store('count', 5)`
  in that case (less ergonomic; prefer wrapping in an object).

### Store + $persist

```js
import persist from '@alpinejs/persist'
Alpine.plugin(persist)
Alpine.store('darkMode', {
  on: Alpine.$persist(false).as('darkMode'),    // typed via global helper
  toggle() { this.on = !this.on },
})
```

> **Assumption:** `Alpine.$persist` is the JS-side accessor for the
> persist helper outside templates. Verify name on
> https://alpinejs.dev/plugins/persist if your version differs.

## Alpine.bind(name, bindings) — reusable bag of attributes

```js
Alpine.bind('Tooltip', () => ({
  ['x-data']() { return { show: false } },
  ['x-show']() { return this.show },
  ['@mouseenter']() { this.show = true },
  ['@mouseleave']() { this.show = false },
  ['x-cloak']: '',
  ['role']: 'tooltip',
}))
```

Usage:

```html
<div x-bind="Tooltip">tooltip body</div>
```

- Replaces v2's `x-spread`.
- Each key is a normal attribute name (`x-show`, `:class`, `@click`,
  `aria-label`).
- Values can be functions (recomputed per element) or plain strings.
- Useful for design-system primitives — share a `Modal` or `Tabs`
  attribute bundle across many usages.

## Alpine.magic(name, factory) — your own $magic

```js
Alpine.magic('clipboard', () => subject => navigator.clipboard.writeText(subject))
```

Usage:

```html
<button @click="$clipboard('hello')">Copy</button>
```

- Factory receives `(el)` so you can scope to the element if you want.
- Naming: `$camelCase`, no leading dollar in the registered name.
- Common community ones: `$clipboard`, `$truncate`, `$tooltip`,
  `$debug`.

## Alpine.directive(name, callback) — your own x-foo (advanced)

```js
Alpine.directive('uppercase', (el) => { el.textContent = el.textContent.toUpperCase() })
```

The full directive callback signature is
`(el, { value, modifiers, expression }, { Alpine, effect, cleanup })`.

> **Assumption:** Custom directive registration is documented as a
> first-class API; treat advanced parameters (effect, cleanup, evaluator)
> as plugin-author territory and verify on
> https://alpinejs.dev/advanced/extending before relying on them.

## Lifecycle events

```js
document.addEventListener('alpine:init', () => { /* register */ })
document.addEventListener('alpine:initialized', () => { /* DOM has been walked */ })
```

You can also dispatch `Alpine.start()` manually (bundler mode) — Alpine
then walks the DOM and binds.

## Order of operations on boot

1. CDN script loads (`defer`) → DOM is ready.
2. `alpine:init` fires → register `data`, `store`, `bind`, `magic`,
   `plugin`, `directive`.
3. Alpine walks the DOM, finds every `x-data`, builds reactive scopes,
   evaluates `x-init`, then walks children binding the rest.
4. `alpine:initialized` fires.
5. From here on, mutations to reactive state schedule directive re-runs.

Gotcha: registering AFTER `Alpine.start()` (bundler) or after the
`alpine:init` event (CDN) means existing elements **won't pick up the
new registration** without manual rebind. Register early.
