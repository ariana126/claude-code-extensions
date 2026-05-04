# Drizzle ORM Integration with NestJS

This reference covers setting up Drizzle ORM in a NestJS application.

## Table of Contents

1. [Installation and setup](#installation-and-setup)
2. [Schema definition](#schema-definition)
3. [Database module](#database-module)
4. [Usage in services](#usage-in-services)
5. [Migrations](#migrations)

## Installation and setup

```bash
npm install drizzle-orm pg
npm install -D drizzle-kit @types/pg
```

Create a Drizzle config file:

```typescript
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/database/schema/*.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

## Schema definition

Define schemas using Drizzle's TypeScript-first approach:

```typescript
// src/database/schema/users.ts
import { pgTable, uuid, varchar, text, timestamp, pgEnum } from 'drizzle-orm/pg-core';

export const roleEnum = pgEnum('role', ['user', 'admin']);

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  name: varchar('name', { length: 100 }).notNull(),
  password: text('password').notNull(),
  role: roleEnum('role').default('user').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
```

## Database module

Create a module that provides the Drizzle client:

```typescript
// src/database/database.module.ts
import { Module, Global } from '@nestjs/common';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from './schema';

export const DRIZZLE = Symbol('DRIZZLE');

@Global()
@Module({
  providers: [
    {
      provide: DRIZZLE,
      useFactory: () => {
        const pool = new Pool({ connectionString: process.env.DATABASE_URL });
        return drizzle(pool, { schema });
      },
    },
  ],
  exports: [DRIZZLE],
})
export class DatabaseModule {}
```

## Usage in services

Inject the Drizzle client and use type-safe queries:

```typescript
@Injectable()
export class UsersService {
  constructor(@Inject(DRIZZLE) private readonly db: NodePgDatabase<typeof schema>) {}

  async create(dto: CreateUserDto) {
    const [user] = await this.db.insert(schema.users)
      .values(dto)
      .returning();
    return user;
  }

  async findAll(page = 1, limit = 20) {
    return this.db.select({
      id: schema.users.id,
      email: schema.users.email,
      name: schema.users.name,
      role: schema.users.role,
    })
    .from(schema.users)
    .orderBy(desc(schema.users.createdAt))
    .limit(limit)
    .offset((page - 1) * limit);
  }
}
```

## Migrations

```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Apply migrations
npx drizzle-kit migrate

# Open Drizzle Studio (DB browser)
npx drizzle-kit studio
```

Drizzle generates SQL migration files. Review them before applying — unlike
Prisma, Drizzle doesn't auto-apply in dev. This is a feature: you always see
exactly what SQL will run.
