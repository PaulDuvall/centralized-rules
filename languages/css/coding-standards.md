# CSS Coding Standards

> **Language:** CSS3
> **Applies to:** All web projects using CSS

## CSS-Specific Standards

### Code Organization

- **Use a consistent methodology** - BEM, SMACSS, or OOCSS for naming conventions
- **Organize by component** - Keep related styles together
- **Follow specificity hierarchy** - Elements → Classes → IDs (avoid IDs for styling)
- **One selector per line** - For better readability
- **Alphabetize properties** - Or group by type (positioning, box model, typography, visual)

**Example:**
```css
/* ❌ Poor organization */
.header{background:blue;color:white;padding:10px;margin:0;}
#main-nav{display:flex;}

/* ✅ Well-organized (BEM methodology) */
.header {
  background-color: blue;
  color: white;
  margin: 0;
  padding: 10px;
}

.header__navigation {
  display: flex;
}

.header__navigation-item {
  padding: 0.5rem 1rem;
}

.header__navigation-item--active {
  font-weight: bold;
}
```

### Naming Conventions (BEM)

- **Use BEM (Block Element Modifier)** - `.block__element--modifier`
- **Use lowercase with hyphens** - `.my-component` not `.myComponent` or `.MyComponent`
- **Be descriptive** - Use clear, meaningful names
- **Avoid abbreviations** - Unless universally understood (btn for button is OK)

**Example:**
```css
/* ✅ BEM naming */
.card { /* Block */ }
.card__title { /* Element */ }
.card__image { /* Element */ }
.card--featured { /* Modifier */ }
.card__button--primary { /* Element with Modifier */ }

/* Usage in HTML */
<div class="card card--featured">
  <h2 class="card__title">Title</h2>
  <img class="card__image" src="image.jpg" alt="...">
  <button class="card__button card__button--primary">Click</button>
</div>
```

### Selectors

- **Avoid over-qualification** - Don't use `div.classname`
- **Avoid deep nesting** - Maximum 3 levels deep
- **Use classes over IDs** - IDs have high specificity
- **Avoid universal selectors** - `*` can impact performance
- **Use attribute selectors wisely** - Good for form inputs

**Example:**
```css
/* ❌ Poor selectors */
div.container > ul > li > a { }
#header .nav ul li a { }
* { margin: 0; }

/* ✅ Good selectors */
.nav-link { }
.nav-item > .nav-link { }

/* ✅ Appropriate attribute selectors */
input[type="text"] { }
a[href^="https"] { }
```

### Specificity

- **Keep specificity low** - Easier to override when needed
- **Avoid `!important`** - Use only as last resort or for utility classes
- **Use classes for styling** - Not IDs or inline styles
- **Order matters** - Later rules override earlier ones of same specificity

**Example:**
```css
/* ❌ High specificity, hard to override */
#header nav ul li a.active { }
.button { color: blue !important; }

/* ✅ Low specificity, easy to override */
.nav-link { }
.nav-link--active { }
.button { color: blue; }
.button--primary { color: white; }
```

### Layout

- **Use Flexbox or Grid** - Avoid floats for layout
- **Mobile-first approach** - Start with mobile styles, use `min-width` media queries
- **Use CSS Grid for page layout** - Use Flexbox for component layout
- **Use CSS variables for consistency** - Especially for spacing, colors, typography

**Example:**
```css
/* ✅ Modern layout techniques */

/* Mobile-first base styles */
.container {
  display: grid;
  gap: 1rem;
  padding: 1rem;
}

.card {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

/* Tablet and up */
@media (min-width: 768px) {
  .container {
    grid-template-columns: repeat(2, 1fr);
    gap: 2rem;
    padding: 2rem;
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .container {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### Responsive Design

- **Use relative units** - `rem`, `em`, `%`, `vw`, `vh` instead of `px`
- **Mobile-first media queries** - Use `min-width` instead of `max-width`
- **Use CSS Grid and Flexbox** - They're responsive by nature
- **Test at common breakpoints** - 320px, 768px, 1024px, 1440px

**Example:**
```css
/* ✅ Responsive with relative units */
:root {
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 2rem;
}

.container {
  /* Fluid typography */
  font-size: clamp(1rem, 2.5vw, 1.5rem);

  /* Responsive spacing */
  padding: var(--spacing-md);
  margin: 0 auto;
  max-width: 1200px;
  width: 90%;
}

/* Mobile-first breakpoints */
@media (min-width: 768px) {
  .container {
    padding: var(--spacing-lg);
    width: 85%;
  }
}
```

### CSS Variables (Custom Properties)

- **Define global variables in `:root`** - For colors, spacing, typography
- **Use semantic naming** - `--color-primary` not `--blue`
- **Provide fallbacks** - For older browsers if needed
- **Scope variables** - Component-specific variables in component selector

**Example:**
```css
/* ✅ CSS variables */
:root {
  /* Colors */
  --color-primary: #3b82f6;
  --color-secondary: #6b7280;
  --color-success: #10b981;
  --color-error: #ef4444;
  --color-text: #1f2937;
  --color-background: #ffffff;

  /* Spacing */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 2rem;
  --spacing-xl: 4rem;

  /* Typography */
  --font-family-sans: 'Inter', system-ui, sans-serif;
  --font-family-mono: 'Fira Code', monospace;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.25rem;
  --font-size-xl: 1.5rem;

  /* Other */
  --border-radius: 0.375rem;
  --transition-speed: 200ms;
}

/* Usage */
.button {
  background-color: var(--color-primary);
  border-radius: var(--border-radius);
  color: white;
  font-family: var(--font-family-sans);
  padding: var(--spacing-sm) var(--spacing-md);
  transition: background-color var(--transition-speed);
}

.button:hover {
  background-color: color-mix(in srgb, var(--color-primary) 80%, black);
}

/* Component-scoped variables */
.card {
  --card-padding: var(--spacing-md);
  --card-background: var(--color-background);

  background-color: var(--card-background);
  padding: var(--card-padding);
}
```

### Typography

- **Use web-safe font stacks** - With fallbacks
- **Limit font variations** - Maximum 2-3 font families
- **Use relative units** - `rem` or `em` for font sizes
- **Set line-height unitless** - Use ratios (1.5, 1.6)
- **Optimize web fonts** - Use `font-display: swap`

**Example:**
```css
/* ✅ Typography best practices */
:root {
  --font-family-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI',
    Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  --font-family-serif: Georgia, 'Times New Roman', serif;
  --font-family-mono: 'Fira Code', 'Courier New', monospace;
}

body {
  color: var(--color-text);
  font-family: var(--font-family-sans);
  font-size: 1rem;
  line-height: 1.6;
}

h1, h2, h3, h4, h5, h6 {
  line-height: 1.2;
  margin-bottom: 0.5em;
  margin-top: 0;
}

h1 { font-size: 2.5rem; }
h2 { font-size: 2rem; }
h3 { font-size: 1.75rem; }

/* Web font optimization */
@font-face {
  font-display: swap;
  font-family: 'Inter';
  font-style: normal;
  font-weight: 400;
  src: url('/fonts/inter-regular.woff2') format('woff2');
}
```

### Colors

- **Use CSS variables** - For maintainability
- **Ensure contrast ratio** - WCAG AA minimum (4.5:1 for text)
- **Use HSL or color-mix()** - For color variations
- **Define semantic colors** - `--color-primary`, `--color-error`, etc.

**Example:**
```css
/* ✅ Color system */
:root {
  /* Base colors */
  --color-primary-h: 217;
  --color-primary-s: 91%;
  --color-primary-l: 60%;
  --color-primary: hsl(
    var(--color-primary-h),
    var(--color-primary-s),
    var(--color-primary-l)
  );

  /* Variants using HSL */
  --color-primary-light: hsl(
    var(--color-primary-h),
    var(--color-primary-s),
    calc(var(--color-primary-l) + 10%)
  );
  --color-primary-dark: hsl(
    var(--color-primary-h),
    var(--color-primary-s),
    calc(var(--color-primary-l) - 10%)
  );

  /* Semantic colors */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #3b82f6;

  /* Neutral colors */
  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-900: #111827;
}

/* Usage with good contrast */
.button--primary {
  background-color: var(--color-primary);
  color: white; /* Ensure 4.5:1 contrast */
}

.button--primary:hover {
  background-color: var(--color-primary-dark);
}
```

### Performance

- **Minimize CSS file size** - Remove unused styles
- **Use shorthand properties** - `margin: 0` instead of individual properties
- **Avoid expensive properties** - Minimize `box-shadow`, `filter`, `transform` animations
- **Use `will-change` sparingly** - Only for elements that will definitely change
- **Optimize animations** - Use `transform` and `opacity` for 60fps

**Example:**
```css
/* ❌ Performance issues */
.box {
  margin-top: 10px;
  margin-right: 10px;
  margin-bottom: 10px;
  margin-left: 10px;
  box-shadow: 0 0 10px rgba(0,0,0,0.5), 0 0 20px rgba(0,0,0,0.3);
}

.animated {
  transition: all 0.3s;
}

/* ✅ Performance optimized */
.box {
  margin: 10px; /* Shorthand */
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1); /* Single shadow */
}

.animated {
  /* Animate only specific properties */
  transition: transform 0.3s, opacity 0.3s;
}

/* ✅ Smooth animations */
@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.slide-in {
  animation: slideIn 0.3s ease-out;
}
```

### Accessibility

- **Don't rely on color alone** - Use icons, patterns, or text
- **Ensure sufficient contrast** - WCAG AA: 4.5:1 for text, 3:1 for large text
- **Respect user preferences** - Use `prefers-reduced-motion`
- **Make focus visible** - Don't remove outlines without replacement
- **Use relative units** - Respect user font size preferences

**Example:**
```css
/* ✅ Accessibility best practices */

/* Respect motion preferences */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Visible focus indicator */
a:focus,
button:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* Don't remove outlines without replacement */
button:focus {
  outline: none; /* Only if providing alternative */
  box-shadow: 0 0 0 3px var(--color-primary);
}

/* High contrast mode support */
@media (prefers-contrast: high) {
  .button {
    border: 2px solid currentColor;
  }
}

/* Respect color scheme preference */
@media (prefers-color-scheme: dark) {
  :root {
    --color-background: #1f2937;
    --color-text: #f9fafb;
  }
}
```

### Common Pitfalls

#### Avoid magic numbers
```css
/* ❌ Magic numbers */
.box {
  margin-top: 23px;
  padding: 17px;
}

/* ✅ Use variables with semantic meaning */
.box {
  margin-top: var(--spacing-md);
  padding: var(--spacing-md);
}
```

#### Don't use IDs for styling
```css
/* ❌ IDs for styling */
#header { }
#main-content { }

/* ✅ Use classes */
.header { }
.main-content { }
```

#### Avoid !important
```css
/* ❌ Overuse of !important */
.text { color: blue !important; }
.button { background: red !important; }

/* ✅ Fix specificity instead */
.text { color: blue; }
.text--emphasized { color: darkblue; }
```

#### Don't suppress outlines without replacement
```css
/* ❌ Removes keyboard focus indicator */
*:focus {
  outline: none;
}

/* ✅ Provide alternative focus indicator */
*:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

*:focus:not(:focus-visible) {
  outline: none;
}

*:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

## File Organization

```
styles/
├── base/
│   ├── reset.css          # CSS reset or normalize
│   ├── typography.css     # Font definitions
│   └── variables.css      # CSS custom properties
├── components/
│   ├── button.css
│   ├── card.css
│   └── navigation.css
├── layouts/
│   ├── grid.css
│   └── container.css
├── utilities/
│   └── spacing.css        # Utility classes
└── main.css               # Import all files
```

## Validation and Linting

- **Use CSS linting** - Stylelint with standard config
- **Validate CSS** - Use W3C CSS Validator
- **Check browser support** - Use caniuse.com
- **Test responsive design** - Multiple devices and screen sizes
- **Check accessibility** - Color contrast, focus indicators

**Stylelint configuration example:**
```json
{
  "extends": "stylelint-config-standard",
  "rules": {
    "color-hex-length": "short",
    "declaration-block-no-duplicate-properties": true,
    "max-nesting-depth": 3,
    "selector-max-id": 0,
    "selector-no-qualifying-type": true
  }
}
```

## Modern CSS Features

### Container Queries
```css
/* ✅ Container queries for component-based responsive design */
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    display: grid;
    grid-template-columns: 1fr 2fr;
  }
}
```

### CSS Nesting (Native)
```css
/* ✅ Native CSS nesting (modern browsers) */
.card {
  padding: 1rem;

  & .card__title {
    font-size: 1.5rem;
  }

  & .card__body {
    margin-top: 0.5rem;

    & p {
      line-height: 1.6;
    }
  }

  &:hover {
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }
}
```

### Cascade Layers
```css
/* ✅ Cascade layers for managing specificity */
@layer reset, base, components, utilities;

@layer reset {
  * { margin: 0; padding: 0; }
}

@layer base {
  body { font-family: sans-serif; }
}

@layer components {
  .button { padding: 0.5rem 1rem; }
}

@layer utilities {
  .mt-4 { margin-top: 1rem; }
}
```

## Related Resources

- See `languages/html/coding-standards.md` for HTML best practices
- See `frameworks/react/best-practices.md` for React styling approaches
- See `base/security-principles.md` for web security guidelines

## References

- **MDN CSS Guide:** https://developer.mozilla.org/en-US/docs/Web/CSS
- **CSS Specification:** https://www.w3.org/Style/CSS/
- **CSS Tricks:** https://css-tricks.com/
- **Modern CSS Solutions:** https://moderncss.dev/
- **CSS Validator:** https://jigsaw.w3.org/css-validator/
- **Can I Use:** https://caniuse.com/
