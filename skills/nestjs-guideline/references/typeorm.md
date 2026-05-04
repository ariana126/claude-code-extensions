# TypeORM Integration with NestJS

This reference covers setting up and using TypeORM in a NestJS application.

## Table of Contents

1. [Installation and setup](#installation-and-setup)
2. [Entity design](#entity-design)
3. [Repository pattern](#repository-pattern)
4. [Migrations](#migrations)
5. [Transactions](#transactions)
6. [Query patterns](#query-patterns)

## Installation and setup

```bash
npm install @nestjs/typeorm typeorm pg  # or mysql2, better-sqlite3, etc.
```

Configure in the root module:

```typescript
// src/database/database.module.ts
@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get('DB_HOST'),
        port: config.get<number>('DB_PORT'),
        username: config.get('DB_USER'),
        password: config.get('DB_PASSWORD'),
        database: config.get('DB_NAME'),
        autoLoadEntities: true,  // Auto-discover entities registered via forFeature()
        synchronize: false,      // NEVER true in production
        logging: config.get('NODE_ENV') === 'development',
      }),
    }),
  ],
})
export class DatabaseModule {}
```

**Critical: set `synchronize: false`.** Setting it to `true` auto-applies
schema changes on startup, which will drop columns and lose data in production.
Use migrations instead.

Register entities per module:

```typescript
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
```

## Entity design

Use the Data Mapper pattern (repositories injected into services) rather than
Active Record, because Data Mapper keeps entities as plain data objects and
separates persistence logic — this makes services easier to test:

```typescript
// src/users/entities/user.entity.ts
@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  name: string;

  @Column({ select: false })  // Excluded from queries by default
  password: string;

  @Column({ type: 'enum', enum: Role, default: Role.USER })
  role: Role;

  @OneToMany(() => Post, (post) => post.author)
  posts: Post[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
```

- Use `@Column({ select: false })` for sensitive fields like passwords — they
  won't be returned unless explicitly selected with `.addSelect()`.
- Use `@CreateDateColumn` and `@UpdateDateColumn` for automatic timestamps.
- Name tables explicitly with `@Entity('table_name')` to control the DB schema.

## Repository pattern

Inject the repository via `@InjectRepository()`:

```typescript
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
  ) {}

  create(dto: CreateUserDto): Promise<User> {
    const user = this.usersRepo.create(dto);
    return this.usersRepo.save(user);
  }

  findAll(): Promise<User[]> {
    return this.usersRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.usersRepo.findOneBy({ id });
    if (!user) throw new NotFoundException(`User #${id} not found`);
    return user;
  }
}
```

- Always use `create()` + `save()` instead of `save()` alone — `create()`
  instantiates the entity and applies defaults before persistence.
- For queries needing the password field: use the query builder with
  `.addSelect('user.password')`.

## Migrations

Set up a separate data-source file for the CLI:

```typescript
// src/database/data-source.ts
import { DataSource } from 'typeorm';
import { config } from 'dotenv';
config();

export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: +process.env.DB_PORT,
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/database/migrations/*.ts'],
});
```

Add scripts to `package.json`:

```json
{
  "typeorm": "ts-node -r tsconfig-paths/register ./node_modules/typeorm/cli.js -d src/database/data-source.ts",
  "migration:generate": "npm run typeorm -- migration:generate",
  "migration:run": "npm run typeorm -- migration:run",
  "migration:revert": "npm run typeorm -- migration:revert"
}
```

```bash
# Generate a migration from entity changes
npm run migration:generate -- src/database/migrations/AddUsersTable

# Run pending migrations
npm run migration:run

# Revert the last migration
npm run migration:revert
```

## Transactions

Use the `DataSource` for transaction management:

```typescript
constructor(
  private readonly dataSource: DataSource,
) {}

async transferFunds(fromId: string, toId: string, amount: number) {
  await this.dataSource.transaction(async (manager) => {
    await manager.decrement(Account, { id: fromId }, 'balance', amount);
    const from = await manager.findOneBy(Account, { id: fromId });
    if (from.balance < 0) {
      throw new BadRequestException('Insufficient funds');
    }
    await manager.increment(Account, { id: toId }, 'balance', amount);
  });
}
```

## Query patterns

Use the query builder for complex queries:

```typescript
async findActiveUsersWithPosts() {
  return this.usersRepo
    .createQueryBuilder('user')
    .leftJoinAndSelect('user.posts', 'post', 'post.published = :pub', { pub: true })
    .where('user.role = :role', { role: Role.USER })
    .orderBy('user.createdAt', 'DESC')
    .getMany();
}
```

Always use parameterized queries (`:paramName`) — never concatenate user input
into query strings.
