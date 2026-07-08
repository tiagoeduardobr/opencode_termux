---
name: frontend-complete
description: Use when building distinctive, production-grade frontend interfaces with high design quality. Triggers include requests to create web components, pages, artifacts, posters, or applications (websites, landing pages, dashboards, React components, HTML/CSS layouts, or styling/beautifying any web UI). Guides design thinking, aesthetic direction, motion, copy, and self-critique to avoid generic AI aesthetics.
---

# Frontend Complete

Unified skill for distinctive frontend design — merging design thinking, aesthetic direction, motion, copy, and self-critique into a single workflow. Every output should feel deliberately designed for its context, not assembled from defaults.

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:

- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme — brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian. Use these as inspiration but design one true to the brief.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work — the key is intentionality, not intensity.

## Ground It in the Subject

If the brief does not pin down what the product or subject is, pin it yourself before designing: name one concrete subject, its audience, and the page's single job, and state your choice. If there's any information in your memory about the human's preferences, context about what they're building, or designs you've made before — use that as a hint. The subject's own world, its materials, instruments, artifacts, and vernacular, is where distinctive choices come from. Build with the brief's real content and subject matter throughout.

## Design Principles

### Hero as Thesis

Open with the most characteristic thing in the subject's world, in whatever form makes sense: a headline, an image, an animation, a live demo, an interactive moment. Be deliberate — a big number with a small label, supporting stats, and a gradient accent is the template answer; only use if truly the best option.

### Typography Carries Personality

Pair display and body faces deliberately, not the same families you'd reach for on any other project. Set a clear type scale with intentional weights, widths, and spacing. Choose fonts that are beautiful, unique, and interesting — avoid generic fonts like Arial and Inter. Opt for distinctive choices that elevate the aesthetics. Make the type treatment itself a memorable part of the design, not a neutral delivery vehicle.

### Color & Theme

Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Describe palettes as 4–6 named hex values.

### Structure Is Information

Structural devices — numbering, eyebrows, dividers, labels — should encode something true about the content, not decorate it. Many generic designs use numbered markers (01 / 02 / 03), but that's only appropriate if the content actually is a sequence. Question if choices like numbered markers make sense before incorporating them.

### Spatial Composition

Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.

### Backgrounds & Visual Details

Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic. Gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, grain overlays.

### Motion

Leverage motion deliberately. Think about where animation can serve the subject: a page-load sequence, a scroll-triggered reveal, hover micro-interactions, ambient atmosphere. One well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. An orchestrated moment lands harder than scattered effects; choose what the direction calls for.

**CSS-only vs Motion library**: Prioritize CSS-only solutions for HTML. Use the Motion library for React when available. Focus on high-impact moments. Sometimes less is more — extra animation can contribute to the feeling that the design is AI-generated.

### Complexity to Vision

Maximalist directions need elaborate execution with extensive animations and effects. Minimal directions need precision in spacing, type, and detail. Elegance is executing the chosen vision well. Match implementation complexity to the aesthetic vision.

### Written Content

Consider written content carefully. A design brief may not contain real content, and it's up to you to come up with copy. Copy can make a design feel as templated as the design itself. See the Writing in Design section below.

## Process: Brainstorm → Explore → Plan → Critique → Build → Critique Again

For calibration: AI-generated design clusters around three looks: (1) warm cream background (~#F4F1EA) with high-contrast serif display and terracotta accent; (2) near-black background with a single bright acid-green or vermilion accent; (3) broadsheet-style layout with hairline rules, zero border-radius, dense newspaper-like columns. All three are legitimate for some briefs, but they are defaults rather than choices. Where the brief pins down a visual direction, follow it exactly. Where it leaves an axis free, don't spend that freedom on one of these defaults.

Work in two passes:

1. **First pass — Brainstorm**: Create a compact token system with color, type, layout, and signature. Color: 4–6 named hex values. Type: faces for 2+ roles (characterful display, complementary body, utility for captions/data if needed). Layout: one-sentence prose descriptions and ASCII wireframes. Signature: the single unique element this page will be remembered by.

2. **Second pass — Review**: Review that plan against the brief. If any part reads like a generic default you'd produce for any similar page — revise that part, say what you changed and why. Only after confirming relative uniqueness should you start writing code, following the revised plan exactly and deriving every color and type decision from it.

Try to do planning and iteration in your thinking, and only show ideas to the user when you have higher confidence it'll delight them.

## Writing in Design

Words appear in a design for one reason: to make it easier to understand, and therefore easier to use. They are design material, not decoration.

- **Write from the user's side**: Name things by what people control and recognize, never by how the system is built. A person manages notifications, not webhook config.
- **Active voice as default**: A control says exactly what happens — "Save changes," not "Submit." An action keeps the same name through the whole flow: the button that says "Publish" produces a toast that says "Published."
- **Failure and emptiness**: Explain what went wrong and how to fix it, in the interface's voice. Errors don't apologize and are never vague. An empty screen is an invitation to act.
- **Register**: Conversational and tuned — plain verbs, sentence case, no filler, tone matched to the brand and audience. Let each element do exactly one job.

## Restraint & Self-Critique

Spend your boldness in one place. Let the signature element be the one memorable thing, keep everything around it quiet and disciplined, and cut any decoration that does not serve the brief. Not taking a risk can be a risk itself.

Build to a quality floor without announcing it: responsive down to mobile, visible keyboard focus, reduced motion respected.

Critique your own work as you build, taking screenshots if your environment supports it — a picture is worth 1000 tokens. Consider Chanel's advice: before leaving the house, take a look in the mirror and remove one accessory. Human creators have memory and always try to do something new, so jot down notes about what you've tried for future passes.

## Anti-Patterns to Avoid

NEVER use generic AI-generated aesthetics:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Cliched color schemes (particularly purple gradients on white backgrounds)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character
- Common convergent choices (Space Grotesk, etc.) across generations

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics.

Remember: you are capable of extraordinary creative work. Don't hold back — show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

---

*Inspirado em: synapse-ai-hub/skills/frontend-design, synapse-ai-hub/skills/designing-frontend-interfaces*
