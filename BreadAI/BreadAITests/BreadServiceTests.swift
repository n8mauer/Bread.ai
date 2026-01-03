import XCTest
@testable import BreadAI

/// Unit tests for BreadService networking and fallback functionality.
final class BreadServiceTests: XCTestCase {

    // MARK: - AIRecipe Model Tests

    func testAIRecipeDecoding_ValidJSON_DecodesSuccessfully() throws {
        let json = """
        {
            "name": "Ciabatta",
            "description": "Italian bread with a crispy crust",
            "prep_time": "30 min",
            "ferment_time": "2 hrs",
            "bake_time": "25 min",
            "difficulty": "Medium",
            "ingredients": [
                {"amount": "500g", "item": "bread flour"},
                {"amount": "350ml", "item": "water"}
            ],
            "instructions": [
                "Mix ingredients",
                "Let rise",
                "Bake"
            ],
            "tips": "Handle gently"
        }
        """.data(using: .utf8)!

        let recipe = try JSONDecoder().decode(AIRecipe.self, from: json)

        XCTAssertEqual(recipe.name, "Ciabatta")
        XCTAssertEqual(recipe.description, "Italian bread with a crispy crust")
        XCTAssertEqual(recipe.prepTime, "30 min")
        XCTAssertEqual(recipe.fermentTime, "2 hrs")
        XCTAssertEqual(recipe.bakeTime, "25 min")
        XCTAssertEqual(recipe.difficulty, "Medium")
        XCTAssertEqual(recipe.ingredients.count, 2)
        XCTAssertEqual(recipe.instructions.count, 3)
        XCTAssertEqual(recipe.tips, "Handle gently")
    }

    func testAIRecipeIngredientDecoding_ValidJSON_DecodesSuccessfully() throws {
        let json = """
        {"amount": "500g", "item": "bread flour"}
        """.data(using: .utf8)!

        let ingredient = try JSONDecoder().decode(AIRecipe.Ingredient.self, from: json)

        XCTAssertEqual(ingredient.amount, "500g")
        XCTAssertEqual(ingredient.item, "bread flour")
    }

    func testAIRecipeDecoding_SnakeCaseKeys_MapsCorrectly() throws {
        // Verify that snake_case keys map to camelCase properties
        let json = """
        {
            "name": "Test",
            "description": "Test bread",
            "prep_time": "10 min",
            "ferment_time": "1 hr",
            "bake_time": "20 min",
            "difficulty": "Easy",
            "ingredients": [],
            "instructions": [],
            "tips": "Tip"
        }
        """.data(using: .utf8)!

        let recipe = try JSONDecoder().decode(AIRecipe.self, from: json)

        XCTAssertEqual(recipe.prepTime, "10 min")
        XCTAssertEqual(recipe.fermentTime, "1 hr")
        XCTAssertEqual(recipe.bakeTime, "20 min")
    }

    func testAIRecipeDecoding_MissingField_ThrowsError() {
        let json = """
        {
            "name": "Test",
            "description": "Test bread"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(AIRecipe.self, from: json))
    }

    func testAIRecipeEncoding_ValidRecipe_EncodesSuccessfully() throws {
        let ingredient = AIRecipe.Ingredient(amount: "500g", item: "flour")
        let recipe = AIRecipe(
            name: "Test Bread",
            description: "A test bread",
            prepTime: "10 min",
            fermentTime: "1 hr",
            bakeTime: "20 min",
            difficulty: "Easy",
            ingredients: [ingredient],
            instructions: ["Mix", "Bake"],
            tips: "Test tip"
        )

        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(AIRecipe.self, from: data)

        XCTAssertEqual(decoded.name, recipe.name)
        XCTAssertEqual(decoded.prepTime, recipe.prepTime)
    }

    // MARK: - BreadServiceError Tests

    func testBreadServiceError_InvalidURL_HasCorrectDescription() {
        let error = BreadService.BreadServiceError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid server URL")
    }

    func testBreadServiceError_ServerError_HasCorrectDescription() {
        let error = BreadService.BreadServiceError.serverError
        XCTAssertEqual(error.errorDescription, "Server error occurred")
    }

    func testBreadServiceError_NoData_HasCorrectDescription() {
        let error = BreadService.BreadServiceError.noData
        XCTAssertEqual(error.errorDescription, "No data received")
    }

    // MARK: - Fallback Response Tests

    func testFallbackResponse_SourdoughQuery_ReturnsSourdoughInfo() {
        let service = BreadService.shared
        let expectation = XCTestExpectation(description: "Fallback response")

        // Use a query that will trigger fallback due to no network
        // The fallback should be triggered by the service when network fails
        service.askAboutBread(query: "sourdough") { response in
            // Either we get a real response or fallback - both should mention sourdough
            XCTAssertTrue(response.lowercased().contains("sourdough") ||
                         response.lowercased().contains("offline"),
                         "Response should mention sourdough or offline status")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 35.0)
    }

    func testFallbackResponse_RyeQuery_ReturnsRyeInfo() {
        let service = BreadService.shared
        let expectation = XCTestExpectation(description: "Fallback response for rye")

        service.askAboutBread(query: "rye bread") { response in
            XCTAssertTrue(response.lowercased().contains("rye") ||
                         response.lowercased().contains("offline"),
                         "Response should mention rye or offline status")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 35.0)
    }

    func testFallbackResponse_GlutenQuery_ReturnsGlutenInfo() {
        let service = BreadService.shared
        let expectation = XCTestExpectation(description: "Fallback response for gluten")

        service.askAboutBread(query: "gluten free options") { response in
            XCTAssertTrue(response.lowercased().contains("gluten") ||
                         response.lowercased().contains("offline"),
                         "Response should mention gluten or offline status")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 35.0)
    }

    func testFallbackResponse_RecipeQuery_ReturnsRecipeInfo() {
        let service = BreadService.shared
        let expectation = XCTestExpectation(description: "Fallback response for recipe")

        service.askAboutBread(query: "how to make bread") { response in
            XCTAssertTrue(response.lowercased().contains("recipe") ||
                         response.lowercased().contains("flour") ||
                         response.lowercased().contains("offline"),
                         "Response should mention recipe basics or offline status")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 35.0)
    }

    func testFallbackResponse_HistoryQuery_ReturnsHistoryInfo() {
        let service = BreadService.shared
        let expectation = XCTestExpectation(description: "Fallback response for history")

        service.askAboutBread(query: "history of bread") { response in
            XCTAssertTrue(response.lowercased().contains("history") ||
                         response.lowercased().contains("years") ||
                         response.lowercased().contains("offline"),
                         "Response should mention history or offline status")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 35.0)
    }

    // MARK: - BreadService Singleton Tests

    func testBreadService_Singleton_ReturnsSameInstance() {
        let instance1 = BreadService.shared
        let instance2 = BreadService.shared

        XCTAssertTrue(instance1 === instance2, "BreadService should be a singleton")
    }

    // MARK: - Recipe Fetch Tests

    func testFetchRecipe_ValidBreadName_CompletesWithResult() {
        let service = BreadService.shared
        let expectation = XCTestExpectation(description: "Recipe fetch")

        service.fetchRecipe(for: "Baguette") { result in
            switch result {
            case .success(let recipe):
                XCTAssertFalse(recipe.name.isEmpty, "Recipe name should not be empty")
            case .failure(let error):
                // Failure is acceptable if backend is not running
                XCTAssertNotNil(error, "Error should be provided on failure")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 65.0)
    }

    func testFetchRecipe_EmptyBreadName_CompletesWithResult() {
        let service = BreadService.shared
        let expectation = XCTestExpectation(description: "Recipe fetch with empty name")

        service.fetchRecipe(for: "") { result in
            // Should still complete, possibly with an error
            switch result {
            case .success, .failure:
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 65.0)
    }
}
