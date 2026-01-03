import Foundation

// MARK: - Response Models

/// Response from /ask endpoint with feedback tracking info
struct AskAIResponse: Codable {
    let response: String
    let responseId: String
    let promptVariant: String

    enum CodingKeys: String, CodingKey {
        case response
        case responseId = "response_id"
        case promptVariant = "prompt_variant"
    }
}

/// Recipe response with feedback tracking info
struct AIRecipe: Codable {
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

    struct Ingredient: Codable {
        let amount: String
        let item: String
    }

    enum CodingKeys: String, CodingKey {
        case name, description, difficulty, ingredients, instructions, tips
        case prepTime = "prep_time"
        case fermentTime = "ferment_time"
        case bakeTime = "bake_time"
        case responseId = "response_id"
        case promptVariant = "prompt_variant"
    }
}

/// Feedback rating types
enum FeedbackRating: String {
    case positive
    case negative
    case neutral
}

/// Feedback request model
struct FeedbackRequest: Codable {
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


// MARK: - Bread Service

class BreadService {
    static let shared = BreadService()

    // MARK: - Configuration
    // Change this URL to your deployed backend URL
    // For local development: "http://localhost:8000"
    // For production: "https://breadai-api.onrender.com" (or your Render URL)
    private let baseURL = "http://localhost:8000"

    private init() {}

    // MARK: - Ask About Bread (with feedback tracking)

    func askAboutBread(query: String, completion: @escaping (AskAIResponse?) -> Void) {
        guard let url = URL(string: "\(baseURL)/ask") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ["query": query]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let data = data else {
                    completion(nil)
                    return
                }

                do {
                    let aiResponse = try JSONDecoder().decode(AskAIResponse.self, from: data)
                    completion(aiResponse)
                } catch {
                    print("Decode error: \(error)")
                    completion(nil)
                }
            }
        }.resume()
    }

    // Legacy method for backwards compatibility
    func askAboutBreadLegacy(query: String, completion: @escaping (String) -> Void) {
        askAboutBread(query: query) { [weak self] response in
            if let response = response {
                completion(response.response)
            } else {
                completion(self?.fallbackResponse(for: query) ?? "Sorry, I couldn't process that request.")
            }
        }
    }

    // MARK: - Recipe Generation

    func fetchRecipe(for breadName: String, completion: @escaping (Result<AIRecipe, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/recipe") else {
            completion(.failure(BreadServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body = ["bread_name": breadName]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(BreadServiceError.serverError))
                    return
                }

                guard let data = data else {
                    completion(.failure(BreadServiceError.noData))
                    return
                }

                do {
                    let recipe = try JSONDecoder().decode(AIRecipe.self, from: data)
                    completion(.success(recipe))
                } catch {
                    print("Recipe decode error: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Feedback Submission

    func submitFeedback(
        responseId: String,
        query: String,
        response: String,
        rating: FeedbackRating,
        promptVariant: String,
        responseType: String,
        comment: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/feedback") else {
            completion(false)
            return
        }

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

        do {
            request.httpBody = try JSONEncoder().encode(feedbackRequest)
        } catch {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Feedback error: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion(false)
                    return
                }

                completion(true)
            }
        }.resume()
    }

    // MARK: - Errors

    enum BreadServiceError: Error, LocalizedError {
        case invalidURL
        case serverError
        case noData

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid server URL"
            case .serverError: return "Server error occurred"
            case .noData: return "No data received"
            }
        }
    }

    // MARK: - Fallback responses for offline mode

    private func fallbackResponse(for query: String) -> String {
        let lowercaseQuery = query.lowercased()

        switch true {
        case lowercaseQuery.contains("sourdough"):
            return "Sourdough bread is made by fermenting dough using naturally occurring lactobacilli and yeast. It has a tangy flavor and is known for its chewy texture and crispy crust."
        case lowercaseQuery.contains("rye"):
            return "Rye bread is made with flour from rye grain. It tends to be denser and darker than bread made from wheat flour and has a stronger, more distinctive flavor."
        case lowercaseQuery.contains("gluten"):
            return "Gluten is a group of proteins found in certain grains like wheat, barley, and rye. For those with celiac disease or gluten sensitivity, there are many gluten-free bread options made from alternative flours."
        case lowercaseQuery.contains("recipe") || lowercaseQuery.contains("make"):
            return "A basic bread recipe includes flour, water, salt, and yeast. Mix ingredients, knead the dough, let it rise, shape it, let it rise again, and then bake until golden brown."
        case lowercaseQuery.contains("history"):
            return "Bread has been a staple food for thousands of years. The earliest breads were likely flat and unleavened. Evidence of bread-making dates back to 14,000 years ago in Jordan."
        default:
            return "I'm currently offline. Please check your connection and try again. I can answer questions about bread types, recipes, baking techniques, and more!"
        }
    }
}
