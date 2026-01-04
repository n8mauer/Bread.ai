import SwiftUI

struct GlossaryView: View {
    @State private var searchText = ""
    @State private var selectedTerm: GlossaryTerm?
    @State private var showingTermDetail = false

    private var filteredTerms: [GlossaryTerm] {
        GlossaryData.searchTerms(query: searchText)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.breadBeige.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    Text("Baking Glossary")
                        .font(.largeTitle.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top, 15)

                    Image("bread.ai logo no background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.vertical, 10)

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search terms...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    // Terms list
                    if filteredTerms.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))

                            Text("No terms found")
                                .font(.headline)
                                .foregroundColor(.gray)

                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))

                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                if searchText.isEmpty {
                                    // Grouped by letter when not searching
                                    ForEach(GlossaryData.groupedByLetter, id: \.0) { letter, terms in
                                        Section(header: SectionHeaderView(letter: letter)) {
                                            ForEach(terms) { term in
                                                GlossaryTermRow(term: term)
                                                    .onTapGesture {
                                                        selectedTerm = term
                                                        showingTermDetail = true
                                                    }
                                            }
                                        }
                                    }
                                } else {
                                    // Flat list when searching
                                    ForEach(filteredTerms) { term in
                                        GlossaryTermRow(term: term)
                                            .onTapGesture {
                                                selectedTerm = term
                                                showingTermDetail = true
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingTermDetail) {
            if let term = selectedTerm {
                GlossaryTermDetailView(term: term)
            }
        }
    }
}

struct SectionHeaderView: View {
    let letter: String

    var body: some View {
        HStack {
            Text(letter)
                .font(.title.bold())
                .foregroundColor(.breadBrown)
                .padding(.vertical, 8)

            Spacer()
        }
        .background(Color.breadBeige)
    }
}

struct GlossaryTermRow: View {
    let term: GlossaryTerm

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(term.term)
                .font(.headline)
                .foregroundColor(.breadBrown)

            Text(term.definition)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .padding(.vertical, 4)
    }
}

struct GlossaryTermDetailView: View {
    let term: GlossaryTerm
    @Environment(\.dismiss) var dismiss
    @State private var showingRelatedTerm: GlossaryTerm?

    var body: some View {
        NavigationView {
            ZStack {
                Color.breadBeige.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Term title
                        Text(term.term)
                            .font(.largeTitle.bold())
                            .foregroundColor(.breadBrown)
                            .padding(.top)

                        Divider()

                        // Definition
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Definition")
                                .font(.title2.bold())
                                .foregroundColor(.breadBrown)

                            Text(term.definition)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }

                        // Related terms
                        if !term.relatedTerms.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Related Terms")
                                    .font(.title2.bold())
                                    .foregroundColor(.breadBrown)

                                FlowLayout(spacing: 8) {
                                    ForEach(term.relatedTerms, id: \.self) { relatedTermName in
                                        RelatedTermButton(
                                            termName: relatedTermName,
                                            action: {
                                                if let foundTerm = GlossaryData.terms.first(where: { $0.term == relatedTermName }) {
                                                    showingRelatedTerm = foundTerm
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(term.term)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.breadBrown)
                }
            }
        }
        .sheet(item: $showingRelatedTerm) { relatedTerm in
            GlossaryTermDetailView(term: relatedTerm)
        }
    }
}

struct RelatedTermButton: View {
    let termName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(termName)
                .font(.subheadline)
                .foregroundColor(.breadBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.breadBrown.opacity(0.15))
                .cornerRadius(8)
        }
    }
}

// Simple flow layout for wrapping related terms
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    GlossaryView()
}
