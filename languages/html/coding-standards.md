# HTML Coding Standards

> **Language:** HTML5
> **Applies to:** All web projects using HTML

## Semantic HTML

- **Use semantic elements** - Prefer `<article>`, `<section>`, `<nav>`, `<header>`, `<footer>`, `<main>` over `<div>`
- **Start headings with `<h1>` in sequential order** - h1 → h2 → h3 (no gaps)
- **Use `<ul>`, `<ol>`, `<li>` for lists** - Not `<div>`
- **Use tables for tabular data only** - Never for layout

Example:
```html
<!-- ✅ -->
<header>
  <nav>
    <ul>
      <li><a href="/">Home</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
</header>
```

## Document Structure

- **Include `<!DOCTYPE html>`** and `<html lang="en">`
- **Add `<meta charset="UTF-8">` and `<meta name="viewport" content="width=device-width, initial-scale=1.0">`**
- **Include descriptive `<title>`**

Example:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title</title>
</head>
<body>
  <main>Content</main>
</body>
</html>
```

## Accessibility

- **All images require `alt` attribute** - Descriptive text or empty string for decorative images
- **All form inputs require `<label>`** - Or `aria-label` if label hidden
- **Use `<button>` for actions, `<a>` for navigation** - Not `<div onclick>`
- **All interactive elements keyboard accessible**
- **Use ARIA only when semantic HTML insufficient** - `aria-label`, `aria-describedby`, `aria-required`

Example:
```html
<button type="submit">Submit</button>

<label for="email">Email</label>
<input type="email" id="email" name="email" required aria-describedby="email-help">
<span id="email-help">We'll never share your email</span>

<img src="logo.png" alt="Company logo">
<img src="pattern.png" alt="">
```

## Forms

- **Use semantic input types** - `email`, `tel`, `url`, `number`, `date` (not generic `text`)
- **Group related inputs with `<fieldset>` and `<legend>`**
- **Include validation attributes** - `required`, `pattern`, `min`, `max`, `minlength`, `maxlength`
- **Add `autocomplete` attributes**

Example:
```html
<form action="/submit" method="POST">
  <fieldset>
    <legend>Personal Information</legend>

    <label for="email">Email</label>
    <input type="email" id="email" name="email" required autocomplete="email">

    <label for="phone">Phone</label>
    <input type="tel" id="phone" name="phone" pattern="[0-9]{3}-[0-9]{3}-[0-9]{4}" autocomplete="tel">
  </fieldset>

  <button type="submit">Submit</button>
</form>
```

## Links and Buttons

- **Use descriptive link text** - Avoid "click here", "read more"
- **External links: `target="_blank" rel="noopener noreferrer"`**
- **Use `<button>` for actions, `<a>` for navigation**

Example:
```html
<a href="/article">Read the full article</a>
<a href="https://example.com" target="_blank" rel="noopener noreferrer">Visit Example</a>
<button type="button">Save Changes</button>
```

## Code Organization

- **Consistent indentation** - 2 or 4 spaces
- **One element per line** - Inline elements excepted
- **Lowercase element and attribute names**
- **Double quote all attribute values**

Example:
```html
<div class="container">
  <p>Text <span>inline</span></p>
  <img src="image.jpg" alt="Description">
</div>
```

## Performance

- **CSS in `<head>` with `<link>`**
- **JavaScript at end of `<body>` or with `defer` attribute**
- **Lazy load below-fold images: `loading="lazy"`**
- **Use WebP/AVIF image formats**
- **External stylesheets only** - No inline styles

Example:
```html
<head>
  <link rel="stylesheet" href="/styles/main.css">
  <link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
</head>
<body>
  <img src="hero.webp" alt="Hero image">
  <img src="gallery.webp" alt="Gallery" loading="lazy">
  <script src="/scripts/main.js" defer></script>
</body>
```

## SEO and Metadata

- **Meta description 150-160 characters** - Unique per page
- **Canonical URL** - `<link rel="canonical" href="https://example.com/page">`
- **Open Graph tags** - `og:title`, `og:description`, `og:image`, `og:url`, `og:type`
- **Structured data** - JSON-LD for rich snippets (Article, Product, etc.)

Example:
```html
<head>
  <meta name="description" content="Page description (150-160 chars)">
  <link rel="canonical" href="https://example.com/page">
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Description for social sharing">
  <meta property="og:image" content="https://example.com/image.jpg">
  <meta property="og:type" content="website">
  <script type="application/ld+json">
    {"@context":"https://schema.org","@type":"Article","headline":"Title"}
  </script>
</head>
```

## Security

- **All resources use HTTPS**
- **Content Security Policy meta tag** - `<meta http-equiv="Content-Security-Policy" content="...">`
- **External links: `rel="noopener noreferrer"`**
- **Validate form inputs** - Client and server-side
- **Sanitize user input** - Server-side rendering

Example:
```html
<head>
  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self'">
</head>

<a href="https://example.com" target="_blank" rel="noopener noreferrer">Link</a>

<form action="/submit" method="POST">
  <input type="email" name="email" required>
  <button type="submit">Submit</button>
</form>
```

## Common Pitfalls

### Avoid nested divs (div-soup)
Use semantic elements instead: `<main>`, `<article>`, `<section>`, `<aside>`

### Avoid inline event handlers
Use JavaScript event listeners, not `onclick` attributes

### Don't use tables for layout
Use CSS Grid or Flexbox instead - tables are for tabular data only

## Validation Tools

- [W3C Markup Validator](https://validator.w3.org/)
- [axe DevTools](https://www.deque.com/axe/devtools/) for accessibility
- Lighthouse (Chrome DevTools) for performance and accessibility
- Screen readers (NVDA, JAWS, VoiceOver) for assistive technology testing

## Related Standards

- See `languages/css/coding-standards.md` for CSS best practices
- See `frameworks/react/best-practices.md` for React-specific HTML patterns
- See `base/security-principles.md` for web security guidelines
