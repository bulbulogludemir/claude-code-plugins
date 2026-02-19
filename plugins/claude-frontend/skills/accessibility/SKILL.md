---
name: accessibility
description: WCAG compliance, ARIA patterns, keyboard navigation
triggers:
  - a11y
  - accessibility
  - aria
  - screen reader
  - wcag
  - erişilebilirlik
  - ekran okuyucu
---

# Accessibility Skill

WCAG 2.1 AA compliance and accessibility best practices.

## Core Principles (POUR)

1. **Perceivable** — Content available to all senses
2. **Operable** — All functionality via keyboard
3. **Understandable** — Clear and predictable
4. **Robust** — Works with assistive technology

## ARIA Patterns

### Interactive Components
```typescript
// Button with loading state
<button
  aria-busy={isLoading}
  aria-disabled={isDisabled}
  disabled={isDisabled}
>
  {isLoading ? 'Loading...' : 'Submit'}
</button>

// Dialog/Modal
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="dialog-title"
  aria-describedby="dialog-description"
>
  <h2 id="dialog-title">Title</h2>
  <p id="dialog-description">Description</p>
</div>

// Form field with error
<div>
  <label htmlFor="email">Email</label>
  <input
    id="email"
    type="email"
    aria-invalid={!!error}
    aria-describedby={error ? 'email-error' : undefined}
  />
  {error && <p id="email-error" role="alert">{error}</p>}
</div>
```

### Live Regions
```typescript
// Announce dynamic content changes
<div aria-live="polite" aria-atomic="true">
  {statusMessage}
</div>

// Urgent announcements
<div role="alert">
  {errorMessage}
</div>
```

## Keyboard Navigation

| Pattern | Keys | Implementation |
|---------|------|----------------|
| Focus trap (modals) | Tab/Shift+Tab cycle | Use `@radix-ui/react-focus-scope` |
| Dismiss | Escape | `onKeyDown` handler |
| Menu navigation | Arrow keys | `role="menu"` + `role="menuitem"` |
| Tab selection | Arrow keys | `role="tablist"` + `role="tab"` |
| Skip link | Tab (first element) | Hidden link to `#main-content` |

## Color Contrast

| Text Size | Minimum Ratio (AA) | Enhanced (AAA) |
|-----------|-------------------|----------------|
| Normal text | 4.5:1 | 7:1 |
| Large text (18px+) | 3:1 | 4.5:1 |
| UI components | 3:1 | — |

## Semantic HTML

```typescript
// Use semantic elements — NOT divs for everything
<header />    // Site header
<nav />       // Navigation
<main />      // Primary content
<article />   // Self-contained content
<section />   // Thematic grouping
<aside />     // Sidebar/related
<footer />    // Site footer

// Heading hierarchy
<h1 /> // One per page
<h2 /> // Major sections
<h3 /> // Subsections
```

## Testing Checklist

- [ ] All interactive elements reachable via keyboard
- [ ] Focus visible on all interactive elements
- [ ] Images have alt text (or alt="" for decorative)
- [ ] Forms have associated labels
- [ ] Color is not the only way to convey information
- [ ] Page has proper heading hierarchy (h1 → h2 → h3)
- [ ] Dynamic content announces changes via aria-live
- [ ] Modals trap focus and close on Escape
- [ ] Skip navigation link exists
- [ ] Contrast ratios meet WCAG AA
