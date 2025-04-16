import Foundation

class BreadService {
    static let shared = BreadService()
    
    private init() {}
    
    func askAboutBread(query: String, completion: @escaping (String) -> Void) {
        // In a real implementation, this would call out to an AI service
        // For now, we'll just return some mock responses based on keywords in the query
        
        let lowercaseQuery = query.lowercased()
        
        let response: String
        
        switch true {
        case lowercaseQuery.contains("sourdough"):
            response = "Sourdough bread is made by fermenting dough using naturally occurring lactobacilli and yeast. It has a tangy flavor and is known for its chewy texture and crispy crust."
        case lowercaseQuery.contains("rye"):
            response = "Rye bread is made with flour from rye grain. It tends to be denser and darker than bread made from wheat flour and has a stronger, more distinctive flavor."
        case lowercaseQuery.contains("gluten"):
            response = "Gluten is a group of proteins found in certain grains like wheat, barley, and rye. For those with celiac disease or gluten sensitivity, there are many gluten-free bread options made from alternative flours."
        case lowercaseQuery.contains("recipe") || lowercaseQuery.contains("make"):
            response = "A basic bread recipe includes flour, water, salt, and yeast. Mix ingredients, knead the dough, let it rise, shape it, let it rise again, and then bake until golden brown. The exact process depends on the type of bread."
        case lowercaseQuery.contains("history"):
            response = "Bread has been a staple food for thousands of years. The earliest breads were likely flat and unleavened. Evidence of bread-making dates back to 14,000 years ago in Jordan. Each culture developed its own variations of bread based on available ingredients."
        default:
            response = "I'd be happy to answer questions about different types of bread, ingredients, baking techniques, recipes, or the history of bread. What would you like to know?"
        }
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(response)
        }
    }
}
