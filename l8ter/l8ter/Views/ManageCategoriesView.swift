import SwiftUI
import SwiftData

/// User-facing screen for managing category definitions. Built-in
/// categories are listed read-only; user-defined ones are editable.
struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @State private var showingNew = false

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            List {
                Section {
                    ForEach(BuiltInCategory.allCases, id: \.self) { cat in
                        HStack(alignment: .top, spacing: DSSpace.sm) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(cat.label)
                                        .font(.dsBody)
                                        .foregroundStyle(Color.textPrimary)
                                    if cat == .restaurant || cat == .movie || cat == .show {
                                        Text(cat.rawValue.uppercased())
                                            .font(.dsMetaTiny)
                                            .tracking(DSTracking.metaTiny)
                                            .foregroundStyle(Color.accent)
                                    }
                                }
                                Text(cat.defaultDescription)
                                    .font(.dsMetaSmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.bgBase)
                    }
                } header: {
                    SectionLabel(text: "Built-in (\(BuiltInCategory.allCases.count))")
                } footer: {
                    Text("Built-in categories can't be edited or removed.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                Section {
                    if customCategories.isEmpty {
                        Text("None yet. Tap + to create one.")
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.textTertiary)
                            .listRowBackground(Color.bgBase)
                    } else {
                        ForEach(customCategories) { cat in
                            NavigationLink {
                                CategoryEditView(category: cat)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text(cat.name.capitalized)
                                            .font(.dsBody)
                                            .foregroundStyle(Color.textPrimary)
                                        Chip(label: "custom", tone: .accent)
                                    }
                                    Text(cat.prompt)
                                        .font(.dsMetaSmall)
                                        .foregroundStyle(Color.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.bgBase)
                        }
                        .onDelete(perform: delete)
                    }
                } header: {
                    SectionLabel(text: "Custom (\(customCategories.count))")
                } footer: {
                    Text("The description teaches Claude when to pick this category.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle("Categories")
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNew = true
                } label: {
                    Text("+ ADD")
                        .font(.dsMetaCaps)
                        .tracking(DSTracking.metaCaps)
                        .foregroundStyle(Color.accent)
                }
            }
        }
        .sheet(isPresented: $showingNew) {
            NavigationStack { CategoryEditView(category: nil) }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(customCategories[index])
        }
        try? context.save()
    }
}

/// Create/edit screen for a single user-defined category.
struct CategoryEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = creating. Non-nil = editing.
    var category: CustomCategory?

    @State private var name: String = ""
    @State private var prompt: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            Form {
                Section {
                    TextField("Name", text: $name)
                        .font(.dsBody)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } footer: {
                    Text("Short, lowercase, one or two words.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                Section {
                    TextField("Description", text: $prompt, axis: .vertical)
                        .font(.dsBody)
                        .lineLimit(4, reservesSpace: true)
                } header: {
                    SectionLabel(text: "Description")
                } footer: {
                    Text("Tell Claude when to pick this category. Example: 'A specific coffee shop I want to try — espresso bars, roasters, pour-over spots. Not general food content.'")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(Color.accent)
            }
            ToolbarItem(placement: .topBarLeading) {
                if category == nil {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        if let category {
            name = category.name
            prompt = category.prompt
        }
    }

    private func save() {
        let normalized = CategoryRegistry.normalize(name)
        guard !normalized.isEmpty else { return }

        // Block collisions with built-ins and other custom categories.
        if BuiltInCategory(rawValue: normalized) != nil {
            errorMessage = "'\(normalized)' is a built-in category name."
            return
        }
        let descriptor = FetchDescriptor<CustomCategory>(
            predicate: #Predicate { $0.name == normalized }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        if let first = existing.first, first !== category {
            errorMessage = "A category named '\(normalized)' already exists."
            return
        }

        if let category {
            category.name = normalized
            category.prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let new = CustomCategory(
                name: normalized,
                prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack { ManageCategoriesView() }
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
