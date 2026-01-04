import Foundation

struct GlossaryTerm: Identifiable, Hashable {
    let id = UUID()
    let term: String
    let definition: String
    let relatedTerms: [String]

    var firstLetter: String {
        String(term.prefix(1).uppercased())
    }
}

class GlossaryData {
    static let terms: [GlossaryTerm] = [
        GlossaryTerm(
            term: "Autolyse",
            definition: "A resting period where flour and water are mixed and allowed to sit before adding salt and yeast. This technique improves gluten development, dough extensibility, and final bread texture.",
            relatedTerms: ["Hydration", "Gluten", "Kneading"]
        ),
        GlossaryTerm(
            term: "Banneton",
            definition: "A woven basket (also called a proofing basket or brotform) used to support dough during its final rise. It gives the dough its shape and creates distinctive circular patterns on the crust.",
            relatedTerms: ["Proofing", "Shaping", "Boule"]
        ),
        GlossaryTerm(
            term: "Bench Rest",
            definition: "A short rest period (15-30 minutes) after pre-shaping and before final shaping, allowing the gluten to relax and making the dough easier to shape.",
            relatedTerms: ["Proofing", "Shaping", "Gluten"]
        ),
        GlossaryTerm(
            term: "Boule",
            definition: "A round-shaped loaf of bread, French for 'ball'. One of the most common shapes for artisan breads, especially sourdough.",
            relatedTerms: ["Batard", "Shaping", "Banneton"]
        ),
        GlossaryTerm(
            term: "Bulk Fermentation",
            definition: "The first rise of bread dough after mixing all ingredients. During this phase, yeast ferments sugars, developing flavor and creating gas that makes the dough rise. Also called first fermentation.",
            relatedTerms: ["Fermentation", "Proofing", "Starter"]
        ),
        GlossaryTerm(
            term: "Crumb",
            definition: "The internal structure and texture of bread, including the size and distribution of air holes. An 'open crumb' has large, irregular holes, while a 'tight crumb' has small, uniform holes.",
            relatedTerms: ["Gluten", "Hydration", "Kneading"]
        ),
        GlossaryTerm(
            term: "Dutch Oven",
            definition: "A heavy, lidded pot (usually cast iron) used for baking bread. It traps steam during baking, creating a crispy crust and excellent oven spring, mimicking professional steam-injected ovens.",
            relatedTerms: ["Oven Spring", "Steam", "Crust"]
        ),
        GlossaryTerm(
            term: "Fermentation",
            definition: "The process by which yeast consumes sugars and produces carbon dioxide and alcohol. This creates the rise in bread and develops complex flavors. Can be done with commercial yeast or wild yeast (sourdough).",
            relatedTerms: ["Yeast", "Starter", "Bulk Fermentation"]
        ),
        GlossaryTerm(
            term: "Gluten",
            definition: "A network of proteins (glutenin and gliadin) that forms when flour is mixed with water and kneaded. Gluten gives bread its structure, elasticity, and ability to trap gas bubbles.",
            relatedTerms: ["Kneading", "Windowpane Test", "Flour"]
        ),
        GlossaryTerm(
            term: "Hydration",
            definition: "The ratio of water to flour in a dough, expressed as a percentage. For example, 500g water and 1000g flour is 50% hydration. Higher hydration creates more open crumb but is harder to handle.",
            relatedTerms: ["Dough", "Crumb", "Flour"]
        ),
        GlossaryTerm(
            term: "Lame",
            definition: "A specialized blade tool used for scoring bread before baking. Consists of a razor blade attached to a handle, allowing for precise, clean cuts at the optimal angle.",
            relatedTerms: ["Scoring", "Crust", "Oven Spring"]
        ),
        GlossaryTerm(
            term: "Levain",
            definition: "A portion of sourdough starter that has been fed and is at its peak activity, ready to be mixed into bread dough. Distinguished from the 'mother' starter that is maintained long-term.",
            relatedTerms: ["Starter", "Sourdough", "Fermentation"]
        ),
        GlossaryTerm(
            term: "Oven Spring",
            definition: "The rapid rise of bread during the first 10-15 minutes of baking, caused by yeast producing a final burst of gas and moisture turning to steam. Proper steam and scoring enhance oven spring.",
            relatedTerms: ["Steam", "Scoring", "Dutch Oven"]
        ),
        GlossaryTerm(
            term: "Poolish",
            definition: "A wet pre-ferment made with equal parts flour and water (100% hydration) and a small amount of yeast. It ferments for 12-16 hours and adds flavor and improves texture in the final bread.",
            relatedTerms: ["Pre-ferment", "Biga", "Fermentation"]
        ),
        GlossaryTerm(
            term: "Pre-ferment",
            definition: "A portion of dough that is fermented before being mixed into the final dough. Common types include poolish, biga, and levain. Enhances flavor, improves texture, and can extend shelf life.",
            relatedTerms: ["Poolish", "Biga", "Levain"]
        ),
        GlossaryTerm(
            term: "Proofing",
            definition: "The final rise of shaped bread dough before baking. Can be done at room temperature (1-3 hours) or cold (8-72 hours in refrigerator). Also called final fermentation or proving.",
            relatedTerms: ["Bulk Fermentation", "Fermentation", "Banneton"]
        ),
        GlossaryTerm(
            term: "Scoring",
            definition: "Cutting patterns into the surface of bread dough just before baking. Controls where the bread expands, prevents random bursting, and creates decorative patterns.",
            relatedTerms: ["Lame", "Oven Spring", "Crust"]
        ),
        GlossaryTerm(
            term: "Sourdough",
            definition: "Bread leavened with wild yeast and bacteria rather than commercial yeast. The starter gives sourdough its characteristic tangy flavor and chewy texture. Requires maintaining a starter culture.",
            relatedTerms: ["Starter", "Levain", "Fermentation"]
        ),
        GlossaryTerm(
            term: "Starter",
            definition: "A culture of wild yeast and beneficial bacteria used to leaven sourdough bread. Made from flour and water, it must be fed regularly to remain active. Also called sourdough starter or mother.",
            relatedTerms: ["Sourdough", "Levain", "Fermentation"]
        ),
        GlossaryTerm(
            term: "Steam",
            definition: "Moisture added to the oven during the first 10-15 minutes of baking. Keeps the crust soft initially, allowing maximum oven spring, and contributes to a crispy, shiny crust.",
            relatedTerms: ["Dutch Oven", "Oven Spring", "Crust"]
        ),
        GlossaryTerm(
            term: "Stretch and Fold",
            definition: "A gentle technique for developing gluten without traditional kneading. The dough is stretched and folded over itself multiple times during bulk fermentation, building strength while preserving air bubbles.",
            relatedTerms: ["Gluten", "Bulk Fermentation", "Kneading"]
        ),
        GlossaryTerm(
            term: "Windowpane Test",
            definition: "A test to check if gluten is adequately developed. Stretch a small piece of dough thin - if it forms a translucent membrane without tearing, gluten development is complete.",
            relatedTerms: ["Gluten", "Kneading", "Dough"]
        ),
        GlossaryTerm(
            term: "Batard",
            definition: "An oval or torpedo-shaped loaf, shorter and fatter than a baguette. Popular for country-style breads and sourdough.",
            relatedTerms: ["Boule", "Shaping", "Baguette"]
        ),
        GlossaryTerm(
            term: "Biga",
            definition: "A stiff Italian pre-ferment made with flour, water (50-60% hydration), and a tiny amount of yeast. Ferments for 12-16 hours and adds depth of flavor to breads.",
            relatedTerms: ["Pre-ferment", "Poolish", "Fermentation"]
        ),
        GlossaryTerm(
            term: "Crust",
            definition: "The outer layer of bread that forms during baking. A good crust should be crispy and golden-brown, with flavor developed through Maillard reactions and caramelization.",
            relatedTerms: ["Steam", "Oven Spring", "Crumb"]
        ),
        GlossaryTerm(
            term: "Retard",
            definition: "Slowing down fermentation by refrigerating dough. Cold retarding (usually overnight) develops more complex flavors and makes dough easier to handle and score.",
            relatedTerms: ["Proofing", "Fermentation", "Flavor"]
        ),
        GlossaryTerm(
            term: "Enriched Dough",
            definition: "Dough that contains fats, sugar, eggs, or dairy in addition to the basic flour, water, salt, and yeast. Examples include brioche, challah, and sandwich bread.",
            relatedTerms: ["Lean Dough", "Brioche", "Challah"]
        ),
        GlossaryTerm(
            term: "Lean Dough",
            definition: "Dough made with only flour, water, salt, and yeast, without added fats or sugar. Examples include baguettes, ciabatta, and most artisan breads.",
            relatedTerms: ["Enriched Dough", "Baguette", "Ciabatta"]
        )
    ]

    static var sortedTerms: [GlossaryTerm] {
        terms.sorted { $0.term < $1.term }
    }

    static var groupedByLetter: [(String, [GlossaryTerm])] {
        let grouped = Dictionary(grouping: sortedTerms) { $0.firstLetter }
        return grouped.sorted { $0.key < $1.key }
    }

    static func searchTerms(query: String) -> [GlossaryTerm] {
        if query.isEmpty {
            return sortedTerms
        }

        let lowercaseQuery = query.lowercased()
        return sortedTerms.filter { term in
            term.term.lowercased().contains(lowercaseQuery) ||
            term.definition.lowercased().contains(lowercaseQuery)
        }
    }
}
