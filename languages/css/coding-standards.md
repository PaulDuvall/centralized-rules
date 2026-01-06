# CSS Coding Standards

> **Language:** CSS3
> **Applies to:** All web projects using CSS

## CSS-Specific Standards

### Code Organization

- **Use BEM methodology** - `.block__element--modifier` naming
- **Organize by component** - Keep related styles together
- **Use classes, not IDs** - IDs have high specificity
- **One selector per line** - For readability
- **Alphabetize properties** within rule blocks

**Example:**
```css
.header {
  background-color: blue;
  color: white;
  margin: 0;
  padding: 10px;
}

.header__nav-item--active {
  font-weight: bold;
}
```

### Naming Conventions

- **Use lowercase with hyphens** - `.my-component` not `.myComponent`
- **Be descriptive** - Use clear, meaningful names
- **Avoid abbreviations** - Unless universally understood (e.g., `btn`)

**Example:**
```css
.card { }
.card__title { }
.card--featured { }
.card__button--primary { }
```

### Selectors

- **Avoid over-qualification** - Don't use `div.classname`
- **Avoid deep nesting** - Maximum 3 levels
- **Avoid universal selectors** - `*` impacts performance
- **Use attribute selectors for form inputs** - `input[type="text"]`

**Example:**
```css
.nav-link { }
.nav-item > .nav-link { }
input[type="text"] { }
```

### Specificity

- **Keep specificity low** - Use single class selectors
- **Avoid `!important`** - Except for utility classes
- **Order matters** - Later rules override earlier ones

**Example:**
```css
.nav-link { }
.nav-link--active { }
.button { color: blue; }
```

### Layout

- **Use Flexbox or Grid** - Avoid floats
- **Mobile-first** - Use `min-width` media queries
- **Grid for pages** - Flexbox for components

**Example:**
```css
.container {
  display: grid;
  gap: 1rem;
  padding: 1rem;
}

@media (min-width: 768px) {
  .container {
    grid-template-columns: repeat(2, 1fr);
  }
}
```

### Responsive Design

- **Use relative units** - `rem`, `em`, `%`, `vw`, `vh` (not `px`)
- **Mobile-first** - Use `min-width` breakpoints: 768px, 1024px, 1440px
- **Use `clamp()`** - For fluid typography and spacing

**Example:**
```css
.container {
  font-size: clamp(1rem, 2.5vw, 1.5rem);
  padding: 1rem;
  width: 90%;
}

@media (min-width: 768px) {
  .container {
    padding: 2rem;
    width: 85%;
  }
}
```

### CSS Variables

- **Define in `:root`** - Colors, spacing, typography, transitions
- **Use semantic naming** - `--color-primary` not `--blue`
- **Scope component variables** - For component-specific overrides

**Example:**
```css
:root {
  --color-primary: #3b82f6;
  --color-error: #ef4444;
  --spacing-md: 1rem;
  --spacing-lg: 2rem;
  --border-radius: 0.375rem;
  --transition-speed: 200ms;
}

.button {
  background-color: var(--color-primary);
  padding: var(--spacing-sm) var(--spacing-md);
  transition: background-color var(--transition-speed);
}

.card {
  --card-padding: var(--spacing-md);
  padding: var(--card-padding);
}
```

### Typography

- **Limit font families** - Maximum 2-3 total
- **Use relative units** - `rem` or `em` for font sizes
- **Set line-height unitless** - Use ratios (1.6 for body, 1.2 for headings)
- **Optimize web fonts** - Use `font-display: swap`

**Example:**
```css
:root {
  --font-family-sans: 'Inter', system-ui, sans-serif;
  --font-family-mono: 'Fira Code', monospace;
}

body {
  font-family: var(--font-family-sans);
  font-size: 1rem;
  line-height: 1.6;
}

h1 { font-size: 2.5rem; line-height: 1.2; }
h2 { font-size: 2rem; line-height: 1.2; }

@font-face {
  font-display: swap;
  font-family: 'Inter';
  src: url('/fonts/inter-regular.woff2') format('woff2');
}
```

### Colors

- **Use CSS variables** - Semantic naming: `--color-primary`, `--color-error`
- **Ensure WCAG AA contrast** - 4.5:1 text, 3:1 UI components
- **Use `color-mix()` for variants** - Instead of multiple color variables

**Example:**
```css
:root {
  --color-primary: #3b82f6;
  --color-error: #ef4444;
  --color-text: #1f2937;
  --color-background: #ffffff;
}

.button {
  background-color: var(--color-primary);
  color: white;
}

.button:hover {
  background-color: color-mix(in srgb, var(--color-primary) 80%, black);
}
```

### Performance

- **Use shorthand properties** - `margin: 10px` not separate properties
- **Avoid expensive animations** - Use `transform` and `opacity` only
- **Limit `box-shadow`** - Single shadow per element
- **Animate only necessary properties** - Not `all`

**Example:**
```css
.box {
  margin: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.animated {
  transition: transform 0.3s, opacity 0.3s;
}

@keyframes slideIn {
  from { opacity: 0; transform: translateY(-20px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### Accessibility

- **Don't rely on color alone** - Use icons, patterns, or text
- **Ensure WCAG AA contrast** - 4.5:1 text, 3:1 UI components
- **Respect motion preferences** - Use `prefers-reduced-motion: reduce`
- **Make focus visible** - Outline: 2px solid with offset
- **Support high contrast mode** - Use `prefers-contrast: high`

**Example:**
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

button:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

@media (prefers-contrast: high) {
  .button {
    border: 2px solid currentColor;
  }
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-background: #1f2937;
    --color-text: #f9fafb;
  }
}
```

### Anti-Patterns

- **No magic numbers** - Use CSS variables with semantic names
- **No IDs for styling** - Use classes only
- **No `!important`** - Fix specificity with class modifiers instead
- **No outline removal** - Use `:focus-visible` with visible alternative

**Example:**
```css
/* Correct */
.box { margin-top: var(--spacing-md); }
.text--emphasized { color: darkblue; }
*:focus-visible { outline: 2px solid var(--color-primary); }
```

## File Organization

```
styles/
├── base/
│   ├── reset.css
│   ├── variables.css
│   └── typography.css
├── components/
│   ├── button.css
│   ├── card.css
│   └── navigation.css
├── layouts/
│   ├── grid.css
│   └── container.css
└── main.css
```

## Validation and Linting

- **Use Stylelint** - `stylelint-config-standard` with custom rules
- **Rules** - `max-nesting-depth: 3`, `selector-max-id: 0`, no duplicate properties
- **Test responsive** - Breakpoints 320px, 768px, 1024px, 1440px
- **Validate contrast** - WCAG AA minimum

**Stylelint config:**
```json
{
  "extends": "stylelint-config-standard",
  "rules": {
    "max-nesting-depth": 3,
    "selector-max-id": 0,
    "declaration-block-no-duplicate-properties": true
  }
}
```

## Modern CSS Features

### Container Queries
```css
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    grid-template-columns: 1fr 2fr;
  }
}
```

### CSS Nesting
```css
.card {
  padding: 1rem;

  & .card__title {
    font-size: 1.5rem;
  }

  &:hover {
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }
}
```

### Cascade Layers
```css
@layer reset, base, components, utilities;

@layer reset {
  * { margin: 0; padding: 0; }
}

@layer components {
  .button { padding: 0.5rem 1rem; }
}
```

## References

- **MDN CSS Guide:** https://developer.mozilla.org/en-US/docs/Web/CSS
- **CSS Validator:** https://jigsaw.w3.org/css-validator/
- **Browser support:** https://caniuse.com/
