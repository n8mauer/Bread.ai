import SwiftUI

struct RecipeDetailView: View {
    let bread: Bread
    
    var body: some View {
        if bread.isSourdough {
            SourdoughRecipeView()
        } else {
            ComingSoonView(breadType: bread.name)
        }
    }
}

struct SourdoughRecipeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Sourdough Bread")
                            .font(.largeTitle.bold())
                            .foregroundColor(.breadBrown)
                        
                        Text("Classic artisan bread with natural leavening")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image("bread.ai logo no background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                }
                .padding(.bottom)
                
                // Recipe Info
                HStack(spacing: 30) {
                    VStack {
                        Text("Prep Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("20 min")
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Ferment")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("8-12 hrs")
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Bake Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("45 min")
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Difficulty")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Medium")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Ingredients
                Group {
                    Text("Ingredients")
                        .font(.title2.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top)
                    
                    // Starter
                    Text("For the starter:")
                        .font(.headline)
                        .padding(.top, 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        IngredientRow(amount: "100g", ingredient: "mature sourdough starter")
                        IngredientRow(amount: "150g", ingredient: "bread flour")
                        IngredientRow(amount: "150g", ingredient: "filtered water (room temperature)")
                    }
                    
                    // Main dough
                    Text("For the main dough:")
                        .font(.headline)
                        .padding(.top, 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        IngredientRow(amount: "500g", ingredient: "bread flour")
                        IngredientRow(amount: "337g", ingredient: "filtered water (room temperature)")
                        IngredientRow(amount: "10g", ingredient: "salt")
                        IngredientRow(amount: "200g", ingredient: "active, bubbly sourdough starter")
                    }
                }
                
                // Instructions
                Group {
                    Text("Instructions")
                        .font(.title2.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        InstructionRow(step: 1, text: "Prepare the starter: Mix the starter ingredients in a clean jar, cover loosely and leave at room temperature for 8-12 hours until bubbly and doubled in size.")
                        
                        InstructionRow(step: 2, text: "Autolyse: Mix flour and water (no salt or starter yet) in a large bowl until no dry flour remains. Cover and rest for 30 minutes.")
                        
                        InstructionRow(step: 3, text: "Add starter and salt: Add the bubbly starter and salt to the dough, mix thoroughly using wet hands or a dough scraper.")
                        
                        InstructionRow(step: 4, text: "Bulk fermentation: For the next 3-4 hours, perform 4-6 sets of stretch and folds, spaced 30 minutes apart. Cover and let rise until doubled in size.")
                        
                        InstructionRow(step: 5, text: "Shape: Turn the dough onto a lightly floured surface, shape into a round or oval loaf, and place in a floured banneton or bowl lined with a floured kitchen towel.")
                        
                        InstructionRow(step: 6, text: "Final proof: Cover and refrigerate for 12-16 hours (overnight).")
                        
                        InstructionRow(step: 7, text: "Preheat: Place a Dutch oven in the oven and preheat to 500°F (260°C) for 45-60 minutes.")
                        
                        InstructionRow(step: 8, text: "Bake: Carefully transfer the cold dough to the hot Dutch oven, score the top with a sharp knife or razor blade, cover, and bake for 20 minutes.")
                        
                        InstructionRow(step: 9, text: "Reduce the temperature to 450°F (230°C), remove the lid, and bake for another 20-25 minutes until deep golden brown.")
                        
                        InstructionRow(step: 10, text: "Cool: Transfer to a wire rack and cool completely for at least 1 hour before slicing.")
                    }
                }
                
                // Baker's Notes
                Group {
                    Text("Baker's Notes")
                        .font(.title2.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top)
                    
                    Text("For best results, use a kitchen scale to weigh ingredients precisely. The temperature of your kitchen affects fermentation times - in warm weather, reduce bulk fermentation and proofing times; in cold weather, extend them. A mature, active starter is crucial for proper rise and flavor development.")
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(Color.breadBeige.ignoresSafeArea())
        .navigationTitle("Sourdough Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ComingSoonView: View {
    let breadType: String
    
    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image("bread.ai logo no background")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                
                Text(breadType)
                    .font(.largeTitle.bold())
                    .foregroundColor(.breadBrown)
                
                Text("Recipe Coming Soon!")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                
                Text("Our bakers are perfecting this recipe right now. Check back soon to start baking your own \(breadType)!")
                    .multilineTextAlignment(.center)
                    .padding()
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 50)
        }
        .navigationTitle(breadType)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IngredientRow: View {
    let amount: String
    let ingredient: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(amount)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
                .foregroundColor(.gray)
            
            Text(ingredient)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct InstructionRow: View {
    let step: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(step)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.breadBrown)
                .clipShape(Circle())
            
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#if compiler(>=5.9)
#Preview("Sourdough") {
    NavigationView {
        RecipeDetailView(bread: Bread(name: "Sourdough", isSourdough: true))
    }
}

#Preview("Coming Soon") {
    NavigationView {
        RecipeDetailView(bread: Bread(name: "Ciabatta"))
    }
}
#endif