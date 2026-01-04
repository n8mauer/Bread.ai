import Foundation

struct BakingTechnique: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let detailedExplanation: String
    let tips: [String]
    let difficulty: String
}

class TechniqueData {
    static let techniques: [BakingTechnique] = [
        BakingTechnique(
            title: "Kneading",
            description: "The process of working dough to develop gluten structure",
            detailedExplanation: "Kneading is a fundamental bread-making technique that develops the gluten network in dough. This process involves folding, pressing, and turning the dough repeatedly, typically for 8-12 minutes by hand or 5-7 minutes with a stand mixer. The gluten proteins align and create an elastic structure that traps gases during fermentation, giving bread its characteristic texture and rise.",
            tips: [
                "Use the heel of your hand to push the dough away from you",
                "Fold it back, rotate a quarter turn, and repeat",
                "The dough is ready when it's smooth and elastic",
                "The windowpane test can confirm proper gluten development",
                "Don't over-knead; it can make the bread tough"
            ],
            difficulty: "Beginner"
        ),
        BakingTechnique(
            title: "Proofing",
            description: "Allowing dough to rise before baking",
            detailedExplanation: "Proofing (or proving) is the final rise dough undergoes after shaping and before baking. During this time, yeast continues to ferment, producing carbon dioxide that expands the dough. Proper proofing is crucial - under-proofed bread will be dense, while over-proofed bread may collapse. The ideal proofing time depends on temperature, dough composition, and desired flavor profile.",
            tips: [
                "Cover dough to prevent skin formation",
                "Ideal proofing temperature is 75-80°F (24-27°C)",
                "Use the poke test: dough should spring back slowly",
                "Humid environments prevent dough from drying out",
                "Cold proofing in the fridge develops more complex flavors"
            ],
            difficulty: "Beginner"
        ),
        BakingTechnique(
            title: "Shaping",
            description: "Forming dough into its final shape before the final rise",
            detailedExplanation: "Shaping is the art of forming your dough into the desired final form, whether it's a boule (round), batard (oval), or baguette. This step creates surface tension that helps the bread hold its shape and rise properly. Good shaping technique ensures even crumb structure and an attractive final loaf. It's performed after bulk fermentation and before the final proof.",
            tips: [
                "Work on a lightly floured surface to prevent sticking",
                "Create surface tension by pulling the dough toward you",
                "Be gentle to avoid degassing the dough too much",
                "Let dough rest if it resists shaping (bench rest)",
                "Practice makes perfect - each dough type behaves differently"
            ],
            difficulty: "Intermediate"
        ),
        BakingTechnique(
            title: "Scoring",
            description: "Cutting patterns into dough before baking",
            detailedExplanation: "Scoring (or slashing) creates controlled weak points in the dough's surface, directing where steam will escape during baking. This prevents random bursting and creates the signature 'ear' and expansion pattern. Scoring is done with a sharp blade (lame) just before the bread enters the oven. The angle, depth, and pattern of cuts significantly affect the bread's final appearance and oven spring.",
            tips: [
                "Use a very sharp blade or lame at a 30-45° angle",
                "Score quickly and confidently in one smooth motion",
                "Depth should be about 1/4 to 1/2 inch",
                "Score right before baking for best results",
                "Spray dough lightly with water if surface is dry"
            ],
            difficulty: "Intermediate"
        ),
        BakingTechnique(
            title: "Autolyse",
            description: "Resting flour and water before adding other ingredients",
            detailedExplanation: "Autolyse is a technique where flour and water are mixed and allowed to rest (typically 20-60 minutes) before adding salt and yeast. During this rest, flour fully hydrates and enzymes begin breaking down starches and proteins. This results in better gluten development with less kneading, improved dough extensibility, enhanced flavor, and a more open crumb structure.",
            tips: [
                "Mix only flour and water initially",
                "Rest for 20-60 minutes at room temperature",
                "Cover to prevent drying",
                "Add salt and yeast after the autolyse period",
                "Especially beneficial for high-hydration doughs"
            ],
            difficulty: "Intermediate"
        ),
        BakingTechnique(
            title: "Stretch and Fold",
            description: "A gentle method of developing gluten without traditional kneading",
            detailedExplanation: "Stretch and fold is a no-knead technique that develops gluten structure through a series of gentle stretches and folds during bulk fermentation. Typically performed 3-4 times at 30-minute intervals, this method is especially useful for wet, sticky doughs. It strengthens the dough while preserving the air bubbles created during fermentation, resulting in an open, airy crumb.",
            tips: [
                "Wet your hands to prevent sticking",
                "Grab one side of dough and stretch it up, then fold over",
                "Rotate bowl 90° and repeat 3-4 times",
                "Perform every 30 minutes during first 2 hours of bulk fermentation",
                "You'll feel the dough get stronger and more elastic"
            ],
            difficulty: "Beginner"
        ),
        BakingTechnique(
            title: "Windowpane Test",
            description: "Testing if dough has been kneaded enough",
            detailedExplanation: "The windowpane test is a simple way to check if gluten is adequately developed in your dough. Take a small piece of dough and gently stretch it between your fingers. If the dough stretches thin enough to see light through it without tearing (like a windowpane), the gluten is well-developed. If it tears easily, more kneading or folding is needed.",
            tips: [
                "Take a golf-ball sized piece of dough",
                "Stretch gently and slowly with both hands",
                "Look for a thin, translucent membrane",
                "If it tears, continue kneading and test again",
                "Not all breads need to pass this test (e.g., ciabatta)"
            ],
            difficulty: "Beginner"
        ),
        BakingTechnique(
            title: "Pre-shaping",
            description: "Creating initial tension before final shaping",
            detailedExplanation: "Pre-shaping is an intermediate step between dividing the dough and final shaping. It creates a gentle initial structure and allows the dough to relax before final shaping. This technique is especially important when making multiple loaves or when working with high-hydration doughs. After pre-shaping, the dough rests (bench rest) for 20-30 minutes before final shaping.",
            tips: [
                "Divide dough into equal portions if making multiple loaves",
                "Gently form into rough rounds or rectangles",
                "Don't over-tighten during pre-shaping",
                "Let dough rest covered for 20-30 minutes",
                "Final shaping will be easier after proper bench rest"
            ],
            difficulty: "Intermediate"
        ),
        BakingTechnique(
            title: "Lamination",
            description: "Stretching dough into a thin sheet and folding",
            detailedExplanation: "Lamination involves stretching dough into a very thin, translucent sheet on a work surface, then folding it back onto itself. This technique distributes ingredients evenly (like add-ins or levain), develops gluten, and creates strength while maintaining an open crumb. It's particularly useful for high-hydration sourdoughs and can replace some stretch-and-fold sessions.",
            tips: [
                "Wet your work surface to prevent sticking",
                "Gently stretch dough from the center outward",
                "Aim for a thin, even sheet you can see through",
                "Fold into thirds like a letter, then repeat",
                "Great for incorporating add-ins like seeds or dried fruit"
            ],
            difficulty: "Advanced"
        ),
        BakingTechnique(
            title: "Bench Rest",
            description: "Allowing shaped dough to relax before final shaping",
            detailedExplanation: "Bench rest (or intermediate proof) is a short rest period after pre-shaping and before final shaping. During this 20-30 minute rest, gluten relaxes, making the dough more extensible and easier to shape into its final form. This prevents the dough from springing back and allows for better final shaping and a more uniform crumb structure.",
            tips: [
                "Rest pre-shaped dough for 20-30 minutes",
                "Cover with a damp towel to prevent drying",
                "Don't skip this step when making artisan loaves",
                "Dough should relax but not spread too much",
                "Adjust time based on dough temperature and fermentation"
            ],
            difficulty: "Beginner"
        ),
        BakingTechnique(
            title: "Creating Steam",
            description: "Adding moisture to the oven for better crust development",
            detailedExplanation: "Steam in the oven during the first 10-15 minutes of baking keeps the crust soft and pliable, allowing maximum oven spring before the crust sets. It also contributes to a shiny, crispy crust. Steam can be created using a Dutch oven, a pan of water in the oven, ice cubes, or by spraying water. Once the crust sets, steam is released to allow browning.",
            tips: [
                "Preheat Dutch oven if using that method",
                "Add ice cubes to a preheated pan for steam",
                "Spray oven walls with water (not on light bulb!)",
                "Steam is most important in first 10-15 minutes",
                "Too much steam later prevents browning"
            ],
            difficulty: "Intermediate"
        ),
        BakingTechnique(
            title: "Bulk Fermentation",
            description: "The first rise where dough develops flavor and structure",
            detailedExplanation: "Bulk fermentation is the first rise after mixing all ingredients. During this phase (typically 2-4 hours for yeast breads, 4-8 for sourdough), yeast ferments sugars, producing CO2 and alcohol. The dough should increase in volume by 50-100%. This stage is crucial for flavor development, gluten strengthening, and creating the conditions for a good final rise.",
            tips: [
                "Keep dough at consistent temperature (75-78°F ideal)",
                "Perform stretch-and-folds during this time",
                "Look for volume increase of 50-100%",
                "Dough should feel airy and jiggly when ready",
                "Don't just watch the clock - observe the dough"
            ],
            difficulty: "Beginner"
        )
    ]

    static func searchTechniques(query: String) -> [BakingTechnique] {
        if query.isEmpty {
            return techniques
        }

        let lowercaseQuery = query.lowercased()
        return techniques.filter { technique in
            technique.title.lowercased().contains(lowercaseQuery) ||
            technique.description.lowercased().contains(lowercaseQuery) ||
            technique.detailedExplanation.lowercased().contains(lowercaseQuery)
        }
    }
}
