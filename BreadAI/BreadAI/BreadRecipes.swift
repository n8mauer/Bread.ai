import Foundation

// Model for bread categories and types
struct BreadCategory: Identifiable {
    let id = UUID()
    let name: String
    let breads: [Bread]
}

struct Bread: Identifiable {
    let id = UUID()
    let name: String
    let isSourdough: Bool
    let image: String // Image name in assets
    
    init(name: String, isSourdough: Bool = false, image: String = "bread.ai logo no background") {
        self.name = name
        self.isSourdough = isSourdough
        self.image = image
    }
}

// Data for all bread categories and types
class BreadData {
    static let categories: [BreadCategory] = [
        BreadCategory(name: "Yeast-Based Breads", breads: [
            Bread(name: "White Sandwich Bread"),
            Bread(name: "Whole Wheat Bread"),
            Bread(name: "Sourdough", isSourdough: true),
            Bread(name: "Brioche"),
            Bread(name: "Challah"),
            Bread(name: "Focaccia"),
            Bread(name: "Ciabatta"),
            Bread(name: "Bagels"),
            Bread(name: "Dinner Rolls")
        ]),
        BreadCategory(name: "Flatbreads", breads: [
            Bread(name: "Naan"),
            Bread(name: "Pita"),
            Bread(name: "Tortillas"),
            Bread(name: "Lefse")
        ]),
        BreadCategory(name: "Quick Breads (No Yeast)", breads: [
            Bread(name: "Banana Bread"),
            Bread(name: "Zucchini Bread"),
            Bread(name: "Pumpkin Bread"),
            Bread(name: "Cornbread"),
            Bread(name: "Beer Bread")
        ]),
        BreadCategory(name: "Specialty and Ethnic Breads", breads: [
            Bread(name: "Rye Bread"),
            Bread(name: "Irish Soda Bread"),
            Bread(name: "Lavash"),
            Bread(name: "Anadama Bread")
        ])
    ]
}