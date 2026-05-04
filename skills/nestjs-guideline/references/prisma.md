# Prisma Integration with NestJS

This reference covers setting up and using Prisma ORM in a NestJS application.

## Table of Contents

1. [Installation and setup](#installation-and-setup)
2. [PrismaService pattern](#prismaservice-pattern)
3. [Schema design](#schema-design)
4. [Migrations](#migrations)
5. [Usage in services](#usage-in-services)
6. [Transactions](#transactions)
7. [Common patterns](#common-patterns)

## Installation and setup

```bash
npm install @prisma/client
npm install -D prisma

npx prisma init
```

This creates `prisma/schema.prisma` and a `.env` file with a placeholder
`DATABASE_URL`. Configure the URL for your database (Postgres recommended):

```env
DATABASE_URL="postgresql://user:password@localhost:5432/mydb?schema=public"
```

## PrismaService pattern

Create a shared `PrismaService` that manages the client lifecycle:

```typescript
// src/database/prisma.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    super({
      log: process.env.NODE_ENV === 'development'
        ? ['query', 'warn', 'error']
        : ['warn', 'error'],
    });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

Register it in a `DatabaseModule` and export it:

```typescript
// src/database/database.module.ts
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class DatabaseModule {}
```

Mark it `@Global()` so every module can inject `PrismaService` without
explicitly importing `DatabaseModule`.

## Schema design

Define models in `prisma/schema.prisma`:

```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String
  password  String
  role      Role     @default(USER)
  posts     Post[]
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@map("users")
}

model Post {
  id        String   @id @default(uuid())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String   @map("author_id")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@map("posts")
}

enum Role {
  USER
  ADMIN
}
```

**Conventions:**
- Use `@map()` and `@@map()` to keep snake_case in the database while using
  camelCase in TypeScript code.
- Always set `@updatedAt` on timestamp fields that should auto-update.
- Use `uuid()` for primary keys in new projects (avoids sequential ID exposure).

## Migrations

```bash
# Create a migration after schema changes
npx prisma migrate dev --name add_users_table

# Apply migrations in production (CI/CD)
npx prisma migrate deploy

# Regenerate the client after any schema change
npx prisma generate

# Reset database (dev only — drops all data)
npx prisma migrate reset
```

Never use `npx prisma db push` in production — it doesn't create migration
files and can't be reproduced. Use `migrate dev` in development and `migrate
deploy` in production/CI.

## Usage in services

Inject `PrismaService` and use the generated client:

```typescript
@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateUserDto) {
    return this.prisma.user.create({ data: dto });
  }

  findAll(page = 1, limit = 20) {
    return this.prisma.user.findMany({
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
        // Never select password in list queries
      },
    });
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException(`User #${id} not found`);
    return user;
  }
}
```

**Key patterns:**
- Use `select` to exclude sensitive fields (passwords) from query results.
- Use `include` sparingly — eager-loading relations can cause N+1-style bloat.
  Load only what the endpoint needs.
- Use `findUnique` (not `findFirst`) when querying by a unique field — it's
  faster and signals intent.

## Transactions

Use interactive transactions for multi-step operations:

```typescript
async transferFunds(fromId: string, toId: string, amount: number) {
  return this.prisma.$transaction(async (tx) => {
    const from = await tx.account.update({
      where: { id: fromId },
      data: { balance: { decrement: amount } },
    });
    if (from.balance < 0) {
      throw new BadRequestException('Insufficient funds');
    }
    await tx.account.update({
      where: { id: toId },
      data: { balance: { increment: amount } },
    });
    return from;
  });
}
```

The `tx` client is scoped to the transaction — if any operation throws, the
entire transaction rolls back.

## Common patterns

### Soft deletes

Prisma doesn't have built-in soft deletes. Implement with a middleware:

```typescript
// In PrismaService constructor or as an extension
this.$use(async (params, next) => {
  if (params.action === 'delete') {
    params.action = 'update';
    params.args.data = { deletedAt: new Date() };
  }
  if (params.action === 'findMany' || params.action === 'findFirst') {
    params.args.where = { ...params.args.where, deletedAt: null };
  }
  return next(params);
});
```

### Pagination helper

```typescript
async paginate<T>(
  model: any,
  args: { page: number; limit: number; where?: any; orderBy?: any },
): Promise<{ data: T[]; total: number; page: number; lastPage: number }> {
  const { page, limit, where, orderBy } = args;
  const [data, total] = await Promise.all([
    model.findMany({ where, orderBy, skip: (page - 1) * limit, take: limit }),
    model.count({ where }),
  ]);
  return { data, total, page, lastPage: Math.ceil(total / limit) };
}
```
