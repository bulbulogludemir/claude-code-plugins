---
name: seo
description: SEO optimization, metadata, sitemap, structured data, OG images
triggers:
  - seo
  - metadata
  - sitemap
  - robots
  - og image
  - structured data
  - json-ld
---

# SEO Skill

Implement SEO best practices for Next.js App Router projects: metadata, OG images, sitemaps, structured data, and performance hints.

## 1. Static Metadata Export

**File:** `src/app/{route}/page.tsx`

```typescript
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Page Title | Site Name',
  description: 'Concise description under 160 characters for search result snippets.',
  alternates: {
    canonical: 'https://example.com/page',
  },
  openGraph: {
    title: 'Page Title',
    description: 'Description for social sharing.',
    url: 'https://example.com/page',
    siteName: 'Site Name',
    images: [
      {
        url: 'https://example.com/og/page.png',
        width: 1200,
        height: 630,
        alt: 'Descriptive alt text for the OG image',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Page Title',
    description: 'Description for Twitter cards.',
    images: ['https://example.com/og/page.png'],
  },
}
```

---

## 2. Dynamic Metadata (generateMetadata)

**File:** `src/app/{resource}/[slug]/page.tsx`

```typescript
import type { Metadata } from 'next'
import { db } from '@/lib/db'
import { articles } from '@/lib/db/schema'
import { eq } from 'drizzle-orm'
import { notFound } from 'next/navigation'

type Props = {
  params: Promise<{ slug: string }>
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params

  const article = await db.query.articles.findFirst({
    where: eq(articles.slug, slug),
  })

  if (!article) return {}

  const ogUrl = new URL('https://example.com/api/og')
  ogUrl.searchParams.set('title', article.title)
  ogUrl.searchParams.set('author', article.authorName)

  return {
    title: `${article.title} | Site Name`,
    description: article.excerpt,
    alternates: {
      canonical: `https://example.com/articles/${slug}`,
    },
    openGraph: {
      title: article.title,
      description: article.excerpt,
      url: `https://example.com/articles/${slug}`,
      type: 'article',
      publishedTime: article.publishedAt.toISOString(),
      modifiedTime: article.updatedAt.toISOString(),
      authors: [article.authorName],
      images: [
        {
          url: ogUrl.toString(),
          width: 1200,
          height: 630,
          alt: article.title,
        },
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: article.title,
      description: article.excerpt,
      images: [ogUrl.toString()],
    },
  }
}
```

---

## 3. Dynamic OG Images (next/og)

**File:** `src/app/api/og/route.tsx`

```typescript
import { ImageResponse } from 'next/og'
import { NextRequest } from 'next/server'

export const runtime = 'edge'

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const title = searchParams.get('title') ?? 'Default Title'
  const author = searchParams.get('author')

  const interBold = await fetch(
    new URL('/public/fonts/Inter-Bold.ttf', import.meta.url)
  ).then((res) => res.arrayBuffer())

  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          backgroundColor: '#0a0a0a',
          padding: '60px 80px',
          fontFamily: 'Inter',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
          }}
        >
          <svg width="40" height="40" viewBox="0 0 40 40" fill="none">
            <rect width="40" height="40" rx="8" fill="#ffffff" />
          </svg>
          <span style={{ color: '#a1a1aa', fontSize: 24 }}>Site Name</span>
        </div>

        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: '16px',
          }}
        >
          <h1
            style={{
              fontSize: title.length > 60 ? 48 : 64,
              fontWeight: 700,
              color: '#fafafa',
              lineHeight: 1.1,
              margin: 0,
            }}
          >
            {title}
          </h1>
          {author && (
            <p style={{ fontSize: 24, color: '#a1a1aa', margin: 0 }}>
              by {author}
            </p>
          )}
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      fonts: [
        {
          name: 'Inter',
          data: interBold,
          style: 'normal',
          weight: 700,
        },
      ],
    }
  )
}
```

---

## 4. Sitemap Generation

**File:** `src/app/sitemap.ts`

```typescript
import type { MetadataRoute } from 'next'
import { db } from '@/lib/db'
import { articles, products } from '@/lib/db/schema'
import { eq } from 'drizzle-orm'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://example.com'

  // Static pages
  const staticPages: MetadataRoute.Sitemap = [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${baseUrl}/about`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.5,
    },
    {
      url: `${baseUrl}/pricing`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.8,
    },
  ]

  // Dynamic article pages
  const allArticles = await db.query.articles.findMany({
    where: eq(articles.status, 'published'),
    columns: { slug: true, updatedAt: true },
  })

  const articlePages: MetadataRoute.Sitemap = allArticles.map((article) => ({
    url: `${baseUrl}/articles/${article.slug}`,
    lastModified: article.updatedAt,
    changeFrequency: 'weekly' as const,
    priority: 0.7,
  }))

  // Dynamic product pages
  const allProducts = await db.query.products.findMany({
    where: eq(products.active, true),
    columns: { slug: true, updatedAt: true },
  })

  const productPages: MetadataRoute.Sitemap = allProducts.map((product) => ({
    url: `${baseUrl}/products/${product.slug}`,
    lastModified: product.updatedAt,
    changeFrequency: 'daily' as const,
    priority: 0.8,
  }))

  return [...staticPages, ...articlePages, ...productPages]
}
```

### Large Sitemap (50,000+ URLs)

```typescript
// app/sitemap/[id]/route.ts - Sitemap index pattern
import type { MetadataRoute } from 'next'

export async function generateSitemaps() {
  const totalProducts = await db
    .select({ count: sql`count(*)` })
    .from(products)
  const count = Number(totalProducts[0].count)
  const sitemaps = Math.ceil(count / 50000)

  return Array.from({ length: sitemaps }, (_, i) => ({ id: i }))
}

export default async function sitemap({
  id,
}: {
  id: number
}): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://example.com'
  const limit = 50000
  const offset = id * limit

  const batch = await db.query.products.findMany({
    columns: { slug: true, updatedAt: true },
    limit,
    offset,
  })

  return batch.map((product) => ({
    url: `${baseUrl}/products/${product.slug}`,
    lastModified: product.updatedAt,
  }))
}
```

---

## 5. robots.txt

**File:** `src/app/robots.ts`

```typescript
import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  const baseUrl = 'https://example.com'

  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/admin/', '/dashboard/', '/settings/'],
      },
      {
        userAgent: 'GPTBot',
        disallow: ['/'],
      },
    ],
    sitemap: `${baseUrl}/sitemap.xml`,
  }
}
```

---

## 6. JSON-LD Structured Data

**File:** `src/lib/seo/json-ld.tsx`

```typescript
import type { Thing, WithContext } from 'schema-dts'

function JsonLd<T extends Thing>({ data }: { data: WithContext<T> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  )
}

export default JsonLd
```

### Article Schema

```typescript
// app/articles/[slug]/page.tsx
import JsonLd from '@/lib/seo/json-ld'
import type { Article } from 'schema-dts'

export default async function ArticlePage({ params }: Props) {
  const { slug } = await params
  const article = await getArticle(slug)
  if (!article) notFound()

  const jsonLd: WithContext<Article> = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: article.title,
    description: article.excerpt,
    image: article.coverImage,
    datePublished: article.publishedAt.toISOString(),
    dateModified: article.updatedAt.toISOString(),
    author: {
      '@type': 'Person',
      name: article.authorName,
      url: `https://example.com/authors/${article.authorSlug}`,
    },
    publisher: {
      '@type': 'Organization',
      name: 'Site Name',
      logo: {
        '@type': 'ImageObject',
        url: 'https://example.com/logo.png',
      },
    },
    mainEntityOfPage: {
      '@type': 'WebPage',
      '@id': `https://example.com/articles/${slug}`,
    },
  }

  return (
    <>
      <JsonLd data={jsonLd} />
      <article>{/* Content */}</article>
    </>
  )
}
```

### Product Schema

```typescript
import type { Product } from 'schema-dts'

const productJsonLd: WithContext<Product> = {
  '@context': 'https://schema.org',
  '@type': 'Product',
  name: product.name,
  description: product.description,
  image: product.images.map((img) => img.url),
  sku: product.sku,
  brand: {
    '@type': 'Brand',
    name: product.brandName,
  },
  offers: {
    '@type': 'Offer',
    url: `https://example.com/products/${product.slug}`,
    priceCurrency: 'USD',
    price: product.price,
    availability: product.inStock
      ? 'https://schema.org/InStock'
      : 'https://schema.org/OutOfStock',
    seller: {
      '@type': 'Organization',
      name: 'Site Name',
    },
  },
  aggregateRating: product.reviewCount > 0
    ? {
        '@type': 'AggregateRating',
        ratingValue: product.avgRating,
        reviewCount: product.reviewCount,
      }
    : undefined,
}
```

### Organization Schema

```typescript
import type { Organization } from 'schema-dts'

// app/layout.tsx - site-wide
const orgJsonLd: WithContext<Organization> = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: 'Company Name',
  url: 'https://example.com',
  logo: 'https://example.com/logo.png',
  sameAs: [
    'https://twitter.com/company',
    'https://github.com/company',
    'https://linkedin.com/company/company',
  ],
  contactPoint: {
    '@type': 'ContactPoint',
    contactType: 'customer service',
    email: 'support@example.com',
  },
}
```

### BreadcrumbList Schema

```typescript
import type { BreadcrumbList } from 'schema-dts'

function buildBreadcrumbJsonLd(
  items: Array<{ name: string; url: string }>
): WithContext<BreadcrumbList> {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: item.url,
    })),
  }
}

// Usage
const breadcrumbs = buildBreadcrumbJsonLd([
  { name: 'Home', url: 'https://example.com' },
  { name: 'Articles', url: 'https://example.com/articles' },
  { name: article.title, url: `https://example.com/articles/${article.slug}` },
])
```

---

## 7. Canonical URLs and hreflang (i18n)

### Root Layout Metadata

**File:** `src/app/layout.tsx`

```typescript
import type { Metadata } from 'next'

const baseUrl = 'https://example.com'

export const metadata: Metadata = {
  metadataBase: new URL(baseUrl),
  title: {
    default: 'Site Name',
    template: '%s | Site Name',
  },
  description: 'Default site description.',
  alternates: {
    canonical: '/',
    languages: {
      'en-US': '/en',
      'tr-TR': '/tr',
      'de-DE': '/de',
      'x-default': '/en',
    },
  },
}
```

### Dynamic hreflang Per Page

```typescript
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug, locale } = await params

  return {
    alternates: {
      canonical: `https://example.com/${locale}/articles/${slug}`,
      languages: {
        'en-US': `https://example.com/en/articles/${slug}`,
        'tr-TR': `https://example.com/tr/articles/${slug}`,
        'de-DE': `https://example.com/de/articles/${slug}`,
        'x-default': `https://example.com/en/articles/${slug}`,
      },
    },
  }
}
```

---

## 8. Performance Hints

**File:** `src/app/layout.tsx`

```typescript
export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        {/* DNS prefetch for external domains */}
        <link rel="dns-prefetch" href="//fonts.googleapis.com" />
        <link rel="dns-prefetch" href="//cdn.example.com" />

        {/* Preconnect for critical third-party origins */}
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link rel="preconnect" href="https://cdn.example.com" />

        {/* Preload critical fonts */}
        <link
          rel="preload"
          href="/fonts/Inter-Variable.woff2"
          as="font"
          type="font/woff2"
          crossOrigin="anonymous"
        />
      </head>
      <body>{children}</body>
    </html>
  )
}
```

---

## Common Patterns

### Metadata Helper

```typescript
// lib/seo/metadata.ts
import type { Metadata } from 'next'

const baseUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'https://example.com'

export function createMetadata({
  title,
  description,
  path,
  image,
  type = 'website',
  noIndex = false,
}: {
  title: string
  description: string
  path: string
  image?: string
  type?: 'website' | 'article'
  noIndex?: boolean
}): Metadata {
  const url = `${baseUrl}${path}`
  const ogImage = image ?? `${baseUrl}/api/og?title=${encodeURIComponent(title)}`

  return {
    title,
    description,
    ...(noIndex && { robots: { index: false, follow: false } }),
    alternates: { canonical: url },
    openGraph: {
      title,
      description,
      url,
      type,
      images: [{ url: ogImage, width: 1200, height: 630, alt: title }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [ogImage],
    },
  }
}

// Usage in any page:
export const metadata = createMetadata({
  title: 'Pricing',
  description: 'Simple, transparent pricing for every team.',
  path: '/pricing',
})
```

### noindex for Auth/Dashboard Pages

```typescript
// app/dashboard/layout.tsx
export const metadata: Metadata = {
  robots: {
    index: false,
    follow: false,
    noarchive: true,
    nosnippet: true,
  },
}
```

### Redirect Handling for SEO

```typescript
// next.config.ts
const nextConfig = {
  async redirects() {
    return [
      {
        source: '/blog/:slug',
        destination: '/articles/:slug',
        permanent: true, // 308 redirect
      },
      {
        source: '/old-page',
        destination: '/new-page',
        permanent: true,
      },
    ]
  },
}
```

---

## Checklist

```
[ ] metadataBase set in root layout
[ ] title.template set for consistent page titles
[ ] generateMetadata for all dynamic routes
[ ] OG images (1200x630) for key pages
[ ] sitemap.ts generates all public URLs
[ ] robots.ts blocks /api/, /admin/, /dashboard/
[ ] JSON-LD for Article, Product, or Organization as needed
[ ] BreadcrumbList on nested pages
[ ] Canonical URLs on every page
[ ] hreflang tags if project uses i18n
[ ] noindex on auth/dashboard/settings pages
[ ] dns-prefetch and preconnect for external origins
[ ] 301/308 redirects for renamed/moved pages
[ ] schema-dts package installed for typed JSON-LD
[ ] tsc --noEmit = 0 errors
```

---

## Dependencies

```bash
npm install schema-dts
```

## Red Flags (STOP)

| If You See | Fix |
|------------|-----|
| Hardcoded `og:image` URL without dynamic params | Use `next/og` ImageResponse |
| Missing `metadataBase` | Add to root layout |
| `robots: 'noindex'` on public pages | Remove or check intent |
| JSON-LD with hardcoded data | Pull from database |
| Sitemap missing dynamic routes | Query DB in `sitemap.ts` |
| No canonical on paginated pages | Add `alternates.canonical` |
| `dangerouslySetInnerHTML` without JSON.stringify | Sanitize via typed helper |
