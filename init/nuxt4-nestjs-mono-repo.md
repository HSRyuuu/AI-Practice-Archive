>### description
>pnpm workspace 기반의 Nuxt 4 및 NestJS 풀스택 모노레포 프로젝트 설정 가이드입니다. Post라는 엔티티를 임시로 세팅합니다. 
확실한 테스트를 위해 [2.Database Connection] 에 실제 커넥션 정보를 넣으세요.

# Project Goal: Setup Full-stack Monorepo with Post CRUD (Nuxt 4, NestJS, TypeORM, Nuxt UI)

## 1. Project Overview
- **Structure:** pnpm workspaces monorepo
  - `/packages/frontend` (Nuxt 4, Nuxt UI)
  - `/packages/backend` (NestJS, TypeORM)
  - `/packages/shared` (Common entities & types with workspace dependencies)
- **Database:** PostgreSQL (with provided credentials)

## 2. Database Connection
Configure the backend to connect to PostgreSQL using the following credentials:
- **Type:** postgres
- **Host:** localhost
- **Port:** 5432
- **Database:** cb
- **Username:** root
- **Password:** test
- **Synchronize:** true (for development)

## 3. Post Entity Requirements
Create a `Post` entity in the `shared` package with TypeScript interfaces:
- `id`: Primary Generated Column (number)
- `title`: String
- `content`: Text
- `createdAt` & `updatedAt`: Date (Timestamps)

Additional DTOs:
- `CreatePostDto`: `{ title: string; content: string; }`
- `UpdatePostDto`: `{ title?: string; content?: string; }`

## 4. Detailed Implementation Tasks

### [Shared Package: Type Definitions]
- Create `/packages/shared/src/entities/post.entity.ts` with:
  - `Post` interface
  - `CreatePostDto` interface
  - `UpdatePostDto` interface
- Export all types from `/packages/shared/src/index.ts`
- Configure `package.json` with TypeScript build script
- **Key Point:** This package provides type definitions only (no runtime code)

### [Backend: NestJS]
- Setup `TypeOrmModule.forRootAsync()` with ConfigService for PostgreSQL credentials
- Create a `PostsModule`, `PostsController`, and `PostsService`
- Create `PostEntity` class that **implements the `Post` interface from shared package**
- Use TypeORM decorators on `PostEntity` for database mapping
- Implement basic CRUD: `findAll()` and `create()`
- Enable Swagger at `/api/docs` to test the Post API
- **Critical Fix:** Set `tsconfig.json` `baseUrl` to `"./src"` (not `"./"`) to ensure NestJS builds output to `dist/` correctly
- Add `"shared": "workspace:*"` dependency in `package.json`
- Configure `tsconfig.json` paths: `"shared": ["../shared/src"]`

### [Frontend: Nuxt 4 & Nuxt UI]
- Use Nuxt 4 with `compatibilityVersion: 4` in `nuxt.config.ts`
- Use the `app/` directory structure (not `pages/` at root)
- Install `@nuxt/ui` module
- Configure Nitro dev proxy to forward `/api` requests to `http://localhost:3001`
- Create `app/app.vue` with `<UApp>` wrapper
- Create example composable `composables/usePosts.ts` using shared types
- **Type Safety:** Import types from shared package: `import type { Post, CreatePostDto } from 'shared'`
- Add `"shared": "workspace:*"` dependency in `package.json`
- Configure `tsconfig.json` to extend Nuxt's config and add shared paths

### [Workspace Configuration]
- Create `pnpm-workspace.yaml` with `packages: ['packages/*']`
- Root `package.json` scripts:
  - `"dev"`: Run both backend and frontend with concurrently
  - `"build:shared"`: Build shared package first
  - `"build:backend"`: Build shared then backend
  - `"build:frontend"`: Build shared then frontend
  - `"build"`: Build all packages in correct order
- **Build Strategy:** Shared types are bundled into each package during build, allowing independent deployment

### [Environment Setup]
- Create a `.env` file in `/packages/backend` with DB credentials
- Use `@nestjs/config` with `ConfigModule.forRoot()` for environment variables
- Set default values in `app.module.ts` for development convenience

## 5. Key Modifications from Initial Plan

### ✅ Shared Type Enforcement
- **Added:** Workspace dependencies (`"shared": "workspace:*"`) in both backend and frontend
- **Added:** TypeScript path mappings in both packages
- **Implementation:** Backend's `PostEntity` implements shared `Post` interface
- **Benefit:** Type consistency across packages, single source of truth

### ✅ Build Configuration
- **Fixed:** Backend `tsconfig.json` `baseUrl` changed from `"./"` to `"./src"`
- **Reason:** NestJS was building to `dist/backend/src/` instead of `dist/`, causing dev mode failures
- **Added:** Granular build scripts for proper dependency order (shared → backend/frontend)

### ✅ Frontend Structure
- **Used:** Nuxt 4 `app/` directory structure (not `pages/` at root)
- **Added:** Nitro dev proxy configuration for API forwarding
- **Created:** Example `usePosts` composable demonstrating shared type usage

### ✅ Development Workflow
- **Workspace Links:** pnpm creates symlinks in `node_modules/shared` → `../../shared`
- **Hot Reload:** Changes in shared package immediately reflect in backend/frontend
- **Independent Deployment:** Each package bundles shared types, no runtime dependency

## 6. Output
- Complete folder structure with all configuration files
- Ready-to-run with `pnpm install && pnpm dev`
- Assumes PostgreSQL database 'cb' exists
- Backend runs on port 3001, Frontend on port 3000
- Swagger documentation available at http://localhost:3001/api/docs

## 7. Project Structure
```
.
├── packages/
│   ├── backend/
│   │   ├── src/
│   │   │   ├── posts/
│   │   │   │   ├── post.entity.ts (implements shared Post)
│   │   │   │   ├── posts.controller.ts
│   │   │   │   ├── posts.service.ts
│   │   │   │   ├── posts.module.ts
│   │   │   │   └── dto/
│   │   │   ├── app.module.ts
│   │   │   └── main.ts
│   │   ├── package.json (with shared workspace dependency)
│   │   ├── tsconfig.json (baseUrl: "./src")
│   │   ├── nest-cli.json
│   │   └── .env
│   ├── frontend/
│   │   ├── app/
│   │   │   ├── app.vue
│   │   │   └── pages/
│   │   ├── composables/
│   │   │   └── usePosts.ts (uses shared types)
│   │   ├── package.json (with shared workspace dependency)
│   │   ├── tsconfig.json (with shared paths)
│   │   └── nuxt.config.ts
│   └── shared/
│       ├── src/
│       │   ├── entities/
│       │   │   └── post.entity.ts
│       │   └── index.ts
│       ├── package.json
│       └── tsconfig.json
├── package.json (root with build scripts)
├── pnpm-workspace.yaml
└── README.md
```