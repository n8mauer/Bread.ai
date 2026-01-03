import Foundation

// MARK: - Response Models

/// Response from /ask endpoint with feedback tracking info
struct AskAIResponse: Codable, Sendable {
    let response: String
    let responseId: String
    let promptVariant: String
    let cached: Bool?

    enum CodingKeys: String, CodingKey {
        case response, cached
        case responseId = "response_id"
        case promptVariant = "prompt_variant"
    }
}

/// Recipe response with feedback tracking info
struct AIRecipe: Codable, Sendable {
    let name: String
    let description: String
    let prepTime: String
    let fermentTime: String
    let bakeTime: String
    let difficulty: String
    let ingredients: [Ingredient]
    let instructions: [String]
    let tips: String
    let responseId: String
    let promptVariant: String
    let cached: Bool?

    struct Ingredient: Codable, Sendable {
        let amount: String
        let item: String
    }

    enum CodingKeys: String, CodingKey {
        case name, description, difficulty, ingredients, instructions, tips, cached
        case prepTime = "prep_time"
        case fermentTime = "ferment_time"
        case bakeTime = "bake_time"
        case responseId = "response_id"
        case promptVariant = "prompt_variant"
    }
}

/// Feedback rating types
enum FeedbackRating: String, Sendable {
    case positive
    case negative
    case neutral
}

/// Feedback request model
struct FeedbackRequest: Codable, Sendable {
    let responseId: String
    let query: String
    let response: String
    let rating: String
    let promptVariant: String
    let responseType: String
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case query, response, rating, comment
        case responseId = "response_id"
        case promptVariant = "prompt_variant"
        case responseType = "response_type"
    }
}

/// Feedback response from server
struct FeedbackResponse: Codable, Sendable {
    let success: Bool
    let message: String
}


// MARK: - Bread Service

/// Modern async/await-based service for BreadAI API
actor BreadService {
    static let shared = BreadService()

    // MARK: - Configuration
    private let baseURL = "http://localhost:8000"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Ask About Bread

    /// Ask a question about bread using async/await
    /// - Parameter query: The question to ask
    /// - Returns: The AI response with metadata
    /// - Throws: BreadServiceError if the request fails
    func askAboutBread(query: String) async throws -> AskAIResponse {
        let url = try buildURL(endpoint: "/ask")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        return try JSONDecoder().decode(AskAIResponse.self, from: data)
    }

    /// Ask about bread with fallback for offline mode
    /// - Parameter query: The question to ask
    /// - Returns: The response text (either from API or fallback)
    func askAboutBreadWithFallback(query: String) async -> (response: String, metadata: AskAIResponse?) {
        do {
            let result = try await askAboutBread(query: query)
            return (result.response, result)
        } catch {
            print("API Error: \(error.localizedDescription)")
            return (fallbackResponse(for: query), nil)
        }
    }

    // MARK: - Recipe Generation

    /// Fetch a recipe for a specific bread type
    /// - Parameter breadName: The name of the bread
    /// - Returns: The generated recipe
    /// - Throws: BreadServiceError if the request fails
    func fetchRecipe(for breadName: String) async throws -> AIRecipe {
        let url = try buildURL(endpoint: "/recipe")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Recipes take longer

        let body = ["bread_name": breadName]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        return try JSONDecoder().decode(AIRecipe.self, from: data)
    }

    // MARK: - Feedback Submission

    /// Submit feedback for a response
    /// - Parameters:
    ///   - responseId: The ID of the response being rated
    ///   - query: The original query
    ///   - response: The response text
    ///   - rating: The user's rating
    ///   - promptVariant: The prompt variant used
    ///   - responseType: Type of response (ask/recipe)
    ///   - comment: Optional user comment
    /// - Returns: Whether the feedback was submitted successfully
    @discardableResult
    func submitFeedback(
        responseId: String,
        query: String,
        response: String,
        rating: FeedbackRating,
        promptVariant: String,
        responseType: String,
        comment: String? = nil
    ) async throws -> Bool {
        let url = try buildURL(endpoint: "/feedback")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let feedbackRequest = FeedbackRequest(
            responseId: responseId,
            query: query,
            response: response,
            rating: rating.rawValue,
            promptVariant: promptVariant,
            responseType: responseType,
            comment: comment
        )

        request.httpBody = try JSONEncoder().encode(feedbackRequest)

        let (data, httpResponse) = try await session.data(for: request)

        try validateResponse(httpResponse)

        let result = try JSONDecoder().decode(FeedbackResponse.self, from: data)
        return result.success
    }

    /// Submit feedback without throwing (fire-and-forget style)
    func submitFeedbackSilently(
        responseId: String,
        query: String,
        response: String,
        rating: FeedbackRating,
        promptVariant: String,
        responseType: String,
        comment: String? = nil
    ) async -> Bool {
        do {
            return try await submitFeedback(
                responseId: responseId,
                query: query,
                response: response,
                rating: rating,
                promptVariant: promptVariant,
                responseType: responseType,
                comment: comment
            )
        } catch {
            print("Feedback submission failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Helper Methods

    private func buildURL(endpoint: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw BreadServiceError.invalidURL
        }
        return url
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BreadServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            throw BreadServiceError.badRequest
        case 401, 403:
            throw BreadServiceError.unauthorized
        case 404:
            throw BreadServiceError.notFound
        case 429:
            throw BreadServiceError.rateLimited
        case 500...599:
            throw BreadServiceError.serverError
        default:
            throw BreadServiceError.unknownError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Errors

    enum BreadServiceError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case badRequest
        case unauthorized
        case notFound
        case rateLimited
        case serverError
        case noData
        case unknownError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid server URL"
            case .invalidResponse:
                return "Invalid server response"
            case .badRequest:
                return "Invalid request"
            case .unauthorized:
                return "Unauthorized access"
            case .notFound:
                return "Resource not found"
            case .rateLimited:
                return "Too many requests. Please try again later."
            case .serverError:
                return "Server error occurred"
            case .noData:
                return "No data received"
            case .unknownError(let statusCode):
                return "Unknown error (status: \(statusCode))"
            }
        }
    }

    // MARK: - Fallback Responses

    private func fallbackResponse(for query: String) -> String {
        let lowercaseQuery = query.lowercased()

        switch true {
        case lowercaseQuery.contains("sourdough"):
            return "Sourdough bread is made by fermenting dough using naturally occurring lactobacilli and yeast. It has a tangy flavor and is known for its chewy texture and crispy crust."
        case lowercaseQuery.contains("rye"):
            return "Rye bread is made with flour from rye grain. It tends to be denser and darker than bread made from wheat flour and has a stronger, more distinctive flavor."
        case lowercaseQuery.contains("gluten"):
            return "Gluten is a group of proteins found in certain grains like wheat, barley, and rye. For those with celiac disease or gluten sensitivity, there are many gluten-free bread options made from alternative flours."
        case lowercaseQuery.contains("recipe"), lowercaseQuery.contains("make"):
            return "A basic bread recipe includes flour, water, salt, and yeast. Mix ingredients, knead the dough, let it rise, shape it, let it rise again, and then bake until golden brown."
        case lowercaseQuery.contains("history"):
            return "Bread has been a staple food for thousands of years. The earliest breads were likely flat and unleavened. Evidence of bread-making dates back to 14,000 years ago in Jordan."
        default:
            return "I'm currently offline. Please check your connection and try again. I can answer questions about bread types, recipes, baking techniques, and more!"
        }
    }
}

// MARK: - Convenience Extensions

extension BreadService {
    /// Check if the service is reachable
    func checkHealth() async -> Bool {
        do {
            let url = try buildURL(endpoint: "/health")
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
