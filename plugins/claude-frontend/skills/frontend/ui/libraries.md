---
name: ui-libraries
description: Use when choosing or integrating UI component libraries. Comparison and integration patterns. Triggers on: ui library, component library, ui components, which ui, radix, headless.
version: 1.0.0
---

# UI Component Libraries (2026)

> **Priority:** RECOMMENDED | **Auto-Load:** On UI/component work
> **Triggers:** ui library, components, aceternity, magic ui, animata, shadcn, preline, hyperui, kokonut, origin ui, cult ui, prompt kit, tweakcn

---

## 🎨 DESIGN DIFFERENTIATION PRINCIPLE

> **Anti-AI Slop Rule**: Every project needs a BOLD aesthetic direction.
> Generic = forgettable. Choose a distinctive visual identity.

### Before Starting ANY UI Work:
1. Pick ONE primary aesthetic (see Design Directions below)
2. Choose 2-3 accent libraries for effects
3. Document in CRITICAL_NOTES.md
4. Stay consistent throughout project

---

## Library Overview

### Tier 1: Foundation Libraries

| Library | Count | Focus | Best For |
|---------|-------|-------|----------|
| **[shadcn/ui](https://ui.shadcn.com)** | 50+ | Accessible, customizable primitives | Production apps, design systems |
| **[Radix UI](https://radix-ui.com)** | 30+ | Unstyled, accessible primitives | Custom design systems |
| **[tweakcn](https://tweakcn.com)** | - | shadcn theme customizer | Visual theme editor |

### Tier 2: Animated Component Libraries

| Library | Count | Focus | Best For |
|---------|-------|-------|----------|
| **[Aceternity UI](https://ui.aceternity.com)** | 200+ | 3D cards, spotlights, meteors, text effects | Landing pages, hero sections |
| **[Magic UI](https://magicui.design)** | 150+ | Shimmer, gradients, particles, borders | Visual effects, CTAs |
| **[Animata](https://animata.design)** | 80+ | Text animations, cards, backgrounds | Micro-interactions |
| **[Motion Primitives](https://motion-primitives.com)** | 50+ | Text effects, dialogs, image grids | Open-source animations |
| **[Cult UI](https://cult-ui.com)** | 30+ | AI integrations, shadcn-compatible | AI-powered apps |

### Tier 3: Tailwind UI Kits

| Library | Count | Framework | Best For |
|---------|-------|-----------|----------|
| **[Preline](https://preline.co)** | 640+ | HTML/React/Vue | Enterprise, dashboards |
| **[HyperUI](https://hyperui.dev)** | 400+ | Tailwind v4 | Marketing, neobrutalism |
| **[Float UI](https://floatui.com)** | 200+ | React/Vue/Svelte | Clean, minimal sites |
| **[KokonutUI](https://kokonutui.com)** | 100+ | React/Next.js | Modern web apps |
| **[Origin UI](https://originui-ng.com)** | 180+ | React/Angular | Forms, inputs |
| **[StyleUI](https://styleui.net)** | - | Figma/SVG | Design-first projects |

### Tier 4: Specialized

| Library | Focus | Best For |
|---------|-------|----------|
| **[Prompt Kit](https://prompt-kit.com)** | AI/Chat UI components | AI apps, chatbots |
| **[UIverse](https://uiverse.io)** | Community CSS elements | Unique buttons, cards |
| **[Framer Marketplace](https://framer.com/marketplace)** | Templates, plugins | Inspiration, rapid prototyping |

---

## Design Directions (Pick ONE)

### 1. Neobrutalism
Bold borders, harsh shadows, bright colors.
```typescript
// Libraries: HyperUI Neobrutalism, UIverse
className="border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]
           bg-yellow-400 hover:translate-x-1 hover:translate-y-1
           hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
```

### 2. Glassmorphism
Frosted glass, blur effects, subtle borders.
```typescript
// Libraries: Aceternity, Magic UI
className="bg-white/10 backdrop-blur-xl border border-white/20
           rounded-2xl shadow-xl"
```

### 3. Dark Futuristic
Gradient glows, neon accents, deep blacks.
```typescript
// Libraries: Aceternity, Magic UI, Motion Primitives
className="bg-black border border-cyan-500/30 rounded-lg
           shadow-[0_0_30px_rgba(34,211,238,0.2)]"
```

### 4. Minimal Elegant
Lots of whitespace, subtle shadows, refined typography.
```typescript
// Libraries: shadcn, Float UI, Origin UI
className="bg-white rounded-xl shadow-sm border border-gray-100
           hover:shadow-md transition-shadow"
```

### 5. Playful Colorful
Rounded shapes, gradients, bouncy animations.
```typescript
// Libraries: Animata, KokonutUI
className="bg-gradient-to-br from-pink-500 to-orange-400
           rounded-3xl shadow-lg hover:scale-105 transition-transform"
```

### 6. Corporate Professional
Clean lines, neutral colors, data-focused.
```typescript
// Libraries: Preline, shadcn
className="bg-slate-50 border border-slate-200 rounded-lg
           shadow-sm hover:border-slate-300"
```

---

## shadcn/ui Best Practices

### Project Structure (Three-Layer Architecture)

```
/components
  /ui           # shadcn primitives (DO NOT EDIT)
    button.tsx
    card.tsx
    dialog.tsx
    ...
  /layout       # Layout components
    navbar.tsx
    footer.tsx
    sidebar.tsx
  /forms        # Form-specific components
    login-form.tsx
    signup-form.tsx
  /sections     # Page sections (business logic + UI)
    hero-section.tsx
    pricing-section.tsx
  /shared       # General reusable components
    user-avatar.tsx
    loading-spinner.tsx
```

### Layer Responsibilities

| Layer | Purpose | Example |
|-------|---------|---------|
| **Abstract (ui/)** | shadcn primitives | `<Button />`, `<Card />` |
| **Section** | Business logic + composition | `<PricingSection plans={plans} />` |
| **Page** | Layout structure only | `<HomePage />` with section composition |

### Installation & Configuration

```bash
# Initialize shadcn in project
npx shadcn@latest init

# Add components as needed
npx shadcn@latest add button card dialog

# shadcn/create for new projects (2026)
npx create@shadcn/ui my-app
# Options: primitives (Radix/Base UI), styles (Vega/Nova/Maia), icons (Lucide/Tabler/HugeIcons)
```

### Customization Pattern

```typescript
// components/ui/button.tsx - Keep shadcn original
import { Button } from "@/components/ui/button";

// components/shared/primary-button.tsx - Create variants
import { Button, ButtonProps } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function PrimaryButton({ className, ...props }: ButtonProps) {
  return (
    <Button
      className={cn("bg-brand-500 hover:bg-brand-600", className)}
      {...props}
    />
  );
}
```

---

## Aceternity UI Patterns

### 3D Card Effect

```typescript
import { CardContainer, CardBody, CardItem } from "@/components/ui/3d-card";

export function Product3DCard({ product }) {
  return (
    <CardContainer className="inter-var">
      <CardBody className="bg-gray-50 relative group/card dark:bg-black dark:border-white/[0.2] border-black/[0.1] w-auto sm:w-[30rem] h-auto rounded-xl p-6 border">
        <CardItem
          translateZ="50"
          className="text-xl font-bold text-neutral-600 dark:text-white"
        >
          {product.name}
        </CardItem>
        <CardItem
          as="p"
          translateZ="60"
          className="text-neutral-500 text-sm max-w-sm mt-2 dark:text-neutral-300"
        >
          {product.description}
        </CardItem>
        <CardItem translateZ="100" className="w-full mt-4">
          <Image
            src={product.image}
            height="1000"
            width="1000"
            className="h-60 w-full object-cover rounded-xl group-hover/card:shadow-xl"
            alt={product.name}
          />
        </CardItem>
        <div className="flex justify-between items-center mt-20">
          <CardItem
            translateZ={20}
            as="button"
            className="px-4 py-2 rounded-xl bg-black dark:bg-white dark:text-black text-white text-xs font-bold"
          >
            Add to cart
          </CardItem>
          <CardItem
            translateZ={20}
            as="button"
            className="px-4 py-2 rounded-xl text-xs font-normal dark:text-white"
          >
            ${product.price}
          </CardItem>
        </div>
      </CardBody>
    </CardContainer>
  );
}
```

### Background Effects

```typescript
// Animated gradient background
import { BackgroundGradient } from "@/components/ui/background-gradient";

<BackgroundGradient className="rounded-[22px] max-w-sm p-4 sm:p-10 bg-white dark:bg-zinc-900">
  <Image src="/product.png" alt="Product" />
  <p className="text-base">Product Description</p>
</BackgroundGradient>

// Spotlight effect
import { Spotlight } from "@/components/ui/spotlight";

<div className="relative">
  <Spotlight className="-top-40 left-0 md:left-60 md:-top-20" fill="white" />
  <h1>Hero Content</h1>
</div>
```

---

## Magic UI Patterns

### Shimmer Effect

```typescript
import { ShimmerButton } from "@/components/magicui/shimmer-button";

<ShimmerButton className="shadow-2xl">
  <span className="whitespace-pre-wrap text-center text-sm font-medium leading-none tracking-tight text-white dark:from-white dark:to-slate-900/10 lg:text-lg">
    Get Started
  </span>
</ShimmerButton>
```

### Meteor Effect

```typescript
import { Meteors } from "@/components/magicui/meteors";

<div className="relative h-full w-full">
  <Meteors number={20} />
  <h1>Hero Content</h1>
</div>
```

### Animated Border

```typescript
import { AnimatedBorder } from "@/components/magicui/animated-border";

<AnimatedBorder>
  <div className="p-4 bg-slate-900 rounded-lg">
    Card content with animated gradient border
  </div>
</AnimatedBorder>
```

---

## Animata Micro-interactions

### Button States

```typescript
import { ScaleButton } from "@/components/animata/scale-button";

<ScaleButton>
  Click me
</ScaleButton>

// Ripple effect button
import { RippleButton } from "@/components/animata/ripple-button";

<RippleButton color="rgba(255, 255, 255, 0.3)">
  Click with ripple
</RippleButton>
```

### Loading States

```typescript
import { PulseLoader } from "@/components/animata/pulse-loader";
import { SkeletonCard } from "@/components/animata/skeleton-card";

// Pulse dots
<PulseLoader />

// Skeleton loading
<SkeletonCard />
```

---

## When to Use What

| Need | Primary | Secondary | Accent |
|------|---------|-----------|--------|
| **Production SaaS** | shadcn/ui | Preline | Motion Primitives |
| **AI/Chat app** | Prompt Kit | shadcn/ui | Animata |
| **Landing page (wow)** | Aceternity | Magic UI | Motion Primitives |
| **Enterprise dashboard** | Preline | shadcn/ui | - |
| **Form-heavy app** | Origin UI | shadcn/ui | Animata |
| **Marketing site** | HyperUI | Aceternity | Magic UI |
| **E-commerce** | KokonutUI | shadcn/ui | Animata |
| **Creative portfolio** | Cult UI | Aceternity | Framer Motion |
| **Rapid prototype** | Float UI | HyperUI | - |
| **Design system** | Radix UI | shadcn/ui | - |

---

## tweakcn - Visual Theme Customizer

Interactive shadcn theme editor with real-time preview.

```bash
# Use online: https://tweakcn.com
# 1. Adjust colors, radius, spacing visually
# 2. Export CSS variables
# 3. Paste into globals.css
```

### Generated CSS Example
```css
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --primary: 262.1 83.3% 57.8%;
    --primary-foreground: 210 20% 98%;
    --radius: 0.75rem;
  }
}
```

---

## Prompt Kit - AI/Chat UI

Pre-built components for AI applications.

```typescript
import { ChatBubble, TypingIndicator, MessageList } from "@prompt-kit/react";

// AI Chat Interface
<MessageList>
  <ChatBubble role="user">Hello!</ChatBubble>
  <ChatBubble role="assistant">
    <TypingIndicator />
  </ChatBubble>
</MessageList>

// Streaming response
<ChatBubble role="assistant" streaming>
  {streamedText}
</ChatBubble>
```

---

## KokonutUI Patterns

Modern React/Next.js components with motion.

```typescript
// Hero with gradient text
import { GradientText, AnimatedButton } from "@kokonut/ui";

<h1>
  <GradientText from="blue" to="purple">
    Build Something Amazing
  </GradientText>
</h1>

<AnimatedButton variant="glow" size="lg">
  Get Started
</AnimatedButton>
```

---

## Cult UI - AI-Ready Components

shadcn-compatible with AI integrations.

```typescript
// AI Agent UI
import { AgentCard, ToolCall, StreamingText } from "@cult-ui/react";

<AgentCard
  name="Research Agent"
  status="thinking"
  tools={["web-search", "file-read"]}
>
  <ToolCall tool="web-search" input="latest news" />
  <StreamingText>{response}</StreamingText>
</AgentCard>
```

---

## Integration Checklist

### Before Adding New UI Library

- [ ] Check if shadcn/ui already has the component
- [ ] Verify library is actively maintained (check GitHub)
- [ ] Check bundle size impact (`bundlephobia.com`)
- [ ] Ensure accessibility compliance (WCAG 2.2 AA)
- [ ] Verify Tailwind compatibility
- [ ] Check for TypeScript support

### Component Integration

```typescript
// 1. Copy component to your project (don't npm install)
// 2. Place in appropriate directory
// 3. Update imports to match your project structure
// 4. Add TypeScript types if missing
// 5. Test accessibility (keyboard navigation, screen reader)
// 6. Verify responsive behavior
```

---

## Performance Considerations

```typescript
// Lazy load heavy animation components
const HeavyAnimatedComponent = dynamic(
  () => import("@/components/ui/3d-card"),
  {
    ssr: false,
    loading: () => <Skeleton className="h-[400px] w-full" />
  }
);

// Conditional loading based on device capability
const shouldLoadAnimations = !navigator.connection?.saveData;

// Intersection Observer for below-fold animations
import { useInView } from "framer-motion";

function AnimatedSection({ children }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });

  return (
    <div ref={ref}>
      {isInView && children}
    </div>
  );
}
```

---

## Common Patterns

### Hero Section with Effects

```typescript
import { Spotlight } from "@/components/aceternity/spotlight";
import { TypewriterEffect } from "@/components/aceternity/typewriter-effect";
import { ShimmerButton } from "@/components/magicui/shimmer-button";

export function HeroSection() {
  const words = [
    { text: "Build" },
    { text: "awesome" },
    { text: "apps" },
    { text: "with", className: "text-blue-500 dark:text-blue-500" },
    { text: "AI.", className: "text-blue-500 dark:text-blue-500" },
  ];

  return (
    <div className="relative min-h-screen flex flex-col items-center justify-center">
      <Spotlight className="-top-40 left-0 md:left-60 md:-top-20" fill="blue" />
      <TypewriterEffect words={words} />
      <ShimmerButton className="mt-8">
        Get Started
      </ShimmerButton>
    </div>
  );
}
```

### Feature Grid with Cards

```typescript
import { BentoGrid, BentoGridItem } from "@/components/aceternity/bento-grid";
import { BackgroundGradient } from "@/components/aceternity/background-gradient";

export function FeaturesGrid({ features }) {
  return (
    <BentoGrid className="max-w-4xl mx-auto">
      {features.map((feature, i) => (
        <BentoGridItem
          key={i}
          title={feature.title}
          description={feature.description}
          header={
            <BackgroundGradient className="rounded-xl">
              <feature.icon className="h-8 w-8" />
            </BackgroundGradient>
          }
          className={i === 3 || i === 6 ? "md:col-span-2" : ""}
        />
      ))}
    </BentoGrid>
  );
}
```

---

## Resources

### Foundation
- [shadcn/ui](https://ui.shadcn.com/docs) - 50+ accessible components
- [Radix UI](https://radix-ui.com) - Unstyled primitives
- [tweakcn](https://tweakcn.com) - Visual theme editor

### Animated Components
- [Aceternity UI](https://ui.aceternity.com/components) - 200+ animated
- [Magic UI](https://magicui.design/docs) - 150+ effects
- [Animata](https://animata.design/docs) - 80+ micro-interactions
- [Motion Primitives](https://motion-primitives.com) - Animation toolkit
- [Cult UI](https://cult-ui.com) - AI-ready components

### Tailwind Kits
- [Preline](https://preline.co/docs) - 640+ enterprise components
- [HyperUI](https://hyperui.dev) - 400+ marketing/neobrutalism
- [Float UI](https://floatui.com) - Clean, minimal
- [KokonutUI](https://kokonutui.com) - Modern React
- [Origin UI](https://originui-ng.com) - Form-focused

### Specialized
- [Prompt Kit](https://prompt-kit.com) - AI/Chat UI
- [UIverse](https://uiverse.io) - Community elements
- [StyleUI](https://styleui.net) - Figma-first
- [Framer Marketplace](https://framer.com/marketplace) - Templates

### Icons (See icon-systems skill)
- [Phosphor](https://phosphoricons.com) - 9,000+ flexible icons
- [HugeIcons](https://hugeicons.com) - 46,000+ icons
- [Lucide](https://lucide.dev) - shadcn default

---

## Web Interface Guidelines (Vercel Standards)

### Purpose
Automated compliance checking against Vercel's Web Interface Guidelines for accessibility, performance, and best practices.

### Guidelines Source
Fetch fresh guidelines before each review:
```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

### How It Works
1. Fetch the latest guidelines from source URL
2. Read specified files (or prompt user for files/pattern)
3. Check against all rules in the fetched guidelines
4. Output findings in terse `file:line` format

### Key Guidelines Enforced
- **Accessibility**: WCAG 2.2 AA compliance, semantic HTML, ARIA labels
- **Performance**: Core Web Vitals, lazy loading, image optimization
- **Responsive Design**: Mobile-first approach, flexible layouts
- **Progressive Enhancement**: Works without JavaScript
- **Security**: Secure headers, CSP, HTTPS enforcement

### Usage
When implementing UI components, automatically check against these guidelines:
- Semantic HTML structure
- Proper heading hierarchy (h1 → h6)
- Alt text for images
- Form labels and validation
- Keyboard navigation support
- Color contrast ratios (4.5:1 minimum)
- Touch target sizes (44x44px minimum)

### Auto-Apply During Development
Frontend agent automatically applies these standards when creating components. No manual invocation needed.

