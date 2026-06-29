# Skill: Unit Testing (Android)

platform: android

## Overview

Unit tests verify one component in isolation — a use case, ViewModel, mapper, or repository
— with its dependencies replaced by test doubles. They are the **base of the test pyramid**:
fast, deterministic, and numerous. On Android, prefer **JUnit 5** (Jupiter) with
**MockK** for Kotlin-friendly mocking and **Turbine** for testing `Flow`/`StateFlow`
emissions. The prerequisite for good unit tests is testable design: constructor-injected
dependencies (or Hilt `@TestInstallIn` modules) and injectable `Clock`/`UUID` sources.

## Use Cases

- Business logic (use cases), presentation logic (ViewModels), DTO mappers.
- Edge-case and error-path verification.
- Regression tests accompanying bug fixes.

## Best Practices

- Follow **AAA** (Arrange, Act, Assert); keep one behavior per test.
- Use **`runTest`** (`kotlinx-coroutines-test`) for deterministic coroutine scoping.
- **Inject** dependencies via constructor or Hilt test modules so tests are deterministic.
- Name tests by behavior: `method_condition_expectedResult`.
- Cover **errors, empties, and boundaries** first, not just the happy path.
- Use **fakes/stubs** over heavy mocking; prefer MockK `relaxed` or `every { … } returns …`.
- Assert `StateFlow` emissions with **Turbine** (`flow.test { … }`).

## Anti-Patterns

- ❌ Launching real coroutines without `runTest` (flaky, slow).
- ❌ Hitting the real network/disk/clock/database.
- ❌ Asserting on private implementation details.
- ❌ One giant test asserting many unrelated things.
- ❌ Non-deterministic data (`Clock.System.now()`, random UUIDs) in assertions.
- ❌ Only happy-path coverage.

## Checklist

- [ ] Logic covered with isolated, deterministic tests.
- [ ] Dependencies injected and faked (constructor or Hilt test module).
- [ ] Error/empty/boundary cases tested.
- [ ] Behavior-focused names; one focus per test.
- [ ] No real network/disk/clock/randomness.
- [ ] Coroutine tests use `runTest` or `runBlocking`.

## Kotlin Examples

```kotlin
import app.cash.turbine.test
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

@OptIn(ExperimentalCoroutinesApi::class)
class TransferUseCaseTest {

    @Test
    fun `execute with sufficient funds succeeds`() = runTest {
        val repo = FakeAccountRepository(initialBalance = 10_000)
        val useCase = TransferUseCase(repo)

        val result = useCase.execute(amount = 5_000, toAccount = "acct-2")

        assertEquals(5_000, result.remainingBalance)
    }

    @Test
    fun `execute with insufficient funds throws InsufficientFunds`() = runTest {
        val repo = FakeAccountRepository(initialBalance = 1_000)
        val useCase = TransferUseCase(repo)

        val error = runCatching {
            useCase.execute(amount = 5_000, toAccount = "acct-2")
        }.exceptionOrNull()

        assertEquals(
            InsufficientFundsException(remaining = 1_000, requested = 5_000).message,
            error?.message
        )
    }
}

class FakeAccountRepository(initialBalance: Int) : AccountRepository {
    private var balance: Int = initialBalance

    override suspend fun getBalance(): Int = balance
    override suspend fun debit(amount: Int): Int {
        if (amount > balance) throw InsufficientFundsException(balance, amount)
        balance -= amount
        return balance
    }
}
```

```kotlin
import app.cash.turbine.test
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var repository: FakeProfileRepository
    private lateinit var viewModel: ProfileViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        repository = FakeProfileRepository()
        viewModel = ProfileViewModel(repository)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `uiState emits initial then loaded with profile data`() = runTest {
        repository.profile = UserProfile(name = "Alice", email = "alice@example.com")

        viewModel.uiState.test {
            assertEquals(UiState.Loading, awaitItem())
            assertEquals(
                UiState.Loaded(UserProfile("Alice", "alice@example.com")),
                awaitItem()
            )
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun `uiState emits error when repository throws`() = runTest {
        repository.shouldThrow = true

        viewModel.uiState.test {
            assertEquals(UiState.Loading, awaitItem())
            assertEquals(UiState.Error("Network failure"), awaitItem())
            cancelAndIgnoreRemainingEvents()
        }
    }
}

class FakeProfileRepository(
    var profile: UserProfile = UserProfile("", ""),
    var shouldThrow: Boolean = false
) : ProfileRepository {
    override suspend fun fetchProfile(): UserProfile {
        if (shouldThrow) throw RuntimeException("Network failure")
        return profile
    }
}
```

## Common Interview Questions

- What makes a good unit test (FIRST principles)?
- How do you test time-dependent or coroutine code in Android?
- Stub vs mock vs fake vs spy in MockK?
- Why use constructor injection over `@Inject` fields for testability?
- `runTest` vs `runBlocking` — when to use each?
- How do you test `StateFlow`/`SharedFlow` emissions deterministically?

## AI Implementation Notes

- Generate unit tests alongside any non-trivial logic; inject `Clock`/`UUID` sources.
- Prefer JUnit 5 `@Test` and MockK `coEvery`/`coVerify` for suspend functions.
- Use `runTest` for coroutine tests; `Turbine` for Flow assertions.
- Always include at least one error-path test.
- Related: [`../unit_testing.md`](../unit_testing.md) (iOS counterpart),
  [`../../../standards/testing_standards.md`](../../../standards/testing_standards.md),
  [`../../../templates/unit_test_template/`](../../../templates/unit_test_template/).
