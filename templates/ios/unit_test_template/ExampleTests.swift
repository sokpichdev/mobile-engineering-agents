//  ExampleTests.swift
//  Representative unit tests using Swift Testing. Copy and adapt.
//  Demonstrates AAA, behavior-focused names, a simple fake, and an error-path test.

import Testing

// System under test (illustrative): a use case that checks out a cart.
struct CheckoutUseCase {
    let payments: PaymentGateway

    func execute(amountCents: Int) async throws -> Receipt {
        guard amountCents > 0 else { throw CheckoutError.invalidAmount }
        return try await payments.charge(amountCents: amountCents)
    }
}

enum CheckoutError: Error, Equatable { case invalidAmount, declined }
struct Receipt: Equatable { let id: String }

protocol PaymentGateway: Sendable {
    func charge(amountCents: Int) async throws -> Receipt
}

// MARK: - Tests

struct CheckoutUseCaseTests {

    @Test func execute_withValidAmount_returnsReceipt() async throws {
        // Arrange
        let sut = CheckoutUseCase(payments: StubGateway(result: .success(Receipt(id: "r1"))))
        // Act
        let receipt = try await sut.execute(amountCents: 500)
        // Assert
        #expect(receipt == Receipt(id: "r1"))
    }

    @Test func execute_withZeroAmount_throwsInvalidAmount() async {
        let sut = CheckoutUseCase(payments: StubGateway(result: .success(Receipt(id: "x"))))

        await #expect(throws: CheckoutError.invalidAmount) {
            try await sut.execute(amountCents: 0)
        }
    }

    @Test func execute_whenGatewayDeclines_propagatesError() async {
        let sut = CheckoutUseCase(payments: StubGateway(result: .failure(CheckoutError.declined)))

        await #expect(throws: CheckoutError.declined) {
            try await sut.execute(amountCents: 500)
        }
    }
}

// MARK: - Test double (simple fake — no mocking framework)

private struct StubGateway: PaymentGateway {
    let result: Result<Receipt, Error>
    func charge(amountCents: Int) async throws -> Receipt { try result.get() }
}
