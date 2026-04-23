import SwiftUI
import SwiftData

/// User-facing screen for managing category definitions. Built-in
/// categories are listed read-only; user-defined ones are editable.
struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @State private var showingNew = false

    var body: some View {
        List {
            Section {
                ForEach(BuiltInCategory.allCases, id: \.self) { cat in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cat.label).font(.body)
                        Text(cat.defaultDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Built-in")
            } footer: {
                Text("Built-in categories can't be edited or removed.")
            }

            Section {
                if customCategories.isEmpty {
                    Text("None yet. Tap + to create one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(customCategories) { cat in
                        NavigationLink {
                            CategoryEditView(category: cat)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cat.name.capitalized).font(.body)
                                Text(cat.prompt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: delete)
                }
            } header: {
                Text("Your categories")
            } footer: {
                Text("The description teaches Claude when to pick this category. Write a clear sentence or two: what qualifies, what does not.")
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNew = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                CategoryEditView(category: nil)
            }
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
        Form {
            Section {
                TextField("Name", text: $name)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } footer: {
                Text("Short, lowercase, one or two words.")
            }

            Section {
                TextField("Description", text: $prompt, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            } header: {
                Text("Description")
            } footer: {
                Text("Tell Claude when to pick this category. Example: 'A specific coffee shop I want to try — espresso bars, roasters, pour-over spots. Not general food content.'")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || prompt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .topBarLeading) {
                if category == nil {
                    Button("Cancel") { dismiss() }
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
