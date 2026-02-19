---
name: tailwind
description: Use when styling with Tailwind CSS. Utilities, responsive design, dark mode, custom config. Triggers on: tailwind, css, style, styling, responsive, dark mode, className, utility, tw.
version: 1.0.0
---

# Tailwind CSS Deep Knowledge

> Custom plugins, performance, themes, and advanced patterns.

---

## Quick Reference

```tsx
<div className="flex items-center justify-between p-4 bg-white rounded-lg shadow-md">
  <h1 className="text-xl font-bold text-gray-900">Title</h1>
  <button className="px-4 py-2 text-white bg-blue-500 rounded hover:bg-blue-600">
    Click
  </button>
</div>
```

---

## Configuration

### tailwind.config.ts

```typescript
import type { Config } from 'tailwindcss';
import defaultTheme from 'tailwindcss/defaultTheme';

const config: Config = {
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  
  darkMode: 'class', // or 'media'
  
  theme: {
    extend: {
      // Custom colors
      colors: {
        brand: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
        },
        // CSS variable colors
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
      },
      
      // Custom fonts
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
        display: ['Cal Sans', 'Inter var', 'sans-serif'],
        mono: ['JetBrains Mono', ...defaultTheme.fontFamily.mono],
      },
      
      // Custom spacing
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      
      // Custom animations
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'spin-slow': 'spin 3s linear infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
      
      // Custom screens
      screens: {
        'xs': '475px',
        '3xl': '1920px',
      },
      
      // Custom border radius
      borderRadius: {
        '4xl': '2rem',
        '5xl': '2.5rem',
      },
      
      // Custom box shadow
      boxShadow: {
        'inner-lg': 'inset 0 2px 4px 0 rgb(0 0 0 / 0.1)',
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
      },
    },
  },
  
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
    require('tailwindcss-animate'),
  ],
};

export default config;
```

---

## Custom Plugins

### Simple Plugin

```typescript
// plugins/custom-utilities.ts
import plugin from 'tailwindcss/plugin';

export const customUtilities = plugin(function ({ addUtilities }) {
  addUtilities({
    '.text-balance': {
      'text-wrap': 'balance',
    },
    '.scrollbar-hide': {
      '-ms-overflow-style': 'none',
      'scrollbar-width': 'none',
      '&::-webkit-scrollbar': {
        display: 'none',
      },
    },
    '.drag-none': {
      '-webkit-user-drag': 'none',
      'user-drag': 'none',
    },
  });
});
```

### Component Plugin

```typescript
// plugins/buttons.ts
import plugin from 'tailwindcss/plugin';

export const buttons = plugin(function ({ addComponents, theme }) {
  addComponents({
    '.btn': {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: theme('borderRadius.md'),
      fontWeight: theme('fontWeight.medium'),
      transition: 'all 150ms ease-in-out',
      '&:focus': {
        outline: 'none',
        ringWidth: '2px',
        ringColor: theme('colors.blue.500'),
        ringOffset: '2px',
      },
      '&:disabled': {
        opacity: '0.5',
        cursor: 'not-allowed',
      },
    },
    '.btn-sm': {
      padding: `${theme('spacing.1')} ${theme('spacing.3')}`,
      fontSize: theme('fontSize.sm'),
    },
    '.btn-md': {
      padding: `${theme('spacing.2')} ${theme('spacing.4')}`,
      fontSize: theme('fontSize.base'),
    },
    '.btn-lg': {
      padding: `${theme('spacing.3')} ${theme('spacing.6')}`,
      fontSize: theme('fontSize.lg'),
    },
    '.btn-primary': {
      backgroundColor: theme('colors.blue.500'),
      color: theme('colors.white'),
      '&:hover': {
        backgroundColor: theme('colors.blue.600'),
      },
    },
    '.btn-secondary': {
      backgroundColor: theme('colors.gray.200'),
      color: theme('colors.gray.900'),
      '&:hover': {
        backgroundColor: theme('colors.gray.300'),
      },
    },
  });
});
```

### Variant Plugin

```typescript
// plugins/variants.ts
import plugin from 'tailwindcss/plugin';

export const customVariants = plugin(function ({ addVariant }) {
  // State variants
  addVariant('hocus', ['&:hover', '&:focus']);
  addVariant('group-hocus', [':merge(.group):hover &', ':merge(.group):focus &']);
  
  // Data attribute variants
  addVariant('data-active', '&[data-active="true"]');
  addVariant('data-state-open', '&[data-state="open"]');
  
  // Parent state variants
  addVariant('parent-hover', '.parent:hover > &');
  
  // Sibling variants
  addVariant('peer-invalid', '.peer:invalid ~ &');
});
```

---

## Performance Optimization

### Safelist (Dynamic Classes)

```typescript
// tailwind.config.ts
module.exports = {
  safelist: [
    // Specific classes
    'bg-red-500',
    'text-xl',
    
    // Pattern matching
    {
      pattern: /bg-(red|green|blue)-(100|500|700)/,
    },
    {
      pattern: /text-(sm|base|lg|xl)/,
      variants: ['hover', 'md'],
    },
  ],
};
```

### Content Configuration

```typescript
// Precise content paths for faster builds
content: [
  './src/app/**/*.{tsx,ts}',
  './src/components/**/*.{tsx,ts}',
  // Exclude test files
  '!./src/**/*.test.{tsx,ts}',
  '!./src/**/*.spec.{tsx,ts}',
];
```

### Class Composition with cn()

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Usage
<div className={cn(
  'base-classes',
  isActive && 'active-classes',
  className // Allow override
)} />
```

---

## Design System with CSS Variables

### CSS Variables

```css
/* globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 48%;
  }
}
```

---

## Responsive Patterns

### Container Queries

```tsx
// Requires @tailwindcss/container-queries plugin
<div className="@container">
  <div className="@md:flex @md:gap-4">
    <div className="@md:w-1/2">Sidebar</div>
    <div className="@md:w-1/2">Content</div>
  </div>
</div>
```

### Fluid Typography

```css
/* Custom clamp for fluid sizing */
.text-fluid-lg {
  font-size: clamp(1.25rem, 2vw + 0.5rem, 2rem);
}

/* In Tailwind config */
fontSize: {
  'fluid-sm': 'clamp(0.875rem, 1.5vw, 1rem)',
  'fluid-base': 'clamp(1rem, 2vw, 1.25rem)',
  'fluid-lg': 'clamp(1.25rem, 2.5vw, 1.5rem)',
  'fluid-xl': 'clamp(1.5rem, 3vw, 2rem)',
}
```

---

## Animation Patterns

### Entrance Animations

```tsx
<div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
  Content
</div>

<div className="animate-in zoom-in-50 duration-300 delay-150">
  Delayed zoom
</div>
```

### Hover Effects

```tsx
// Scale on hover
<div className="transition-transform hover:scale-105">
  Card
</div>

// Lift on hover
<div className="transition-all hover:-translate-y-1 hover:shadow-lg">
  Card
</div>

// Glow effect
<div className="transition-shadow hover:shadow-[0_0_20px_rgba(59,130,246,0.5)]">
  Glow
</div>
```

### Loading States

```tsx
// Skeleton
<div className="animate-pulse">
  <div className="h-4 bg-gray-200 rounded w-3/4" />
  <div className="h-4 bg-gray-200 rounded w-1/2 mt-2" />
</div>

// Spinner
<div className="animate-spin h-5 w-5 border-2 border-current border-t-transparent rounded-full" />

// Shimmer
<div className="relative overflow-hidden bg-gray-200">
  <div className="absolute inset-0 -translate-x-full animate-[shimmer_2s_infinite] bg-gradient-to-r from-transparent via-white/60 to-transparent" />
</div>
```

---

## Common Patterns

### Glass Effect

```tsx
<div className="backdrop-blur-md bg-white/30 border border-white/20 shadow-lg">
  Glassmorphism
</div>
```

### Gradient Text

```tsx
<h1 className="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
  Gradient Text
</h1>
```

### Truncation

```tsx
// Single line
<p className="truncate">Long text...</p>

// Multi-line (line-clamp)
<p className="line-clamp-3">Long text that wraps to multiple lines...</p>
```

### Focus Ring

```tsx
<button className="focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
  Button
</button>

// With focus-visible (only keyboard)
<button className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2">
  Button
</button>
```
