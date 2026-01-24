---
name: nestjs-dev
description: Nest.js 백엔드 개발 가이드. Nest.js 프로젝트 생성, 모듈/컨트롤러/서비스 구현, 의존성 주입 패턴 적용 시 사용. (1) Nest.js 프로젝트 초기화, (2) 모듈 구조 설계, (3) REST API 엔드포인트 구현, (4) 서비스 레이어 작성, (5) DTO/Validation 설정 시 활성화.
---

# Nest.js Development Guide

## 프로젝트 구조 (레이어별)

```
src/
├── app.module.ts              # 루트 모듈
├── main.ts                    # 진입점
├── controllers/               # 컨트롤러 (HTTP 요청/응답)
│   ├── project.controller.ts
│   ├── task.controller.ts
│   └── planning.controller.ts
├── services/                  # 서비스 (비즈니스 로직)
│   ├── project.service.ts
│   ├── task.service.ts
│   └── planning.service.ts
├── dto/                       # DTO (입력 검증)
│   ├── project/
│   │   ├── create-project.dto.ts
│   │   └── update-project.dto.ts
│   ├── task/
│   └── planning/
├── modules/                   # 모듈 정의
│   ├── project.module.ts
│   ├── task.module.ts
│   └── planning.module.ts
├── types/                     # 타입/인터페이스 정의
│   ├── project.types.ts
│   └── task.types.ts
└── common/                    # 공통 유틸
    ├── filters/               # Exception filters
    ├── interceptors/          # Logging, Transform
    └── pipes/                 # Validation pipes
```

## 핵심 패턴

### 모듈 정의 (modules/project.module.ts)

```typescript
import { Module } from '@nestjs/common';
import { ProjectController } from '../controllers/project.controller';
import { ProjectService } from '../services/project.service';

@Module({
  imports: [],
  controllers: [ProjectController],
  providers: [ProjectService],
  exports: [ProjectService],  // 다른 모듈에서 사용 시
})
export class ProjectModule {}
```

### 컨트롤러 (controllers/project.controller.ts)

```typescript
import { Controller, Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { ProjectService } from '../services/project.service';
import { CreateProjectDto } from '../dto/project/create-project.dto';
import { UpdateProjectDto } from '../dto/project/update-project.dto';

@Controller('projects')
export class ProjectController {
  constructor(private readonly projectService: ProjectService) {}

  @Get()
  findAll() {
    return this.projectService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.projectService.findOne(id);
  }

  @Post()
  create(@Body() dto: CreateProjectDto) {
    return this.projectService.create(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateProjectDto) {
    return this.projectService.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.projectService.remove(id);
  }
}
```

### 서비스 (services/project.service.ts)

```typescript
import { Injectable } from '@nestjs/common';
import { CreateProjectDto } from '../dto/project/create-project.dto';
import { UpdateProjectDto } from '../dto/project/update-project.dto';

@Injectable()
export class ProjectService {
  findAll() { /* ... */ }
  findOne(id: string) { /* ... */ }
  create(dto: CreateProjectDto) { /* ... */ }
  update(id: string, dto: UpdateProjectDto) { /* ... */ }
  remove(id: string) { /* ... */ }
}
```

### DTO (dto/project/create-project.dto.ts)

```typescript
import { IsString, IsOptional } from 'class-validator';

export class CreateProjectDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  path?: string;
}
```

### DTO (dto/project/update-project.dto.ts)

```typescript
import { PartialType } from '@nestjs/mapped-types';
import { CreateProjectDto } from './create-project.dto';

export class UpdateProjectDto extends PartialType(CreateProjectDto) {}
```

## main.ts 설정

```typescript
async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // CORS
  app.enableCors();

  // Global prefix
  app.setGlobalPrefix('api');

  // Validation pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
  }));

  await app.listen(3000);
}
bootstrap();
```

## 규칙

1. **모듈 단위 구성**: 기능별로 모듈 분리
2. **의존성 주입**: 생성자 주입 사용, `@Injectable()` 데코레이터 필수
3. **DTO 사용**: 입력 검증은 class-validator + ValidationPipe
4. **서비스 레이어**: 비즈니스 로직은 서비스에 집중
5. **컨트롤러**: HTTP 요청/응답 처리만 담당
