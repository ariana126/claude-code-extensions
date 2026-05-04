---
name: nestjs-guideline
description: >
  Guide for building NestJS backend applications with best practices for
  project structure, modules, services, controllers, DTOs, guards, pipes,
  interceptors, testing, and database integration. Use this skill whenever
  the user wants to create a NestJS project, add a new module or feature
  to an existing NestJS app, scaffold CRUD endpoints, set up authentication
  or authorization, integrate an ORM (Prisma, TypeORM, Drizzle, MikroORM),
  write NestJS unit or e2e tests, configure middleware or interceptors,
  build microservices or WebSocket gateways, or apply NestJS architectural
  patterns. Also trigger when the user mentions "Nest", "NestJS", "@nestjs",
  "nest new", "nest generate", decorators like @Controller, @Injectable,
  @Module, @Guard, or concepts like NestJS providers, pipes, exception
  filters, or dynamic modules — even if they don't explicitly say "NestJS"
  but are clearly working in a Nest codebase.
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
  sources:
    - https://docs.nestjs.com
    - https://github.com/nestjs/nest
---

# NestJS Guideline

A skill for building well-structured, production-grade NestJS applications.

## Project bootstrapping

Use the Nest CLI to scaffold new projects and generate resources. It enforces
consistent naming and structure from the start:

```bash
# Install CLI globally
npm install -g @nestjs/cli

# Create a new project (choose your package manager when prompted)
nest new my-app

# Generate a full CRUD resource (module + controller + service + DTOs + tests)
nest generate resource users
```

When generating a resource, choose REST or GraphQL depending on your API style.
The CLI creates a module with controller, service, DTOs, and spec files already
wired together — don't create these files manually.

## Project structure

Organize by **domain module**, not by technical layer. Each module encapsulates
its own controller(s), service(s), DTOs, entities/models, and guards:

```
src/
├── main.ts                      # Bootstrap, global pipes/filters/interceptors
├── app.module.ts                # Root module — imports all feature modules
├── common/                      # Cross-cutting concerns (shared across modules)
│   ├── decorators/              # Custom decorators (@CurrentUser, @Public, etc.)
│   ├── filters/                 # Exception filters (AllExceptionsFilter)
│   ├── guards/                  # Auth guards (JwtAuthGuard, RolesGuard)
│   ├── interceptors/            # Logging, transform, timeout interceptors
│   ├── pipes/                   # Custom validation pipes
│   └── dto/                     # Shared DTOs (PaginationDto, etc.)
├── config/                      # Configuration module (@nestjs/config)
│   ├── config.module.ts
│   ├── app.config.ts
│   └── database.config.ts
├── database/                    # Database module (ORM setup, migrations)
│   ├── database.module.ts
│   ├── prisma.service.ts        # (if Prisma) or typeorm data-source config
│   └── migrations/
├── users/                       # Feature module example
│   ├── users.module.ts
│   ├── users.controller.ts
│   ├── users.service.ts
│   ├── dto/
│   │   ├── create-user.dto.ts
│   │   └── update-user.dto.ts
│   ├── entities/
│   │   └── user.entity.ts       # TypeORM entity / Prisma model reference
│   └── users.service.spec.ts
└── auth/                        # Auth module
    ├── auth.module.ts
    ├── auth.controller.ts
    ├── auth.service.ts
    ├── strategies/
    │   ├── jwt.strategy.ts
    │   └── local.strategy.ts
    └── guards/
        └── jwt-auth.guard.ts
```

The `common/` directory holds things used across multiple modules. Feature-specific
guards, interceptors, or pipes live inside their own module directory.

## Module design

Every feature is a module. Modules declare what they own and what they export:

```typescript
@Module({
  imports: [DatabaseModule, ConfigModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],  // Only export if other modules need it
})
export class UsersModule {}
```

**Key rules:**
- Only export providers that other modules genuinely depend on — not everything.
- Use `forRoot()` / `forRootAsync()` for modules that need one-time global config
  (database, config, auth). Use `forFeature()` for per-module registration (e.g.,
  TypeORM repositories).
- Avoid circular dependencies. If module A needs module B and vice versa, extract
  the shared logic into a third module or use `forwardRef()` as a last resort.
  The need for `forwardRef()` usually signals a design problem.

## Controllers

Controllers handle HTTP concerns only — request parsing, response shaping, and
status codes. Business logic belongs in services.

```typescript
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.findOne(id);
  }
}
```

- Use built-in pipes (`ParseIntPipe`, `ParseUUIDPipe`, `ParseBoolPipe`) for
  param coercion — don't manually parseInt in controller methods.
- Use `@HttpCode()` to set non-200 status codes (POST defaults to 201, which is
  correct; but custom actions may need 200 or 204).
- Return plain objects/arrays from controllers — NestJS serializes them to JSON
  automatically. Don't manually call `res.json()` unless you need streaming.

## DTOs and validation

Use `class-validator` + `class-transformer` for input validation. Enable the
global validation pipe in `main.ts`:

```typescript
// main.ts
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,           // Strip properties not in the DTO
  forbidNonWhitelisted: true, // Throw if unknown properties are sent
  transform: true,            // Auto-transform payloads to DTO instances
}));
```

Define DTOs with validation decorators:

```typescript
export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;
}
```

For update DTOs, extend create DTOs with `PartialType`:

```typescript
export class UpdateUserDto extends PartialType(CreateUserDto) {}
```

`PartialType` makes all fields optional and preserves validation decorators —
don't duplicate DTO definitions.

## Services

Services contain all business logic. They're `@Injectable()` and injected via
the constructor:

```typescript
@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateUserDto): Promise<User> {
    const hashedPassword = await hash(dto.password, 10);
    return this.prisma.user.create({
      data: { ...dto, password: hashedPassword },
    });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException(`User #${id} not found`);
    return user;
  }
}
```

- Throw NestJS built-in exceptions (`NotFoundException`, `BadRequestException`,
  `ConflictException`, `ForbiddenException`) — they automatically produce the
  correct HTTP status code and a consistent error shape.
- Keep services focused on one domain. A `UsersService` should not send emails —
  inject a `MailService` and call it.

## Database integration

Choose one ORM and stick with it. Read the reference file for your chosen ORM
for detailed setup and patterns:

- **Prisma** (recommended for new projects): See [references/prisma.md](references/prisma.md)
- **TypeORM**: See [references/typeorm.md](references/typeorm.md)
- **Drizzle**: See [references/drizzle.md](references/drizzle.md)

Default to **Prisma** unless the user specifies otherwise or the project already
uses a different ORM. Prisma gives the best type-safety, migration workflow,
and developer experience for most NestJS projects.

## Authentication and authorization

Use `@nestjs/passport` + `@nestjs/jwt` for JWT-based auth. See
[references/auth.md](references/auth.md) for the full setup pattern including
strategies, guards, and role-based access control.

Quick summary:
- Create a `JwtStrategy` extending `PassportStrategy(Strategy)` from
  `passport-jwt`.
- Create a `JwtAuthGuard` extending `AuthGuard('jwt')`.
- Apply guards at the controller or method level with `@UseGuards()`, or
  globally via `APP_GUARD` for protected-by-default APIs.
- Use a custom `@Public()` decorator to exempt specific routes from the global
  guard.

## Configuration

Use `@nestjs/config` with Joi or zod validation for environment variables:

```typescript
// config/app.config.ts
import { registerAs } from '@nestjs/config';

export default registerAs('app', () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET,
}));
```

Access config via injection — never read `process.env` directly in services or
controllers. This makes the code testable and centralizes env validation.

## Testing

NestJS uses Jest out of the box. Write two kinds of tests:

**Unit tests** (`.spec.ts` next to the file being tested):
- Test services in isolation by mocking their dependencies.
- Use `Test.createTestingModule()` to build a minimal module with mocked providers.

```typescript
const module = await Test.createTestingModule({
  providers: [
    UsersService,
    { provide: PrismaService, useValue: mockPrisma },
  ],
}).compile();
```

**E2E tests** (`test/` directory, `.e2e-spec.ts`):
- Test full request/response cycles against a real (or in-memory) database.
- Use `supertest` with `app.getHttpServer()`.
- Seed the database before tests, clean up after.

See [references/testing.md](references/testing.md) for patterns, mocking
strategies, and common pitfalls.

## Gotchas

- **`synchronize: true` in TypeORM will destroy production data.** It auto-syncs
  entity changes to the DB schema. Only use in development — never in production.
  Use migrations instead.
- **Circular dependency errors** usually mean your module graph is wrong. Extract
  shared logic into a new module rather than reaching for `forwardRef()`.
- **`class-validator` won't work** unless you enable the `ValidationPipe` globally
  (in `main.ts`) or per-route. Without it, DTOs are just plain objects with no
  validation.
- **Prisma Client must be regenerated** after any schema change (`npx prisma
  generate`). If types look wrong or missing, run `generate` first.
- **Guards execute before interceptors**, which execute before pipes. If your
  auth guard depends on a transformed body, you need to restructure — the body
  isn't validated yet when the guard runs.
- **Don't import entities/services across modules without exporting them.** If
  module A needs a service from module B, module B must `exports: [TheService]`
  and module A must `imports: [ModuleB]`.
- **Global filters/pipes/interceptors registered in `main.ts`** via `app.use*()`
  don't have access to dependency injection. If they need injected dependencies,
  register them as providers with `APP_FILTER`, `APP_PIPE`, `APP_INTERCEPTOR`
  tokens in a module instead.
- **`@Res()` disables NestJS's automatic response handling.** If you inject the
  raw response object, you must manually call `res.json()` / `res.send()`. Prefer
  returning values from controller methods instead.
- **Nest's default error format** is `{ statusCode, message, error }`. If you
  customize it via an exception filter, keep the shape consistent across your API
  or document the new shape clearly.
- **`forRootAsync()` with `useFactory`** — don't forget to add `inject: [...]`
  for any services you use in the factory function, and `imports: [...]` for
  their modules.

## File naming conventions

Follow the Nest CLI conventions strictly:

| Type         | Naming pattern                    | Example                    |
|--------------|-----------------------------------|----------------------------|
| Module       | `feature.module.ts`               | `users.module.ts`          |
| Controller   | `feature.controller.ts`           | `users.controller.ts`      |
| Service      | `feature.service.ts`              | `users.service.ts`         |
| DTO          | `action-feature.dto.ts`           | `create-user.dto.ts`       |
| Entity       | `feature.entity.ts`               | `user.entity.ts`           |
| Guard        | `feature.guard.ts`                | `jwt-auth.guard.ts`        |
| Interceptor  | `feature.interceptor.ts`          | `logging.interceptor.ts`   |
| Pipe         | `feature.pipe.ts`                 | `parse-date.pipe.ts`       |
| Filter       | `feature.filter.ts`               | `http-exception.filter.ts` |
| Strategy     | `feature.strategy.ts`             | `jwt.strategy.ts`          |
| Spec         | `feature.type.spec.ts`            | `users.service.spec.ts`    |
| E2E test     | `feature.e2e-spec.ts`             | `users.e2e-spec.ts`        |

Use **kebab-case** for file names, **PascalCase** for class names. The suffix
(`.controller`, `.service`, `.module`) is not optional — it's how the codebase
stays navigable.
