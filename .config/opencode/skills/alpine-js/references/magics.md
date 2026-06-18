# Magic helpers — full reference

Magic helpers are values prefixed with `$` that Alpine injects into every
directive expression. They are scope-aware (resolve to the nearest
`x-data` boundary unless noted).

## $el — current element

```html
<button @click="$el.classList.toggle('busy')">Click me</button>
```

- Inside an event handler, `$el` is the element with the listener
  (NOT the `x-data` root).
- Use `$root` for the component root.

## $refs — named DOM nodes

```html
<div x-data="{ focus() { this.$refs.input.focus() } }">
  <input x-ref="input">
  <button @click="focus">Focus</button>
</div>
```

- Resolves names from `x-ref` within the nearest `x-data`.
- Empty during `x-init`; wrap in `$nextTick` to use them then.

## $store — global state

```html
<button @click="$store.cart.add(item)">
  Cart: <span x-text="$store.cart.items.length"></span>
</button>
```

- `$store` is the same object Alpine.store registered
  (see `references/globals.md`).
- Reactive — anything binding `$store.x.y` re-runs when `y` changes.
- Stores can have an `init()` method that fires once when Alpine boots.

## $watch — observe a property

```js
// inside Alpine.data() init():
init() {
  this.$watch('open', (value, old) => {
    console.log('open changed', old, '->', value)
  })
  this.$watch('user.email', v => …)   // dotted path supported
}
```

- Triggers on **value change**, not on initial set.
- Receives `(newValue, oldValue)`.
- Use `x-effect` for inline DOM-side equivalents.

## $dispatch — fire a custom DOM event

```html
<button @click="$dispatch('saved', { id: 42 })">Save</button>

<!-- elsewhere -->
<div @saved.window="banner = `saved #${$event.detail.id}`"></div>
```

- Wraps `dispatchEvent(new CustomEvent(name, { detail, bubbles: true }))`.
- Bubbles by default, so a parent listener (or `@event.window` anywhere)
  catches it.
- The dispatched payload is in `$event.detail` on the listener side.

### Cross-component patterns

- **Parent ↔ child:** child dispatches; parent listens on the wrapping
  element.
- **Across the page:** dispatch normally; listen with `.window`.
- **From outside Alpine:** plain `el.dispatchEvent(new CustomEvent('x', { detail }))`
  is caught by `@x` listeners just fine.

## $nextTick — after DOM flush

```html
<button @click="open = true; $nextTick(() => $refs.input.focus())">Open</button>
```

- Runs the callback after Alpine has applied pending reactive updates.
- Common use: focus an input that just became visible via `x-show`
  flipping.
- Returns a Promise too: `await $nextTick()`.

## $root — the x-data root

```html
<button @click="$root.classList.add('opened')">…</button>
```

- The element that owns the nearest `x-data`.

## $id — unique id paired with x-id

```html
<div x-data x-id="['accordion-item']">
  <button :aria-controls="$id('accordion-item')" :aria-expanded="open">…</button>
  <div :id="$id('accordion-item')" x-show="open">…</div>
</div>
```

- Within an `x-id` scope, repeated calls with the same name return the
  same generated id; outside that scope they're distinct.
- Pass an integer to differentiate within a loop:
  `$id('row', index)`.

## $data — current scope object

```html
<pre x-text="JSON.stringify($data, null, 2)"></pre>
```

- Rarely needed; useful for debugging.

## $persist — Persist plugin

```html
<div x-data="{ darkMode: $persist(false) }">
  <button @click="darkMode = !darkMode">Toggle</button>
</div>
```

- Auto-saves to `localStorage` under a key derived from the property name.
- Customize: `$persist(0).as('counter-key')`,
  `.using(sessionStorage)`.
- See `references/plugins.md` for full options.

## $focus — Focus plugin

```html
<button @click="$focus.focus($refs.input)">Focus input</button>
<button @click="$focus.focusable($refs.modal).first().focus()">First focusable</button>
```

Programmatic focus utilities — see `references/plugins.md`.

## Custom magics — Alpine.magic()

Register your own — see `references/globals.md`. Naming convention:
`$camelCase`. Common community magics include `$clipboard`,
`$tooltip`, `$truncate`.

## Magic gotchas

- `$el` inside a method (`Alpine.data().method()`) is the **root**
  element of the scope, **not** the element that triggered the
  handler. Inside an inline `@click="…"` it's the element with the
  listener. This is the most common confusion.
- `$watch` inside a re-renderable parent (Livewire morph) survives
  morphdom, but multiple `init()` calls on the same persistent scope
  would stack watchers — guard with a flag if your scope can re-init.
- `$dispatch` events do NOT cross shadow DOM by default.
- `$store.foo.bar = 1` is reactive; `$store.foo = { bar: 1 }` is also
  reactive. Replacing the whole `$store.foo` reference is rare but works.
