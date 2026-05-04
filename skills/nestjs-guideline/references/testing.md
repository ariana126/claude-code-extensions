# Testing NestJS Applications

This reference covers unit testing, e2e testing, and common testing patterns
for NestJS applications.

## Table of Contents

1. [Unit testing services](#unit-testing-services)
2. [Unit testing controllers](#unit-testing-controllers)
3. [E2E testing](#e2e-testing)
4. [Mocking patterns](#mocking-patterns)
5. [Common pitfalls](#common-pitfalls)

## Unit testing services

Test services in isolation by mocking their dependencies:

```typescript
// users.service.spec.ts
describe('UsersService', () => {
  let service: UsersService;
  let prisma: DeepMockProxy<PrismaService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: PrismaService,
          useValue: mockDeep<PrismaService>(),
        },
      ],
    }).compile();

    service = module.get(UsersService);
    prisma = module.get(PrismaService);
  });

  describe('findOne', () => {
    it('should return a user when found', async () => {
      const mockUser = { id: '1', name: 'Alice', email: 'a@b.com' };
      prisma.user.findUnique.mockResolvedValue(mockUser as any);

      const result = await service.findOne('1');
      expect(result).toEqual(mockUser);
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: '1' },
      });
    });

    it('should throw NotFoundException when user not found', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(service.findOne('999')).rejects.toThrow(NotFoundException);
    });
  });
});
```

Use `jest-mock-extended` (`mockDeep`) for type-safe mocking of Prisma or any
complex dependency.

## Unit testing controllers

Controller tests verify routing, pipes, and response transformation — not
business logic:

```typescript
describe('UsersController', () => {
  let controller: UsersController;
  let service: jest.Mocked<UsersService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: {
            create: jest.fn(),
            findOne: jest.fn(),
            findAll: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get(UsersController);
    service = module.get(UsersService);
  });

  it('should call service.create with the DTO', async () => {
    const dto = { name: 'Alice', email: 'a@b.com', password: 'secret123' };
    service.create.mockResolvedValue({ id: '1', ...dto } as any);

    const result = await controller.create(dto);
    expect(service.create).toHaveBeenCalledWith(dto);
    expect(result.id).toBe('1');
  });
});
```

## E2E testing

E2E tests exercise the full HTTP stack:

```typescript
// test/users.e2e-spec.ts
describe('UsersController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = module.createNestApplication();
    // Apply the same global config as main.ts
    app.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST /users creates a user', () => {
    return request(app.getHttpServer())
      .post('/users')
      .send({ name: 'Alice', email: 'a@b.com', password: 'secret123' })
      .expect(201)
      .expect((res) => {
        expect(res.body.id).toBeDefined();
        expect(res.body.email).toBe('a@b.com');
        expect(res.body.password).toBeUndefined(); // Should not leak
      });
  });

  it('POST /users rejects invalid email', () => {
    return request(app.getHttpServer())
      .post('/users')
      .send({ name: 'Alice', email: 'not-an-email', password: 'secret123' })
      .expect(400);
  });
});
```

**Important:** Apply the same global pipes, filters, and interceptors in e2e
tests as in `main.ts` — otherwise you're testing a different app configuration.

## Mocking patterns

### Mock a service entirely

```typescript
{ provide: UsersService, useValue: { findOne: jest.fn(), create: jest.fn() } }
```

### Mock a repository (TypeORM)

```typescript
{
  provide: getRepositoryToken(User),
  useValue: {
    find: jest.fn(),
    findOneBy: jest.fn(),
    save: jest.fn(),
    create: jest.fn().mockImplementation((dto) => dto),
  },
}
```

### Mock ConfigService

```typescript
{
  provide: ConfigService,
  useValue: { get: jest.fn((key: string) => {
    const config = { JWT_SECRET: 'test-secret', DB_HOST: 'localhost' };
    return config[key];
  })},
}
```

## Common pitfalls

- **Forgetting to apply global pipes in e2e tests.** If `main.ts` has a
  `ValidationPipe`, your e2e tests must too — otherwise DTO validation won't
  run and tests will pass with invalid input.
- **Testing implementation details instead of behavior.** Don't assert that
  `prisma.user.findUnique` was called 1 time — assert that the service returns
  the expected result or throws the expected error.
- **Not cleaning up the database between e2e tests.** Use `beforeEach` to
  truncate tables or use transactions that roll back after each test.
- **Mocking too much in e2e tests.** E2E tests should use real modules and a
  real (or in-memory) database. Mock only external services (email, payment).
- **Using `jest.mock()` at the module level** when you should use NestJS DI
  overrides. NestJS's `Test.createTestingModule().overrideProvider()` is more
  idiomatic and avoids Jest hoisting confusion.
