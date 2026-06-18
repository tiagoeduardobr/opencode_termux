# Directives — full reference

Every directive Alpine ships, with the gotchas that bite people in real
codebases. Shorthand: `:` is `x-bind:`, `@` is `x-on:`.

## x-data — declare a component scope

```html
<div x-data="{ open: false, count: 0 }">…</div>
```

- The expression is a **JavaScript object literal** (not JSON — methods
  and getters allowed).
- Every property is reactive (Proxy-wrapped).
- A nested `x-data` creates a **new child scope**, not an extension. To
  inherit cleanly, prefer one root scope and pass values down via
  expressions, or register a named component (`Alpine.data`).

### Lifecycle hooks inside the data object

```js
Alpine.data('widget', () => ({
  open: false,
  init() {                    // runs once after Alpine wires the scope
    this.$watch('open', v => console.log('open ->', v))
  },
  destroy() {                 // runs when the element is removed
    /* cleanup */
  },
}))
```

### Multiple components on one element

You can spread two `Alpine.data` registrations:

```html
<div x-data="{ ...counter(), ...toggler() }">…</div>
```

…but only if both are pure objects (no overlapping `init`).

## x-init — one-shot imperative init

```html
<div x-data="{ ready: false }" x-init="setTimeout(() => ready = true, 100)">
```

- Runs **before** child directives bind.
- Runs once. For reactive reactions, use `x-effect` or `$watch`.
- If you need refs to exist, wrap in `$nextTick(() => …)`.

## x-show — toggle display:none

```html
<div x-show="open">contents</div>
```

- Sets inline `display: none` when falsy; restores original on truthy.
- Element stays in DOM. State (input values, video playback) is preserved.
- Pair with `x-cloak` to avoid initial-render flash.
- Use `x-transition` to animate.

## x-if — mount/unmount

```html
<template x-if="open">
  <div>only here when open</div>
</template>
```

- Must be on a `<template>` tag with **exactly one** root child.
- Element is built/destroyed on every truthy/falsy change.
- No state retained inside (each mount is fresh).
- Cannot be combined with `x-transition` (use `x-show` if you want anim).

## x-for — loop

```html
<template x-for="(item, index) in items" :key="item.id">
  <li><span x-text="index + 1"></span> — <span x-text="item.name"></span></li>
</template>
```

- Must be on `<template>` with one root child.
- `:key` strongly recommended (omit only for static, never-reordered lists).
- Iteration variable forms: `item in items`, `(item, index) in items`,
  `(item, index, collection) in items`, `n in 10` (range), `key in obj`.
- Inside the loop, `item` and `index` are in scope alongside the parent
  `x-data`.

## x-bind / : — reactively set attributes

```html
<button :disabled="loading" :aria-pressed="active">Save</button>
<a :href="`/users/${id}`">profile</a>
```

### Class binding (3 forms)

```html
<!-- string -->
<div :class="open ? 'block' : 'hidden'">

<!-- object (merges with static class) -->
<div class="px-4" :class="{ 'bg-red-500': error, 'bg-green-500': !error }">

<!-- array (mix) -->
<div :class="['base', open && 'is-open', sizes[size]]">
```

Object syntax is the safest default — it merges with the static `class`
attribute instead of overwriting.

### Style binding

```html
<div :style="{ width: pct + '%', color: error && 'red' }">
```

### Spread binding (whole bag of attributes)

```html
<div x-bind="Tooltip">…</div>
```

…where `Tooltip` is registered via `Alpine.bind('Tooltip', () => ({…}))`
— see `references/globals.md`.

## x-on / @ — listen for events

```html
<button @click="open = !open">Toggle</button>
<input @keyup.enter="submit">
<form @submit.prevent="save">…</form>
```

### Modifiers (chained, dot-separated)

| Modifier | Effect |
|---|---|
| `.prevent` | `event.preventDefault()` |
| `.stop` | `event.stopPropagation()` |
| `.outside` | Fires only on clicks **outside** the element. Common for dropdowns. |
| `.window` | Attach listener to `window` instead of element (resize, keyup-anywhere). |
| `.document` | Attach to `document`. |
| `.self` | Only when `event.target === el` (ignore bubbled). |
| `.once` | Detach after first fire. |
| `.passive` | `addEventListener({ passive: true })` (perf for scroll/touch). |
| `.capture` | Use capture phase. |
| `.debounce`, `.debounce.500ms` | Debounce by N ms (default 250ms). |
| `.throttle`, `.throttle.250ms` | Throttle. |
| `.dot`, `.camel` | Translate listener-name dots / camelCase. |

### Key modifiers

```html
<input @keyup.enter="submit">
<input @keyup.escape="close">
<input @keyup.cmd.k="openPalette"><!-- cmd on mac -->
<input @keyup.ctrl.k="openPalette">
<input @keyup.shift.tab="prev">
<input @keyup.arrow-up="hi--">
```

- Multiple chained = AND.
- Use `kebab-case` for multi-word keys (`arrow-up`, not `arrowup`).

### Custom events

```html
<div @saved.window="banner = 'saved'">…</div>
```

Pair with `$dispatch('saved')` from anywhere — see `references/magics.md`.

## x-model — two-way binding

```html
<input x-model="name">
<input type="checkbox" x-model="agree">
<select x-model="city">…</select>
<input type="checkbox" value="red" x-model="colors">  <!-- array binding -->
```

### Modifiers

| Modifier | Effect |
|---|---|
| `.lazy` | Sync on `change` instead of `input` (text inputs). |
| `.number` | Cast to Number on read. |
| `.boolean` | Cast `'true'`/`'false'` to Boolean. |
| `.debounce`, `.debounce.300ms` | Debounce sync. |
| `.throttle` | Throttle sync. |
| `.fill` | Use the input's existing DOM value to seed `x-data` if the data property is null/empty (good for SSR-pre-filled forms). |

### Custom components — `x-modelable`

Let a child `x-data` expose a property as the target of the parent's
`x-model`:

```html
<div x-data="{ form: 'hi' }">
  <input x-data="{ value: 'default' }" x-modelable="value" x-model="form">
</div>
```

## x-text — set textContent

```html
<span x-text="`${count} items`"></span>
```

Reactive. Replaces children.

## x-html — set innerHTML

```html
<div x-html="renderedMarkdown"></div>
```

**Only with trusted input** — this is an XSS hole otherwise.

## x-ref + $refs — name a node

```html
<div x-data="{ focusInput() { this.$refs.input.focus() } }">
  <input x-ref="input">
  <button @click="focusInput">Focus</button>
</div>
```

- `$refs` is scoped to the nearest enclosing `x-data`.
- Inside `x-init`, refs may not be ready — wrap in `$nextTick`.

## x-cloak — anti-FOUC

```html
<style>[x-cloak]{display:none!important}</style>
…
<div x-data="{ open: false }" x-cloak>
  <div x-show="open">…</div>
</div>
```

Alpine strips `x-cloak` after init. Without the global CSS rule, this
directive does nothing.

## x-ignore — opt out of Alpine

```html
<div x-data="…">
  <div x-ignore>
    <!-- Alpine will not parse anything here. Useful for hand-off to
         other libraries (Vue, Stimulus, third-party widgets). -->
  </div>
</div>
```

## x-effect — inline reactive watcher

```html
<div x-data="{ count: 0 }" x-effect="console.log('count is', count)">
```

- Re-runs whenever any reactive dep it reads changes.
- Roughly equivalent to `init() { this.$watch('count', …) }` but inline.
- Useful for syncing imperative APIs (e.g., chart libs) to scope.

## x-transition — enter/leave animation

Works **on** elements toggled by `x-show` (not `x-if`).

### Single-attribute helper

```html
<div x-show="open" x-transition>
```

Produces a sensible default fade+scale.

### CSS-class hooks (Tailwind-friendly)

```html
<div
  x-show="open"
  x-transition:enter="transition ease-out duration-200"
  x-transition:enter-start="opacity-0 scale-95"
  x-transition:enter-end="opacity-100 scale-100"
  x-transition:leave="transition ease-in duration-150"
  x-transition:leave-start="opacity-100 scale-100"
  x-transition:leave-end="opacity-0 scale-95">
```

### Modifier helper

```html
<div x-show="open" x-transition.duration.500ms.opacity>
```

Modifiers: `.duration.<n>ms`, `.delay.<n>ms`, `.opacity`, `.scale`,
`.scale.<n>` (default 95), `.origin.top`, `.origin.bottom`, etc.

## x-teleport — render somewhere else

```html
<template x-teleport="body">
  <div class="fixed inset-0 …">modal contents</div>
</template>
```

- Must be on `<template>`.
- Target is a CSS selector (`body`, `#modal-root`).
- The teleported element keeps its original Alpine scope (so it can read
  `open` from the original `x-data`).

## x-id + $id — stable, unique ids

```html
<div x-data x-id="['text-input']">
  <label :for="$id('text-input')">Email</label>
  <input :id="$id('text-input')">
</div>
```

- `x-id` declares which id namespaces this scope owns. Each call to
  `$id('text-input')` within this scope returns the **same** id;
  outside scopes get a different one.
- Indispensable for accessible label/control wiring inside loops or
  reusable components.

## x-modelable — custom x-model target

Covered above under `x-model`. Use when building reusable custom inputs
as `Alpine.data` components.

## Directives gotchas — fast list

- **`x-data` parse errors are silent in some browsers.** A dangling
  comma or unquoted JSON trips it; check the console for
  `Alpine Expression Error`.
- **`x-show` + `x-transition`** works; **`x-if` + `x-transition`** does
  not (use Collapse plugin or stick with `x-show`).
- **`x-for` with object iteration** — `(value, key) in obj` lets you
  iterate object keys. Don't expect Alpine to react to nested key
  insertion on plain objects unless you reassign the whole object.
- **`x-bind:class` array form** doesn't merge with the static `class`
  attribute — use object form for safe merging.
- **`@click.outside`** listens at `document` level and only fires when
  the click is outside the element where it's declared. It does NOT
  fire on the initial click that opened the dropdown if that click
  came from a child of the same `x-data` — but **does** if the
  trigger button is a sibling outside the toggled element.
- **`x-text` vs `{{ … }}`** — Alpine has no mustache interpolation.
  Use `x-text` or template literals inside `x-bind`.
