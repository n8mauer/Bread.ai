import SwiftUI

struct RecipeDetailView: View {
    let bread: Bread
    @ObservedObject private var gamification = GamificationManager.shared

    var body: some View {
        if bread.isSourdough {
            SourdoughRecipeView()
                .onAppear {
                    gamification.logRecipeViewed(breadType: bread.name)
                }
        } else {
            AIRecipeView(breadType: bread.name)
                .onAppear {
                    gamification.logRecipeViewed(breadType: bread.name)
                }
        }
    }
}

struct SourdoughRecipeView: View {
    @ObservedObject private var gamification = GamificationManager.shared
    @State private var showBakeLogged = false

    // Ingredient checklist state
    @State private var checkedIngredients: Set<Int> = []

    // Guided mode state
    @State private var isGuidedMode = false
    @State private var currentStep = 0
    @State private var completedSteps: Set<Int> = []

    // Ask AI state
    @State private var showAIHelp = false
    @State private var aiHelpStep: Int?
    @State private var aiHelpResponse: String = ""
    @State private var isLoadingAIHelp = false

    // Timer state
    @State private var showTimer = false
    @State private var timerMinutes = 30

    let ingredients = [
        (amount: "100g", ingredient: "mature sourdough starter"),
        (amount: "150g", ingredient: "bread flour"),
        (amount: "150g", ingredient: "filtered water (room temperature)"),
        (amount: "500g", ingredient: "bread flour"),
        (amount: "337g", ingredient: "filtered water (room temperature)"),
        (amount: "10g", ingredient: "salt"),
        (amount: "200g", ingredient: "active, bubbly sourdough starter")
    ]

    let instructions = [
        "Prepare the starter: Mix the starter ingredients in a clean jar, cover loosely and leave at room temperature for 8-12 hours until bubbly and doubled in size.",
        "Autolyse: Mix flour and water (no salt or starter yet) in a large bowl until no dry flour remains. Cover and rest for 30 minutes.",
        "Add starter and salt: Add the bubbly starter and salt to the dough, mix thoroughly using wet hands or a dough scraper.",
        "Bulk fermentation: For the next 3-4 hours, perform 4-6 sets of stretch and folds, spaced 30 minutes apart. Cover and let rise until doubled in size.",
        "Shape: Turn the dough onto a lightly floured surface, shape into a round or oval loaf, and place in a floured banneton or bowl lined with a floured kitchen towel.",
        "Final proof: Cover and refrigerate for 12-16 hours (overnight).",
        "Preheat: Place a Dutch oven in the oven and preheat to 500°F (260°C) for 45-60 minutes.",
        "Bake: Carefully transfer the cold dough to the hot Dutch oven, score the top with a sharp knife or razor blade, cover, and bake for 20 minutes.",
        "Reduce the temperature to 450°F (230°C), remove the lid, and bake for another 20-25 minutes until deep golden brown.",
        "Cool: Transfer to a wire rack and cool completely for at least 1 hour before slicing."
    ]

    var progressPercentage: Double {
        guard !instructions.isEmpty else { return 0 }
        return Double(completedSteps.count) / Double(instructions.count)
    }

    var body: some View {
        ZStack {
            if isGuidedMode {
                guidedModeView
            } else {
                normalRecipeView
            }
        }
        .background(Color.breadBeige.ignoresSafeArea())
        .navigationTitle("Sourdough Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $gamification.showBadgeUnlockAlert) {
            Alert(
                title: Text("Badge Unlocked!"),
                message: Text("You earned: \(gamification.recentlyUnlockedBadge?.name ?? "")"),
                dismissButton: .default(Text("Awesome!"))
            )
        }
        .sheet(isPresented: $showAIHelp) {
            aiHelpSheet
        }
        .sheet(isPresented: $showTimer) {
            timerSheet
        }
    }

    var normalRecipeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress Bar
                if !completedSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recipe Progress")
                                .font(.caption.bold())
                                .foregroundColor(.breadBrown)
                            Spacer()
                            Text("\(Int(progressPercentage * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(.breadBrown)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(Color.breadBrown)
                                    .frame(width: geometry.size.width * progressPercentage, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                }

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
                    HStack {
                        Text("Ingredients")
                            .font(.title2.bold())
                            .foregroundColor(.breadBrown)
                        Spacer()
                        Text("\(checkedIngredients.count) of \(ingredients.count) ready")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.breadBrown.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.top)

                    // Starter
                    Text("For the starter:")
                        .font(.headline)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 8) {
                        CheckableIngredientRow(index: 0, amount: ingredients[0].amount, ingredient: ingredients[0].ingredient, isChecked: checkedIngredients.contains(0)) {
                            toggleIngredient(0)
                        }
                        CheckableIngredientRow(index: 1, amount: ingredients[1].amount, ingredient: ingredients[1].ingredient, isChecked: checkedIngredients.contains(1)) {
                            toggleIngredient(1)
                        }
                        CheckableIngredientRow(index: 2, amount: ingredients[2].amount, ingredient: ingredients[2].ingredient, isChecked: checkedIngredients.contains(2)) {
                            toggleIngredient(2)
                        }
                    }

                    // Main dough
                    Text("For the main dough:")
                        .font(.headline)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 8) {
                        CheckableIngredientRow(index: 3, amount: ingredients[3].amount, ingredient: ingredients[3].ingredient, isChecked: checkedIngredients.contains(3)) {
                            toggleIngredient(3)
                        }
                        CheckableIngredientRow(index: 4, amount: ingredients[4].amount, ingredient: ingredients[4].ingredient, isChecked: checkedIngredients.contains(4)) {
                            toggleIngredient(4)
                        }
                        CheckableIngredientRow(index: 5, amount: ingredients[5].amount, ingredient: ingredients[5].ingredient, isChecked: checkedIngredients.contains(5)) {
                            toggleIngredient(5)
                        }
                        CheckableIngredientRow(index: 6, amount: ingredients[6].amount, ingredient: ingredients[6].ingredient, isChecked: checkedIngredients.contains(6)) {
                            toggleIngredient(6)
                        }
                    }
                }
                
                // Instructions
                Group {
                    HStack {
                        Text("Instructions")
                            .font(.title2.bold())
                            .foregroundColor(.breadBrown)
                        Spacer()
                        Text("Step \(completedSteps.count) of \(instructions.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)

                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                            EnhancedInstructionRow(
                                step: index + 1,
                                text: instruction,
                                isCompleted: completedSteps.contains(index),
                                onToggleComplete: {
                                    toggleStepCompletion(index)
                                },
                                onAskAI: {
                                    askAIForHelp(step: index + 1, text: instruction)
                                },
                                onStartTimer: {
                                    if let minutes = extractTimeInMinutes(from: instruction) {
                                        timerMinutes = minutes
                                        showTimer = true
                                    }
                                }
                            )
                        }
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

                // Start Cooking Button
                Button(action: {
                    currentStep = 0
                    isGuidedMode = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Cooking Mode")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.breadBrown.opacity(0.8))
                    .cornerRadius(12)
                }
                .padding(.top, 10)

                // Log Bake Button
                Button(action: {
                    gamification.logBake(breadType: "Sourdough")
                    showBakeLogged = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            showBakeLogged = false
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: showBakeLogged ? "checkmark.circle.fill" : "flame.fill")
                        Text(showBakeLogged ? "Bake Logged!" : "I Made This!")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(showBakeLogged ? Color.green : Color.breadBrown)
                    .cornerRadius(12)
                }
                .padding(.top, 20)
                .disabled(showBakeLogged)
            }
            .padding()
        }
    }

    var guidedModeView: some View {
        VStack(spacing: 0) {
            // Header with exit button
            HStack {
                Button(action: {
                    isGuidedMode = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Exit")
                    }
                    .foregroundColor(.breadBrown)
                }
                Spacer()
                Text("Step \(currentStep + 1) of \(instructions.count)")
                    .font(.headline)
                    .foregroundColor(.breadBrown)
            }
            .padding()
            .background(Color.white.opacity(0.95))

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)

                    Rectangle()
                        .fill(Color.breadBrown)
                        .frame(width: geometry.size.width * (Double(currentStep + 1) / Double(instructions.count)), height: 4)
                }
            }
            .frame(height: 4)

            ScrollView {
                VStack(spacing: 30) {
                    // Current step
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Step \(currentStep + 1)")
                            .font(.title3.bold())
                            .foregroundColor(.breadBrown)

                        Text(instructions[currentStep])
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)

                        // Timer button if applicable
                        if let minutes = extractTimeInMinutes(from: instructions[currentStep]) {
                            Button(action: {
                                timerMinutes = minutes
                                showTimer = true
                            }) {
                                HStack {
                                    Image(systemName: "timer")
                                    Text("Start \(minutes) min timer")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                        }

                        // Ask AI button
                        Button(action: {
                            askAIForHelp(step: currentStep + 1, text: instructions[currentStep])
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Ask AI for Help")
                            }
                            .font(.headline)
                            .foregroundColor(.breadBrown)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.breadBrown, lineWidth: 2)
                            )
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(15)
                }
                .padding()
            }

            // Navigation buttons
            HStack(spacing: 20) {
                Button(action: {
                    if currentStep > 0 {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.headline)
                    .foregroundColor(currentStep > 0 ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentStep > 0 ? Color.breadBrown : Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                .disabled(currentStep == 0)

                Button(action: {
                    completedSteps.insert(currentStep)
                    if currentStep < instructions.count - 1 {
                        currentStep += 1
                    } else {
                        isGuidedMode = false
                    }
                }) {
                    HStack {
                        Text(currentStep < instructions.count - 1 ? "Next" : "Finish")
                        Image(systemName: currentStep < instructions.count - 1 ? "chevron.right" : "checkmark.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.breadBrown)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.white.opacity(0.95))
        }
        .background(Color.breadBeige.ignoresSafeArea())
    }

    var aiHelpSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoadingAIHelp {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Getting AI help...")
                            .font(.headline)
                            .foregroundColor(.breadBrown)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Step \(aiHelpStep ?? 1)")
                                .font(.headline)
                                .foregroundColor(.breadBrown)

                            Text(aiHelpResponse)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAIHelp = false
                    }
                }
            }
        }
    }

    var timerSheet: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundColor(.breadBrown)

                Text("\(timerMinutes) minutes")
                    .font(.largeTitle.bold())
                    .foregroundColor(.breadBrown)

                Text("Timer feature will be integrated with system timer")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showTimer = false
                    }
                }
            }
        }
    }

    func toggleIngredient(_ index: Int) {
        if checkedIngredients.contains(index) {
            checkedIngredients.remove(index)
        } else {
            checkedIngredients.insert(index)
        }
    }

    func toggleStepCompletion(_ index: Int) {
        if completedSteps.contains(index) {
            completedSteps.remove(index)
        } else {
            completedSteps.insert(index)
        }
    }

    func askAIForHelp(step: Int, text: String) {
        aiHelpStep = step
        aiHelpResponse = ""
        isLoadingAIHelp = true
        showAIHelp = true

        Task {
            let query = "Help me with step \(step) of my sourdough bread recipe: \(text)"
            let result = await BreadService.shared.askAboutBreadWithFallback(query: query)

            await MainActor.run {
                aiHelpResponse = result.response
                isLoadingAIHelp = false
            }
        }
    }

    func extractTimeInMinutes(from text: String) -> Int? {
        let lowercased = text.lowercased()

        // Look for patterns like "30 minutes", "8-12 hours", "45-60 minutes"
        if lowercased.contains("30 minutes") || lowercased.contains("30 min") {
            return 30
        } else if lowercased.contains("45-60 minutes") || lowercased.contains("45 min") {
            return 45
        } else if lowercased.contains("20-25 minutes") || lowercased.contains("20 minutes") {
            return 20
        } else if lowercased.contains("8-12 hours") || lowercased.contains("12-16 hours") {
            // For hours, convert to minutes (use lower bound)
            if lowercased.contains("8-12") {
                return 480 // 8 hours
            } else if lowercased.contains("12-16") {
                return 720 // 12 hours
            }
        } else if lowercased.contains("3-4 hours") {
            return 180 // 3 hours
        } else if lowercased.contains("1 hour") {
            return 60
        }

        return nil
    }
}

struct AIRecipeView: View {
    let breadType: String
    @State private var recipe: AIRecipe?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showBakeLogged = false
    @ObservedObject private var gamification = GamificationManager.shared

    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Generating \(breadType) recipe...")
                        .font(.headline)
                        .foregroundColor(.breadBrown)
                    Text("Our AI baker is crafting the perfect recipe")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Couldn't load recipe")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Try Again") {
                        loadRecipe()
                    }
                    .padding()
                    .background(Color.breadBrown)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else if let recipe = recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.breadBrown)

                                Text(recipe.description)
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

                        // AI Badge
                        HStack {
                            Image(systemName: "sparkles")
                            Text("AI Generated Recipe")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.breadBrown.opacity(0.8))
                        .cornerRadius(20)

                        // Recipe Info
                        HStack(spacing: 20) {
                            RecipeInfoBadge(label: "Prep", value: recipe.prepTime)
                            if recipe.fermentTime != "N/A" {
                                RecipeInfoBadge(label: "Ferment", value: recipe.fermentTime)
                            }
                            RecipeInfoBadge(label: "Bake", value: recipe.bakeTime)
                            RecipeInfoBadge(label: "Difficulty", value: recipe.difficulty)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                        // Ingredients
                        Text("Ingredients")
                            .font(.title2.bold())
                            .foregroundColor(.breadBrown)
                            .padding(.top)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.ingredients, id: \.item) { ingredient in
                                IngredientRow(amount: ingredient.amount, ingredient: ingredient.item)
                            }
                        }

                        // Instructions
                        Text("Instructions")
                            .font(.title2.bold())
                            .foregroundColor(.breadBrown)
                            .padding(.top)

                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                InstructionRow(step: index + 1, text: instruction)
                            }
                        }

                        // Tips
                        Text("Baker's Tips")
                            .font(.title2.bold())
                            .foregroundColor(.breadBrown)
                            .padding(.top)

                        Text(recipe.tips)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)

                        // Log Bake Button
                        Button(action: {
                            gamification.logBake(breadType: breadType)
                            showBakeLogged = true
                            Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                await MainActor.run {
                                    showBakeLogged = false
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: showBakeLogged ? "checkmark.circle.fill" : "flame.fill")
                                Text(showBakeLogged ? "Bake Logged!" : "I Made This!")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showBakeLogged ? Color.green : Color.breadBrown)
                            .cornerRadius(12)
                        }
                        .padding(.top, 20)
                        .disabled(showBakeLogged)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(breadType)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRecipe()
        }
        .alert(isPresented: $gamification.showBadgeUnlockAlert) {
            Alert(
                title: Text("Badge Unlocked!"),
                message: Text("You earned: \(gamification.recentlyUnlockedBadge?.name ?? "")"),
                dismissButton: .default(Text("Awesome!"))
            )
        }
    }

    private func loadRecipe() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedRecipe = try await BreadService.shared.fetchRecipe(for: breadType)
                await MainActor.run {
                    recipe = fetchedRecipe
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct RecipeInfoBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
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

struct CheckableIngredientRow: View {
    let index: Int
    let amount: String
    let ingredient: String
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? .breadBrown : .gray)
                    .font(.title3)

                Text(amount)
                    .font(.subheadline)
                    .frame(width: 60, alignment: .leading)
                    .foregroundColor(.gray)
                    .strikethrough(isChecked)

                Text(ingredient)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .strikethrough(isChecked)

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedInstructionRow: View {
    let step: Int
    let text: String
    let isCompleted: Bool
    let onToggleComplete: () -> Void
    let onAskAI: () -> Void
    let onStartTimer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 15) {
                // Step number with checkbox
                Button(action: onToggleComplete) {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : Color.breadBrown)
                            .frame(width: 30, height: 30)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else {
                            Text("\(step)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }

                Text(text)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .gray : .primary)

                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                // Ask AI button
                Button(action: onAskAI) {
                    HStack(spacing: 5) {
                        Image(systemName: "questionmark.circle")
                        Text("Ask AI")
                    }
                    .font(.caption)
                    .foregroundColor(.breadBrown)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.breadBrown, lineWidth: 1)
                    )
                }

                // Timer button (only show if step mentions time)
                if hasTimeReference(text) {
                    Button(action: onStartTimer) {
                        HStack(spacing: 5) {
                            Image(systemName: "timer")
                            Text("Timer")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.leading, 45)
        }
    }

    func hasTimeReference(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return lowercased.contains("minutes") || lowercased.contains("hours") || lowercased.contains("min")
    }
}

#if compiler(>=5.9)
#Preview("Sourdough") {
    NavigationView {
        RecipeDetailView(bread: Bread(name: "Sourdough", isSourdough: true))
    }
}

#Preview("AI Recipe") {
    NavigationView {
        RecipeDetailView(bread: Bread(name: "Ciabatta"))
    }
}
#endif