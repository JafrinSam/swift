import SwiftUI
import SwiftData

struct SnippetLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Snippet.createdAt, order: .reverse) private var snippets: [Snippet]
    
    @State private var showingAddSheet = false
    @State private var snippetToEdit: Snippet? // Track which snippet is being edited
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                if snippets.isEmpty {
                    ContentUnavailableView(
                        "Library Offline",
                        systemImage: "terminal.fill",
                        description: Text("No code modules detected in the local registry.")
                    )
                } else {
                    List {
                        ForEach(snippets) { snippet in
                            // Use our new Expandable Row component
                            ExpandableSnippetRow(snippet: snippet) {
                                snippetToEdit = snippet // Trigger Edit Sheet
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteSnippet)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Registry")
            .toolbar {
                Button { showingAddSheet = true } label: {
                    Image(systemName: "plus.square.dashed")
                        .foregroundStyle(Color.toxicLime)
                }
            }
            // Sheet for Adding
            .sheet(isPresented: $showingAddSheet) {
                AddSnippetView()
            }
            // Sheet for Editing
            .sheet(item: $snippetToEdit) { snippet in
                EditSnippetView(snippet: snippet)
            }
        }
    }
    
    private func deleteSnippet(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(snippets[index])
        }
    }
}

// MARK: - Add Snippet View
struct AddSnippetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var code = ""
    @State private var language = "Swift"
    
    let languages = ["Swift", "Python", "TS", "C++", "Bash"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                Form {
                    Section("Module Header") {
                        TextField("Module Title (e.g. Auth Guard)", text: $title)
                    }
                    
                    Section("Environment") {
                        Picker("Language", selection: $language) {
                            ForEach(languages, id: \.self) { lang in
                                Text(lang).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section("Logic Implementation") {
                        TextEditor(text: $code)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Module")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abort") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Commit") {
                        if title.lowercased() == "sudo unlock theme" {
                            ThemeManager.shared.applyTheme("theme_hacker", color: Color(hex: "00FF41"))
                        } else {
                            let newSnippet = Snippet(title: title, code: code, language: language)
                            modelContext.insert(newSnippet)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty || code.isEmpty)
                    .foregroundStyle(Color.toxicLime)
                }
            }
        }
    }
}

// MARK: - New: Expandable Row Component
struct ExpandableSnippetRow: View {
    @Bindable var snippet: Snippet
    @State private var isExpanded = false
    var onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // HEADER (The part you click to drop down)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snippet.title)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(Color.smokeWhite)
                    Text(snippet.language)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                }
                
                Spacer()
                
                // Edit Button
                Button(action: onEdit) {
                    Image(systemName: "pencil.and.outline")
                        .font(.caption)
                        .foregroundStyle(Color.ashGrey)
                }
                .buttonStyle(.plain)
                
                // Expansion Indicator
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.ashGrey)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            // DROP DOWN: The Code Block
            if isExpanded {
                VStack(alignment: .leading) {
                    Text(snippet.code)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.electricCyan)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.carbonGrey)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    
                    HStack {
                        Spacer()
                        Button {
                            UIPasteboard.general.string = snippet.code
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Copy Code", systemImage: "doc.on.doc")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.toxicLime)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.carbonGrey.opacity(0.3))
        .cornerRadius(16)
        .padding(.vertical, 4)
    }
}

// MARK: - New: Edit Snippet View
struct EditSnippetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var snippet: Snippet
    
    let languages = ["Swift", "Python", "TS", "C++", "Bash"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                Form {
                    Section("Update Module") {
                        TextField("Module Title", text: $snippet.title)
                        Picker("Environment", selection: $snippet.language) {
                            ForEach(languages, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section("Logic Update") {
                        TextEditor(text: $snippet.code)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 300)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Refactor Module")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply Changes") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundStyle(Color.toxicLime)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}