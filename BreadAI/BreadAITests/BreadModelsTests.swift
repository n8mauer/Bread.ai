import XCTest
@testable import BreadAI

/// Unit tests for Bread and BreadCategory models.
final class BreadModelsTests: XCTestCase {

    // MARK: - Bread Model Tests

    func testBread_DefaultInitializer_SetsDefaultValues() {
        let bread = Bread(name: "Test Bread")

        XCTAssertEqual(bread.name, "Test Bread")
        XCTAssertFalse(bread.isSourdough, "Default isSourdough should be false")
        XCTAssertEqual(bread.image, "bread.ai logo no background")
    }

    func testBread_SourdoughInitializer_SetsSourdoughTrue() {
        let bread = Bread(name: "Sourdough", isSourdough: true)

        XCTAssertEqual(bread.name, "Sourdough")
        XCTAssertTrue(bread.isSourdough)
    }

    func testBread_CustomImageInitializer_SetsCustomImage() {
        let bread = Bread(name: "Custom Bread", isSourdough: false, image: "custom_image")

        XCTAssertEqual(bread.image, "custom_image")
    }

    func testBread_HasUniqueID() {
        let bread1 = Bread(name: "Bread 1")
        let bread2 = Bread(name: "Bread 2")

        XCTAssertNotEqual(bread1.id, bread2.id, "Each bread should have a unique ID")
    }

    func testBread_SameNameDifferentInstances_HaveDifferentIDs() {
        let bread1 = Bread(name: "Same Name")
        let bread2 = Bread(name: "Same Name")

        XCTAssertNotEqual(bread1.id, bread2.id, "Different instances should have different IDs")
    }

    // MARK: - BreadCategory Model Tests

    func testBreadCategory_Initializer_SetsValuesCorrectly() {
        let breads = [Bread(name: "Bread 1"), Bread(name: "Bread 2")]
        let category = BreadCategory(name: "Test Category", breads: breads)

        XCTAssertEqual(category.name, "Test Category")
        XCTAssertEqual(category.breads.count, 2)
    }

    func testBreadCategory_HasUniqueID() {
        let category1 = BreadCategory(name: "Category 1", breads: [])
        let category2 = BreadCategory(name: "Category 2", breads: [])

        XCTAssertNotEqual(category1.id, category2.id)
    }

    func testBreadCategory_EmptyBreadsArray_IsValid() {
        let category = BreadCategory(name: "Empty Category", breads: [])

        XCTAssertEqual(category.breads.count, 0)
    }

    // MARK: - BreadData Tests

    func testBreadData_Categories_NotEmpty() {
        XCTAssertFalse(BreadData.categories.isEmpty, "BreadData should have categories")
    }

    func testBreadData_Categories_ContainsYeastBasedBreads() {
        let yeastCategory = BreadData.categories.first { $0.name == "Yeast-Based Breads" }
        XCTAssertNotNil(yeastCategory, "Should have Yeast-Based Breads category")
    }

    func testBreadData_Categories_ContainsFlatbreads() {
        let flatbreadsCategory = BreadData.categories.first { $0.name == "Flatbreads" }
        XCTAssertNotNil(flatbreadsCategory, "Should have Flatbreads category")
    }

    func testBreadData_Categories_ContainsQuickBreads() {
        let quickBreadsCategory = BreadData.categories.first { $0.name.contains("Quick Breads") }
        XCTAssertNotNil(quickBreadsCategory, "Should have Quick Breads category")
    }

    func testBreadData_Categories_ContainsSpecialtyBreads() {
        let specialtyCategory = BreadData.categories.first { $0.name.contains("Specialty") }
        XCTAssertNotNil(specialtyCategory, "Should have Specialty Breads category")
    }

    func testBreadData_ContainsSourdough() {
        let sourdough = BreadData.categories
            .flatMap { $0.breads }
            .first { $0.name == "Sourdough" }

        XCTAssertNotNil(sourdough, "BreadData should contain Sourdough")
        XCTAssertTrue(sourdough?.isSourdough ?? false, "Sourdough should have isSourdough = true")
    }

    func testBreadData_NonSourdoughBreads_HaveIsSourdoughFalse() {
        let nonSourdoughBreads = BreadData.categories
            .flatMap { $0.breads }
            .filter { $0.name != "Sourdough" }

        for bread in nonSourdoughBreads {
            XCTAssertFalse(bread.isSourdough,
                          "\(bread.name) should have isSourdough = false")
        }
    }

    func testBreadData_AllBreadsHaveNames() {
        let allBreads = BreadData.categories.flatMap { $0.breads }

        for bread in allBreads {
            XCTAssertFalse(bread.name.isEmpty, "All breads should have a name")
        }
    }

    func testBreadData_AllCategoriesHaveNames() {
        for category in BreadData.categories {
            XCTAssertFalse(category.name.isEmpty, "All categories should have a name")
        }
    }

    func testBreadData_YeastBasedBreads_ContainsExpectedBreads() {
        let yeastCategory = BreadData.categories.first { $0.name == "Yeast-Based Breads" }
        let breadNames = yeastCategory?.breads.map { $0.name } ?? []

        XCTAssertTrue(breadNames.contains("Ciabatta"), "Should contain Ciabatta")
        XCTAssertTrue(breadNames.contains("Brioche"), "Should contain Brioche")
        XCTAssertTrue(breadNames.contains("Focaccia"), "Should contain Focaccia")
        XCTAssertTrue(breadNames.contains("Bagels"), "Should contain Bagels")
    }

    func testBreadData_Flatbreads_ContainsExpectedBreads() {
        let flatbreadsCategory = BreadData.categories.first { $0.name == "Flatbreads" }
        let breadNames = flatbreadsCategory?.breads.map { $0.name } ?? []

        XCTAssertTrue(breadNames.contains("Naan"), "Should contain Naan")
        XCTAssertTrue(breadNames.contains("Pita"), "Should contain Pita")
        XCTAssertTrue(breadNames.contains("Tortillas"), "Should contain Tortillas")
    }

    func testBreadData_TotalBreadCount_IsReasonable() {
        let totalBreads = BreadData.categories.flatMap { $0.breads }.count

        XCTAssertGreaterThanOrEqual(totalBreads, 15, "Should have at least 15 bread types")
        XCTAssertLessThanOrEqual(totalBreads, 50, "Should not exceed 50 bread types")
    }
}
