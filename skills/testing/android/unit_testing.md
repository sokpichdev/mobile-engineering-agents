---
platform: android
---

# Skill: Unit Testing

## Overview

Unit tests verify one component in isolation — a use case, ViewModel, mapper, or repository
— with its dependencies replaced by test doubles. They are the **base of the test pyramid**:
fast, deterministic, and numerous. On Android, prefer **JUnit 5** with **MockK** for Kotlin
and **Turbine** for `Flow`/`StateFlow` assertions. The prerequisite for good unit tests is
testable design: constructor injection and injectable `Clock`/UUID providers.

## Use Cases

- Business logic (use cases), presentation logic (ViewModels), DTO mappers.
- Edge-case and error-path verification.
- Regression tests accompanying bug fixes.

## Best Practices

- Follow **AAA** (Arrange, Act, Assert); keep one behavior per test.
- **Inject** dependencies (repositories, clock, ids) so tests are deterministic.
- Name tests by behavior: `method_condition_expectedResult`.
- Cover **errors, empties, and boundaries** first, not just the happy path.
- Use **fakes/stubs** over heavy mocking frameworks; keep doubles simple.
- Use `runTest` (coroutines-test) for suspending functions; use `Turbine` for `Flow` assertions.

## Anti-Patterns

- ❌ Hitting the real network/disk/clock (flaky, slow).
- ❌ Asserting on private implementation details.
- ❌ One giant test asserting many unrelated things.
- ❌ Non-deterministic data (`Clock.System.now()`, random ids) in assertions.
- ❌ Only happy-path coverage.
- ❌ Using `runBlocking` instead of `runTest` (skips virtual time, loses test isolation).
- ❌ Mocking `StateFlow.value` directly instead of collecting emissions with Turbine.

## Checklist

- [ ] Logic covered with isolated, deterministic tests.
- [ ] Dependencies injected and faked.
- [ ] Error/empty/boundary cases tested.
- [ ] Behavior-focused names; one focus per test.
- [ ] No real network/clock/randomness.
- [ ] `runTest` used for coroutine tests; Turbine used for `Flow`/`StateFlow` assertions.

## Kotlin Examples

```kotlin
import app.cash.turbine.test
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

class TransferUseCaseTest {

    private val repository = FakeAccountRepository(balanceCents = 10_000)
    private val sut = TransferUseCase(repository)

    @Test
    fun `execute with sufficient funds succeeds`() = runTest {
        val result = sut.execute(amountCents = 5_000, toAccount = "acct-2")

        assertEquals(5_000, result.remainingCents)
    }

    @Test
    fun `execute with insufficient funds throws`() = runTest {
        val repository = FakeAccountRepository(balanceCents = 1_000)
        val sut = TransferUseCase(repository)

        assertThrows<InsufficientFundsException> {
            sut.execute(amountCents = 5_000, toAccount = "acct-2")
        }
    }
}

class TransferViewModelTest {

    @Test
    fun `stateFlow emits loading then success`() = runTest {
        val repo = mockk<AccountRepository> {
            coEvery { transfer(any(), any()) } returns TransferResult(5_000)
        }
        val viewModel = TransferViewModel(repo)

        viewModel.uiState.test {
            assertEquals(UiState.Loading, awaitItem())
            assertEquals(UiState.Success(5_000), awaitItem())
        }
    }

    @Test
    fun `stateFlow emits error on failure`() = runTest {
        val repo = mockk<AccountRepository> {
            coEvery { transfer(any(), any()) } throws InsufficientFundsException()
        }
        val viewModel = TransferViewModel(repo)

        viewModel.uiState.test {
            assertEquals(UiState.Loading, awaitItem())
            assertEquals(UiState.Error("Insufficient funds"), awaitItem())
        }
    }
}

// Simple fake — no mocking framework needed
class FakeAccountRepository(private val balanceCents: Int) : AccountRepository {
    override suspend fun balance(): Int = balanceCents

    override suspend fun transfer(amountCents: Int, toAccount: String): TransferResult {
        if (amountCents > balanceCents) throw InsufficientFundsException()
        return TransferResult(balanceCents - amountCents)
    }
}
```

## Common Interview Questions

- What makes a good unit test (FIRST principles)?
- How do you make time-dependent code testable?
- Stub vs mock vs fake vs spy?
- Why avoid asserting on private internals?
- JUnit 4 vs JUnit 5 differences?
- `runBlocking` vs `runTest` — why prefer `runTest`?

## AI Implementation Notes

- Generate unit tests alongside any non-trivial logic; inject `Clock`/UUID providers.
- Prefer JUnit 5 `@Test` with MockK `mockk`/`coEvery`; use simple fakes when practical.
- Always include at least one error-path test and one `StateFlow`-emission test with Turbine.
- Related: [iOS Unit Testing](../ios/unit_testing.md),
  [`integration_testing.md`](../ios/integration_testing.md),
  [`../../../standards/testing_standards.md`](../../../standards/testing_standards.md),
  [`../../../templates/ios/unit_test_template/`](../../../templates/ios/unit_test_template/).
