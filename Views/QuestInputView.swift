import SwiftUI
import SwiftData

struct QuestInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var details = ""

    
    // Sub-Quest Input
    @State private var temporarySubQuests: [TempSubQuest] = []
    @State private var newSubTitle = ""
    @State private var newSubDifficulty: QuestDifficulty = .routine
    
    // MARK: - Blueprints System
    struct TempSubQuest: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let difficulty: QuestDifficulty
    }

    struct QuestBlueprint: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let description: String
        let icon: String
        let color: Color
        let defaultSubQuests: [TempSubQuest]
    }
    
    let blueprints: [QuestBlueprint] = [
        QuestBlueprint(
            name: "New API Endpoint",
            description: "Build a backend route with validation",
            icon: "server.rack",
            color: .electricCyan,
            defaultSubQuests: [
                TempSubQuest(title: "Design Input/Output Schema", difficulty: .routine),
                TempSubQuest(title: "Write Controller Logic", difficulty: .complex),
                TempSubQuest(title: "Implement Database Query", difficulty: .complex),
                TempSubQuest(title: "Write Unit Tests", difficulty: .routine)
            ]
        ),
        QuestBlueprint(
            name: "UI Component",
            description: "Design and implement a new screen",
            icon: "paintbrush.pointed.fill",
            color: .ballisticOrange,
            defaultSubQuests: [
                TempSubQuest(title: "Create wireframe/layout", difficulty: .routine),
                TempSubQuest(title: "Build component structure", difficulty: .complex),
                TempSubQuest(title: "Add animations/transitions", difficulty: .routine),
                TempSubQuest(title: "Responsive/dark mode testing", difficulty: .routine)
            ]
        ),
        QuestBlueprint(
            name: "Bug Fix",
            description: "Diagnose and resolve a defect",
            icon: "ladybug.fill",
            color: .alertRed,
            defaultSubQuests: [
                TempSubQuest(title: "Reproduce the bug", difficulty: .routine),
                TempSubQuest(title: "Root cause analysis", difficulty: .complex),
                TempSubQuest(title: "Implement fix", difficulty: .complex),
                TempSubQuest(title: "Regression testing", difficulty: .routine)
            ]
        ),
        QuestBlueprint(
            name: "Security Audit",
            description: "Vulnerability scanning and patching",
            icon: "shield.lefthalf.filled.badge.checkmark",
            color: .red,
            defaultSubQuests: [
                TempSubQuest(title: "Run dependency scan", difficulty: .routine),
                TempSubQuest(title: "Analyze exploit vectors", difficulty: .complex),
                TempSubQuest(title: "Patch vulnerabilities", difficulty: .legacy)
            ]
        ),
        QuestBlueprint(
            name: "Database Migration",
            description: "Schema updates and data migration",
            icon: "cylinder.split.1x2.fill",
            color: .purple,
            defaultSubQuests: [
                TempSubQuest(title: "Design new schema", difficulty: .complex),
                TempSubQuest(title: "Write migration script", difficulty: .complex),
                TempSubQuest(title: "Backup existing data", difficulty: .routine),
                TempSubQuest(title: "Run migration + verify", difficulty: .legacy)
            ]
        ),
        QuestBlueprint(
            name: "Testing Suite",
            description: "Add comprehensive test coverage",
            icon: "checkmark.shield.fill",
            color: .toxicLime,
            defaultSubQuests: [
                TempSubQuest(title: "Write unit tests", difficulty: .routine),
                TempSubQuest(title: "Write integration tests", difficulty: .complex),
                TempSubQuest(title: "Set up CI pipeline", difficulty: .complex)
            ]
        ),
        QuestBlueprint(
            name: "Documentation",
            description: "Write docs and README updates",
            icon: "doc.text.fill",
            color: .cyan,
            defaultSubQuests: [
                TempSubQuest(title: "Write API documentation", difficulty: .routine),
                TempSubQuest(title: "Create usage examples", difficulty: .routine),
                TempSubQuest(title: "Update README/changelog", difficulty: .routine)
            ]
        ),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Blueprints Grid
                        blueprintSelector
                        
                        // MARK: - Module Details
                        inputCard(title: "MODULE SPECIFICATION") {
                            VStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Name")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.ashGrey)
                                    TextField("e.g. Auth System", text: $title)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(Color.voidBlack.opacity(0.5))
                                        .cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Documentation")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.ashGrey)
                                    TextField("Technical details...", text: $details, axis: .vertical)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .lineLimit(2...5)
                                        .padding(12)
                                        .background(Color.voidBlack.opacity(0.5))
                                        .cornerRadius(10)
                                }
                                
                                // Boss Quest Info
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(Color.ashGrey.opacity(0.5))
                                    Text("Modules auto-escalate to ⚠ TECH DEBT after 3 days")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(Color.ashGrey)
                                }
                            }
                        }
                        
                        // MARK: - Sub-Modules
                        inputCard(title: "SUB-MODULE BOUNTIES (\(temporarySubQuests.count))") {
                            VStack(spacing: 12) {
                                // Existing sub-quests with drag reorder
                                ForEach(temporarySubQuests) { item in
                                    HStack(spacing: 10) {
                                        Image(systemName: "line.horizontal.3")
                                            .font(.caption2)
                                            .foregroundStyle(Color.ashGrey.opacity(0.4))
                                        
                                        Text(item.title)
                                            .font(.system(.subheadline, design: .monospaced))
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        DifficultyBadge(difficulty: item.difficulty)
                                        
                                        // Remove button
                                        Button {
                                            withAnimation {
                                                temporarySubQuests.removeAll { $0.id == item.id }
                                                Haptics.shared.play(.light)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(Color.alertRed.opacity(0.5))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                                
                                Divider().overlay(Color.white.opacity(0.05))
                                
                                // Add new sub-quest
                                VStack(spacing: 10) {
                                    TextField("New sub-module...", text: $newSubTitle)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(Color.voidBlack.opacity(0.5))
                                        .cornerRadius(8)
                                        .onSubmit { addSubQuest() }
                                    
                                    HStack {
                                        Picker("Difficulty", selection: $newSubDifficulty) {
                                            ForEach(QuestDifficulty.allCases, id: \.self) { diff in
                                                Text(diff.rawValue).tag(diff)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        
                                        Button { addSubQuest() } label: {
                                            Text("ADD")
                                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(newSubTitle.isEmpty ? Color.ashGrey : Color.electricCyan)
                                                .cornerRadius(8)
                                        }
                                        .disabled(newSubTitle.isEmpty)
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Preview
                        inputCard(title: "DEPLOYMENT MANIFEST") {
                            VStack(spacing: 10) {
                                manifestRow(label: "Module", value: title.isEmpty ? "—" : title)
                                Divider().overlay(Color.white.opacity(0.03))
                                manifestRow(label: "Sub-Modules", value: "\(temporarySubQuests.count)")
                                Divider().overlay(Color.white.opacity(0.03))
                                manifestRow(label: "Completion Bonus", value: "+50 XP", color: .toxicLime)
                                Divider().overlay(Color.white.opacity(0.03))
                                HStack {
                                    Text("Total Potential")
                                        .font(.system(.subheadline, design: .monospaced)).bold()
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(calculateTotalXP()) XP")
                                        .font(.system(.title3, design: .monospaced)).bold()
                                        .foregroundStyle(Color.ballisticOrange)
                                }
                            }
                        }
                        
                        // MARK: - Deploy Button
                        Button { saveQuest() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                Text("DEPLOY MODULE")
                                    .font(.system(.headline, design: .monospaced)).bold()
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity).padding(16)
                            .background(title.isEmpty ? Color.ashGrey : Color.toxicLime)
                            .cornerRadius(16)
                        }
                        .disabled(title.isEmpty)
                        .padding(.bottom, 30)
                    }
                    .padding()
                }
            }
            .navigationTitle("Initialize Module")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abort") { dismiss() }
                        .foregroundStyle(Color.ashGrey)
                }
            }
        }
    }
    
    // MARK: - Blueprint Selector
    @ViewBuilder
    private var blueprintSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORGE BLUEPRINTS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(blueprints) { bp in
                        Button { loadBlueprint(bp) } label: {
                            VStack(spacing: 8) {
                                Image(systemName: bp.icon)
                                    .font(.title3)
                                    .foregroundStyle(bp.color)
                                Text(bp.name)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 90, height: 80)
                            .background(bp.color.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(bp.color.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func inputCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(Color.carbonGrey.opacity(0.5))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05)))
        }
    }
    
    private func manifestRow(label: String, value: String, color: Color = .ashGrey) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Color.smokeWhite.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(color)
        }
    }
    
    private func addSubQuest() {
        guard !newSubTitle.isEmpty else { return }
        withAnimation {
            temporarySubQuests.append(TempSubQuest(title: newSubTitle, difficulty: newSubDifficulty))
            newSubTitle = ""
            Haptics.shared.play(.light)
        }
    }
    
    private func loadBlueprint(_ bp: QuestBlueprint) {
        withAnimation {
            title = bp.name
            details = bp.description
            temporarySubQuests = bp.defaultSubQuests
            Haptics.shared.play(.medium)
        }
    }
    
    private func calculateTotalXP() -> Int {
        let subXP = temporarySubQuests.reduce(0) { $0 + $1.difficulty.xpReward }
        return subXP + 50
    }
    
    private func saveQuest() {
        let newQuest = Quest(title: title, details: details)
        modelContext.insert(newQuest)
        
        for temp in temporarySubQuests {
            let sub = SubQuest(title: temp.title, difficulty: temp.difficulty)
            sub.parentQuest = newQuest
            newQuest.subQuests.append(sub)
        }
        
        try? modelContext.save()
        Haptics.shared.notify(.success)
        dismiss()
    }
}

// MARK: - Reusable Difficulty Badge
struct DifficultyBadge: View {
    var difficulty: QuestDifficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(.black)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(difficultyColor(difficulty))
            .clipShape(Capsule())
    }
    
    func difficultyColor(_ d: QuestDifficulty) -> Color {
        switch d {
        case .routine: return .toxicLime
        case .complex: return .ballisticOrange
        case .legacy:  return .alertRed
        }
    }
}