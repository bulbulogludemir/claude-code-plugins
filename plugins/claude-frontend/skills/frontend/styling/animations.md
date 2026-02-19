---
name: framer-motion
description: Use when adding animations, transitions, or motion to UI. Variants, gestures, layout animations. Triggers on: animation, animate, framer, motion, transition, gesture, hover, tap, drag, layout animation.
version: 1.0.0
detect: ["framer-motion"]
---

# Framer Motion

Production-ready animations for React applications.

## Basic Animations

```tsx
import { motion } from 'framer-motion'

// Animate on mount
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.5 }}
>
  Content
</motion.div>

// Animate on hover/tap
<motion.button
  whileHover={{ scale: 1.05 }}
  whileTap={{ scale: 0.95 }}
>
  Click me
</motion.button>
```

## Variants

```tsx
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
    },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
}

function List({ items }) {
  return (
    <motion.ul
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {items.map(item => (
        <motion.li key={item.id} variants={itemVariants}>
          {item.name}
        </motion.li>
      ))}
    </motion.ul>
  )
}
```

## Page Transitions

```tsx
// In layout or page wrapper
import { AnimatePresence, motion } from 'framer-motion'
import { usePathname } from 'next/navigation'

function PageTransition({ children }) {
  const pathname = usePathname()
  
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        exit={{ opacity: 0, x: 20 }}
        transition={{ duration: 0.3 }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  )
}
```

## Scroll Animations

```tsx
import { motion, useScroll, useTransform } from 'framer-motion'

function ParallaxSection() {
  const { scrollYProgress } = useScroll()
  const y = useTransform(scrollYProgress, [0, 1], [0, -100])
  
  return (
    <motion.div style={{ y }}>
      Parallax content
    </motion.div>
  )
}

// Animate when in view
<motion.div
  initial={{ opacity: 0, y: 50 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-100px" }}
  transition={{ duration: 0.6 }}
>
  Appears on scroll
</motion.div>
```

## Gestures

```tsx
// Drag
<motion.div
  drag
  dragConstraints={{ left: -100, right: 100, top: -100, bottom: 100 }}
  dragElastic={0.2}
>
  Drag me
</motion.div>

// Drag to dismiss
<motion.div
  drag="x"
  dragConstraints={{ left: 0, right: 0 }}
  onDragEnd={(_, info) => {
    if (Math.abs(info.offset.x) > 100) {
      onDismiss()
    }
  }}
>
  Swipe to dismiss
</motion.div>
```

## Layout Animations

```tsx
// Automatic layout animation
<motion.div layout>
  {isExpanded ? <FullContent /> : <Preview />}
</motion.div>

// Shared layout animation
<motion.div layoutId="shared-element">
  <Card />
</motion.div>

// In another component with same layoutId
<motion.div layoutId="shared-element">
  <ExpandedCard />
</motion.div>
```

## Exit Animations

```tsx
import { AnimatePresence, motion } from 'framer-motion'

function Modal({ isOpen, onClose, children }) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          <motion.div
            className="modal"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            {children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
```

## Reusable Components

```tsx
// Fade in component
export function FadeIn({ 
  children, 
  delay = 0,
  duration = 0.5,
  className 
}: {
  children: React.ReactNode
  delay?: number
  duration?: number
  className?: string
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Stagger children
export function StaggerChildren({
  children,
  staggerDelay = 0.1,
}: {
  children: React.ReactNode
  staggerDelay?: number
}) {
  return (
    <motion.div
      initial="hidden"
      animate="visible"
      variants={{
        visible: {
          transition: {
            staggerChildren: staggerDelay,
          },
        },
      }}
    >
      {children}
    </motion.div>
  )
}
```

## Reduced Motion

```tsx
// Respect user preference
import { useReducedMotion } from 'framer-motion'

function AnimatedComponent() {
  const shouldReduceMotion = useReducedMotion()
  
  return (
    <motion.div
      initial={{ opacity: 0, y: shouldReduceMotion ? 0 : 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: shouldReduceMotion ? 0 : 0.5 }}
    >
      Content
    </motion.div>
  )
}
```
