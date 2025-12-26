# HTML Coding Standards

> **Language:** HTML5
> **Applies to:** All web projects using HTML

## HTML-Specific Standards

### Semantic HTML

- **Use semantic elements** - Prefer `<article>`, `<section>`, `<nav>`, `<header>`, `<footer>`, `<main>` over generic `<div>`
- **Use appropriate heading hierarchy** - Start with `<h1>`, follow sequential order (h1 → h2 → h3)
- **Use lists for lists** - Use `<ul>`, `<ol>`, `<li>` for list content, not `<div>`
- **Use tables for tabular data only** - Never for layout

**Example:**
```html
<!-- ❌ Non-semantic markup -->
<div class="header">
  <div class="nav">
    <div class="nav-item">Home</div>
    <div class="nav-item">About</div>
  </div>
</div>

<!-- ✅ Semantic markup -->
<header>
  <nav>
    <ul>
      <li><a href="/">Home</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
</header>
```

### Document Structure

- **Always include DOCTYPE** - Use `<!DOCTYPE html>` for HTML5
- **Specify language** - Add `lang` attribute to `<html>` element
- **Include charset** - Add `<meta charset="UTF-8">` in `<head>`
- **Include viewport meta** - Add `<meta name="viewport" content="width=device-width, initial-scale=1.0">` for responsive design
- **Use meaningful title** - Every page must have a descriptive `<title>`

**Example:**
```html
<!-- ✅ Proper document structure -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Brief page description">
  <title>Page Title - Site Name</title>
</head>
<body>
  <main>
    <!-- Page content -->
  </main>
</body>
</html>
```

### Accessibility (a11y)

- **All images must have `alt` attributes** - Provide descriptive text or empty string for decorative images
- **Use ARIA attributes appropriately** - Only when semantic HTML isn't sufficient
- **All form inputs must have labels** - Use `<label>` or `aria-label`
- **Use proper button elements** - Use `<button>` for actions, `<a>` for navigation
- **Ensure keyboard navigation** - All interactive elements must be keyboard accessible
- **Use `role` attributes** - Only when semantic elements don't exist

**Example:**
```html
<!-- ❌ Poor accessibility -->
<div onclick="submitForm()">Submit</div>
<input type="text" placeholder="Email">
<img src="logo.png">

<!-- ✅ Accessible markup -->
<button type="submit" aria-label="Submit form">Submit</button>

<label for="email">Email Address</label>
<input
  type="email"
  id="email"
  name="email"
  aria-required="true"
  aria-describedby="email-help"
>
<span id="email-help">We'll never share your email</span>

<img src="logo.png" alt="Company logo">
<img src="decorative-pattern.png" alt="" role="presentation">
```

### Forms

- **Use proper input types** - Use `email`, `tel`, `url`, `number`, `date` instead of generic `text`
- **Include labels for all inputs** - Use `<label>` with `for` attribute or wrap inputs
- **Group related inputs** - Use `<fieldset>` and `<legend>`
- **Include validation attributes** - Use `required`, `pattern`, `min`, `max`, `minlength`, `maxlength`
- **Use autocomplete** - Add `autocomplete` attributes for user convenience

**Example:**
```html
<!-- ✅ Well-structured form -->
<form action="/submit" method="POST">
  <fieldset>
    <legend>Personal Information</legend>

    <div class="form-group">
      <label for="name">Full Name</label>
      <input
        type="text"
        id="name"
        name="name"
        required
        minlength="2"
        autocomplete="name"
      >
    </div>

    <div class="form-group">
      <label for="email">Email</label>
      <input
        type="email"
        id="email"
        name="email"
        required
        autocomplete="email"
        aria-describedby="email-help"
      >
      <small id="email-help">We'll send a confirmation email</small>
    </div>

    <div class="form-group">
      <label for="phone">Phone</label>
      <input
        type="tel"
        id="phone"
        name="phone"
        pattern="[0-9]{3}-[0-9]{3}-[0-9]{4}"
        placeholder="123-456-7890"
        autocomplete="tel"
      >
    </div>
  </fieldset>

  <button type="submit">Submit</button>
</form>
```

### Links and Buttons

- **Use descriptive link text** - Avoid "click here" or "read more"
- **Open external links in new tab** - Use `target="_blank" rel="noopener noreferrer"`
- **Use `<button>` for actions** - Use `<a>` for navigation
- **Include title for context** - Add `title` attribute for additional context when needed

**Example:**
```html
<!-- ❌ Poor link practices -->
<a href="/article">Click here</a>
<a href="https://example.com" target="_blank">External site</a>
<div class="button" onclick="save()">Save</div>

<!-- ✅ Good link practices -->
<a href="/article">Read the full article about HTML best practices</a>
<a href="https://example.com" target="_blank" rel="noopener noreferrer">
  Visit External Site (opens in new tab)
</a>
<button type="button" onclick="save()">Save Changes</button>
```

### Code Organization

- **Use consistent indentation** - 2 or 4 spaces (be consistent)
- **One element per line** - Except inline elements within text
- **Close all tags** - Even self-closing tags should use `<tag />` or `<tag>`
- **Lowercase element and attribute names** - HTML is case-insensitive, but use lowercase
- **Quote all attribute values** - Use double quotes

**Example:**
```html
<!-- ❌ Inconsistent formatting -->
<DIV CLASS=container><P>Text <SPAN>inline</SPAN></P>
<IMG SRC='image.jpg'></DIV>

<!-- ✅ Consistent formatting -->
<div class="container">
  <p>
    Text <span>inline</span>
  </p>
  <img src="image.jpg" alt="Description">
</div>
```

### Performance

- **Load CSS in `<head>`** - Use `<link>` in document head
- **Load JavaScript before `</body>`** - Or use `defer`/`async` attributes
- **Use lazy loading for images** - Add `loading="lazy"` for below-fold images
- **Optimize images** - Use appropriate formats (WebP, AVIF) and sizes
- **Minimize inline styles** - Use external stylesheets

**Example:**
```html
<!-- ✅ Performance optimized -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title</title>

  <!-- CSS in head -->
  <link rel="stylesheet" href="/styles/main.css">

  <!-- Preload critical resources -->
  <link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
</head>
<body>
  <main>
    <!-- Above-fold image -->
    <img src="hero.webp" alt="Hero image">

    <!-- Below-fold images with lazy loading -->
    <img src="gallery-1.webp" alt="Gallery image" loading="lazy">
    <img src="gallery-2.webp" alt="Gallery image" loading="lazy">
  </main>

  <!-- JavaScript at end of body or with defer -->
  <script src="/scripts/main.js" defer></script>
</body>
</html>
```

### SEO and Metadata

- **Include meta description** - Unique description for each page (150-160 characters)
- **Use Open Graph tags** - For social media sharing
- **Add structured data** - Use JSON-LD for rich snippets
- **Include canonical URL** - Prevent duplicate content issues

**Example:**
```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title - Site Name</title>

  <!-- SEO -->
  <meta name="description" content="Concise page description for search results">
  <link rel="canonical" href="https://example.com/page">

  <!-- Open Graph -->
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Page description for social sharing">
  <meta property="og:image" content="https://example.com/image.jpg">
  <meta property="og:url" content="https://example.com/page">
  <meta property="og:type" content="website">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Page Title">
  <meta name="twitter:description" content="Page description">
  <meta name="twitter:image" content="https://example.com/image.jpg">

  <!-- Structured Data -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Article",
    "headline": "Article Headline",
    "author": {
      "@type": "Person",
      "name": "Author Name"
    },
    "datePublished": "2025-01-01"
  }
  </script>
</head>
```

### Security

- **Sanitize user input** - Never trust user-generated content
- **Use HTTPS** - All resources should use HTTPS
- **Add security headers** - Use Content Security Policy
- **Validate form inputs** - Client-side and server-side validation
- **Use `rel="noopener noreferrer"`** - For external links with `target="_blank"`

**Example:**
```html
<!-- ✅ Security best practices -->
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline'">
</head>

<!-- External link security -->
<a href="https://example.com" target="_blank" rel="noopener noreferrer">
  External Link
</a>

<!-- Form with validation -->
<form action="/submit" method="POST">
  <input
    type="email"
    name="email"
    required
    pattern="[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$"
  >
  <button type="submit">Submit</button>
</form>
```

### Common Pitfalls

#### Avoid div-soup
```html
<!-- ❌ Too many meaningless divs -->
<div class="wrapper">
  <div class="container">
    <div class="content">
      <div class="text">Hello</div>
    </div>
  </div>
</div>

<!-- ✅ Semantic, minimal markup -->
<main>
  <p>Hello</p>
</main>
```

#### Avoid inline event handlers
```html
<!-- ❌ Inline JavaScript -->
<button onclick="handleClick()">Click me</button>

<!-- ✅ Add event listeners in JavaScript -->
<button id="myButton">Click me</button>
<script>
  document.getElementById('myButton').addEventListener('click', handleClick);
</script>
```

#### Don't use tables for layout
```html
<!-- ❌ Tables for layout -->
<table>
  <tr>
    <td>Navigation</td>
    <td>Content</td>
  </tr>
</table>

<!-- ✅ Use CSS Grid or Flexbox -->
<div class="layout">
  <nav>Navigation</nav>
  <main>Content</main>
</div>
```

## Validation

- **Validate HTML** - Use [W3C Markup Validation Service](https://validator.w3.org/)
- **Check accessibility** - Use tools like axe DevTools, WAVE, or Lighthouse
- **Test keyboard navigation** - Ensure all interactive elements are accessible via keyboard
- **Test with screen readers** - Verify content is accessible to assistive technologies

## Related Resources

- See `languages/css/coding-standards.md` for CSS best practices
- See `frameworks/react/best-practices.md` for React-specific HTML patterns
- See `base/security-principles.md` for web security guidelines

## References

- **MDN HTML Guide:** https://developer.mozilla.org/en-US/docs/Web/HTML
- **HTML5 Specification:** https://html.spec.whatwg.org/
- **Web Content Accessibility Guidelines (WCAG):** https://www.w3.org/WAI/WCAG21/quickref/
- **HTML Validator:** https://validator.w3.org/
