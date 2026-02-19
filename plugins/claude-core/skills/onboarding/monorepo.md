---
name: monorepo
description: Turborepo and pnpm workspace monorepo patterns
triggers:
  - monorepo
  - turborepo
  - workspace
  - pnpm workspace
---

# Monorepo with Turborepo

Patterns for monorepo setup with Turborepo and pnpm workspaces.

## 1. Project Structure

```
my-monorepo/
├── apps/
│   ├── web/              # Next.js app
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── mobile/           # Expo app
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── api/              # Standalone API
│       └── package.json
├── packages/
│   ├── ui/               # Shared UI components
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── db/               # Shared database (Drizzle)
│   │   ├── src/
│   │   └── package.json
│   ├── types/            # Shared TypeScript types
│   │   └── package.json
│   └── config-ts/        # Shared tsconfig
│       ├── base.json
│       ├── nextjs.json
│       └── package.json
├── turbo.json
├── pnpm-workspace.yaml
├── package.json
└── tsconfig.json
```

## 2. pnpm-workspace.yaml

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

## 3. Root package.json

```json
{
  "name": "my-monorepo",
  "private": true,
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "typecheck": "turbo typecheck",
    "clean": "turbo clean"
  },
  "devDependencies": {
    "turbo": "^2.0.0",
    "typescript": "^5.5.0"
  },
  "packageManager": "pnpm@9.0.0"
}
```

## 4. turbo.json

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "typecheck": {
      "dependsOn": ["^build"]
    },
    "clean": {
      "cache": false
    }
  }
}
```

## 5. Shared Package Example (packages/ui)

```json
{
  "name": "@repo/ui",
  "version": "0.0.0",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "build": "tsc",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^19.0.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "@repo/config-ts": "workspace:*"
  }
}
```

### Using Internal Packages

```json
{
  "name": "web",
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/db": "workspace:*",
    "@repo/types": "workspace:*"
  }
}
```

## 6. Shared TypeScript Config

```json
// packages/config-ts/base.json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

```json
// packages/config-ts/nextjs.json
{
  "extends": "./base.json",
  "compilerOptions": {
    "jsx": "preserve",
    "lib": ["dom", "dom.iterable", "esnext"],
    "module": "esnext",
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## 7. Workspace-Aware TypeScript

```bash
# Typecheck all packages
pnpm turbo typecheck

# Typecheck specific app
pnpm --filter web typecheck

# Build only what changed
pnpm turbo build --filter=...@repo/ui
```

## Commands

```bash
# Install deps
pnpm install

# Add dep to specific package
pnpm --filter web add react-query

# Add internal dep
pnpm --filter web add @repo/ui --workspace

# Run script in specific package
pnpm --filter web dev

# Run script in all packages
pnpm turbo dev
```

## Gotchas

| Issue | Solution |
|-------|----------|
| "Package not found" | Check workspace:* in deps, run pnpm install |
| Types not resolving | Ensure "main" and "types" in package.json point to source |
| Build order wrong | Use dependsOn: ["^build"] in turbo.json |
| Next.js transpile needed | Add transpilePackages in next.config.ts |
| Expo doesn't resolve workspace | Use expo-module-scripts or manual resolver |
