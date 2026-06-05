---
name: astro-static
description: Astro static site template principles. Content-focused websites, blogs, documentation.
---

# Astro Static Site Template

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Astro 4.x |
| Content | MDX + Content Collections |
| Styling | Tailwind CSS |
| Integrations | Sitemap, RSS, SEO |
| Output | Static/SSG |

---

## Directory Structure

```
project-name/
â”œâ”€â”€ src/
â”‚   â”œâ”€â”€ components/      # .astro components
â”‚   â”œâ”€â”€ content/         # MDX content
â”‚   â”‚   â”œâ”€â”€ blog/
â”‚   â”‚   â””â”€â”€ config.ts    # Collection schemas
â”‚   â”œâ”€â”€ layouts/         # Page layouts
â”‚   â”œâ”€â”€ pages/           # File-based routing
â”‚   â””â”€â”€ styles/
â”œâ”€â”€ public/              # Static assets
â”œâ”€â”€ astro.config.mjs
â””â”€â”€ package.json
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| Content Collections | Type-safe content with Zod schemas |
| Islands Architecture | Partial hydration for interactivity |
| Zero JS by default | Static HTML unless needed |
| MDX Support | Markdown with components |

---

## Setup Steps

1. `npm create astro@latest {{name}}`
2. Add integrations: `npx astro add mdx tailwind sitemap`
3. Configure `astro.config.mjs`
4. Create content collections
5. `npm run dev`

---

## Deployment

| Platform | Method |
|----------|--------|
| Railway/Cloudflare Pages | Auto-detected |
| Netlify | Auto-detected |
| Cloudflare Pages | Auto-detected |
| GitHub Pages | Build + deploy action |

---

## Best Practices

- Use Content Collections for type safety
- Leverage static generation
- Add islands only where needed
- Optimize images with Astro Image

