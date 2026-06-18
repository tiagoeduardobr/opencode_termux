# Livewire ↔ Alpine interop

Livewire and Alpine are designed to coexist on the same elements.
Livewire bundles Alpine internally (you don't load it twice). The two
directive namespaces (`wire:*` and `x-*`) are both legal on the same
element. This page documents the interactions that bite people.

> **Assumption:** notes below assume Livewire **v3**. Livewire v2
> differs in `$wire` surface, has no `@entangle.live`, and bundles an
> older Alpine. Verify against the live Livewire docs for v2 projects.

## Attribute ordering (rule of thumb)

When stacking `wire:*` and `x-*` on the same element, **put `wire:*`
first, then `x-*`**.

```html
<input wire:model.live="search" x-model="search">  <!-- correct -->
<input x-model="search" wire:model.live="search">  <!-- can race -->
```

Both attribute sets work no matter the order, but Livewire's morphdom
phase respects DOM order; in practice keeping `wire:*` left of `x-*`
makes diffs and dev-tools output easier to follow and avoids the rare
case where a third-party morph reorders attributes mid-update.

## $wire — Alpine-side bridge to the Livewire component

Inside any Alpine expression rooted in a Livewire component:

```html
<button @click="$wire.save()">Save</button>
<button @click="$wire.set('count', 5)">Set 5</button>
<span x-text="$wire.count"></span>          <!-- reactive read -->
<span x-text="$wire.user.email"></span>     <!-- nested reactive read -->
```

- `$wire.foo` is a **reactive proxy** of the server-side property `foo`.
  Reading it in `x-text` / `:class` re-runs the binding when the
  Livewire round-trip updates `foo`.
- `$wire.set('foo', value)` updates server state (debounced into the
  next request batch unless you use `.live` modifier elsewhere).
- `$wire.$call('method', ...args)` calls a server-side method.
- `$wire.$refresh()` forces a re-render.
- `$wire.$watch('foo', cb)` subscribes (Alpine `$watch` works on
  `$wire.foo` too).

## @entangle — share state between Alpine and Livewire

```html
<div x-data="{ open: @entangle('isOpen') }">
  <button @click="open = !open">Toggle</button>
  <div x-show="open">contents</div>
</div>
```

- Two-way bind: changes on either side propagate.
- Default: **deferred** — Alpine update is batched and sent on next
  Livewire request.
- Use `.live` for real-time round-trip on each change:
  `@entangle('isOpen').live`.
- Use this when you need both client-side instant feedback (Alpine)
  AND server-side state continuity (Livewire) without writing manual
  sync code.

### When to use what

| Want | Use |
|---|---|
| Pure client-only state (open/closed, hover) | plain Alpine `x-data` |
| Pure server-only state (auth user) | plain Livewire property |
| Shared, both sides should know | `@entangle('foo')` |
| Shared, every change must hit server | `@entangle('foo').live` |
| Read server state from Alpine without binding | `$wire.foo` |
| Trigger a server method from Alpine | `$wire.$call('method')` |

## Persistent Alpine scope across Livewire re-renders

Livewire re-renders by morphing the server-rendered HTML into the live
DOM (using the same algorithm as the Morph plugin). Alpine state on
elements that **survive** the morph is preserved. Implications:

1. `init()` on a persistent root will **NOT** re-run on every Livewire
   render — only on initial mount.
2. If you have logic that needs to run on every server-side update,
   listen for `morphed` events (Livewire emits hooks per update) or
   pair an Alpine watcher on a `$wire.*` property.
3. Adding a `wire:key` on loop items is essential — same as `:key` on
   `x-for`, but for Livewire's morph.

## Livewire events ↔ Alpine

Livewire dispatches Browser events you can listen to from Alpine:

```html
<div x-data
     @user-saved.window="banner = 'saved'">
```

From server: `$this->dispatch('user-saved')`. From Alpine:
`$dispatch('user-saved')` is also caught by Livewire if any component
has a matching `#[On('user-saved')]` listener.

## Common interop pitfalls

1. **`wire:model` + `x-model` on the same input without coordination.**
   Either rely on Livewire's `wire:model.live` and read from `$wire.*`
   in Alpine, OR `@entangle` an Alpine prop. Don't double-bind to the
   same input with both `wire:model` and `x-model` to two different
   variables.
2. **Forgetting `wire:key` inside `@foreach` loops** that interact
   with Alpine state — Livewire's morph will swap children unpredictably
   and Alpine state on those rows will go missing.
3. **`x-init` running once even though Livewire re-renders.** This is
   correct behavior. Use `$watch('$wire.foo', …)` or a `morph` hook
   if you need per-render side effects.
4. **Alpine plugins must be registered before Livewire boots.**
   Livewire bundles Alpine and calls `Alpine.start()` itself; register
   plugins inside an `alpine:init` listener.
   ```html
   <script>
   document.addEventListener('alpine:init', () => {
     Alpine.plugin(window.Persist) // example
     Alpine.data('myComponent', () => ({ … }))
   })
   </script>
   ```
5. **`@entangle` with deeply nested objects** can be heavy on every
   keystroke (whole object diffed each round-trip). Either flatten the
   shape or use `@entangle('foo')` (deferred) instead of `.live`.
6. **`@click="$wire.save()"` on a `<button type="submit">` inside a
   form** still submits the form first. Add `.prevent`:
   `@click.prevent="$wire.save()"`.
7. **AlpineJS components inside `wire:ignore`** keep working but won't
   receive server-side morph updates. That's the point — use
   `wire:ignore` for third-party widgets (date pickers, charts) that
   manage their own DOM.

## Suggested patterns

- **Form with optimistic UI:** `wire:model.live` for the input,
  `@entangle('saving').live` for a `saving` flag, Alpine drives the
  spinner / disabled state.
- **Modal opened by Livewire event:** server dispatches
  `modal-open`, Alpine catches `@modal-open.window="open = true"`.
- **Confirmation dialog:** Alpine owns `confirming` flag locally,
  on confirm calls `$wire.delete(id)`.
- **Third-party widget (Flatpickr, Chart.js):** wrap in
  `wire:ignore` + Alpine `init` to mount the widget once; sync via
  `$wire.$watch('value', v => widget.set(v))`.

> **Assumption:** the precise event names emitted by Livewire's
> internal hooks (e.g., `morph.updated`) are version-specific. Verify
> on https://livewire.laravel.com/docs/lifecycle-hooks before relying
> on them.
