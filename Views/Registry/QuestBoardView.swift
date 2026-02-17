import SwiftUI
import SwiftData
import AVFoundation

struct QuestBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var heroes: [Hero]
    var hero: Hero { heroes.first ?? Hero() }
    
    @Query(filter: #Predicate<Quest> { !$0.isCompleted }, sort: \.createdAt, order: .reverse)
    private var activeQuests: [Quest]
    
    @Query(filter: #Predicate<Quest> { $0.isCompleted }, sort: \.createdAt, order: .reverse)
    private var completedQuests: [Quest]
    
    @State private var isShowingInput = false
    @State private var searchText = ""
    @State private var showCompleted = false
    @State private var questToEdit: Quest? = nil
    
    // Filtered + sorted: bosses first, then by date
    private var filteredActiveQuests: [Quest] {
        let filtered = searchText.isEmpty
            ? activeQuests
            : activeQuests.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted { a, b in
            if a.isBoss != b.isBoss { return a.isBoss }
            return a.createdAt > b.createdAt
        }
    }
    
    private var filteredCompletedQuests: [Quest] {
        searchText.isEmpty
            ? Array(completedQuests)
            : completedQuests.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Quest Count Summary
                        HStack(spacing: 12) {
                            countBadge(count: activeQuests.count, label: "ACTIVE", color: .electricCyan)
                            countBadge(count: completedQuests.count, label: "DEPLOYED", color: .toxicLime)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Search Bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.ashGrey)
                            TextField("Search modules...", text: $searchText)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(Color.carbonGrey.opacity(0.5))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Active Quests Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACTIVE FORGE MODULES")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.electricCyan)
                                .padding(.horizontal)
                            
                            if filteredActiveQuests.isEmpty {
                                emptyActiveState
                            } else {
                                ForEach(filteredActiveQuests) { quest in
                                    QuestRow(
                                        quest: quest,
                                        hero: hero,
                                        isCompleted: false,
                                        onEdit: { questToEdit = quest },
                                        onDelete: { deleteQuest(quest) }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Completed Quests Section (Collapsible)
                        if !completedQuests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        showCompleted.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Text("DEPLOYED MODULES")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color.toxicLime)
                                        
                                        Text("(\(completedQuests.count))")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(Color.ashGrey)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption2.bold())
                                            .foregroundStyle(Color.ashGrey)
                                            .rotationEffect(.degrees(showCompleted ? 90 : 0))
                                    }
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                                
                                if showCompleted {
                                    ForEach(filteredCompletedQuests.prefix(10)) { quest in
                                        QuestRow(
                                            quest: quest,
                                            hero: hero,
                                            isCompleted: true,
                                            onEdit: nil,
                                            onDelete: { deleteQuest(quest) }
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Module Registry")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isShowingInput = true } label: {
                        Image(systemName: "plus.viewfinder")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.toxicLime)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isShowingInput) {
                QuestInputView()
            }
            .sheet(item: $questToEdit) { quest in
                QuestEditView(quest: quest)
            }
        }
    }
    
    // MARK: - Components
    
    private func countBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.system(.headline, design: .monospaced)).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(label.lowercased()) modules")
    }
    
    private var emptyActiveState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.electricCyan.opacity(0.1), lineWidth: 1)
                    .frame(width: 70, height: 70)
                Image(systemName: "terminal")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.ashGrey.opacity(0.4))
            }
            
            VStack(spacing: 4) {
                Text("NO ACTIVE MODULES")
                    .font(.system(.subheadline, design: .monospaced)).bold()
                    .foregroundStyle(Color.ashGrey)
                Text("Initialize a new module to begin your operation.")
                    .font(.caption)
                    .foregroundStyle(Color.ashGrey.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.carbonGrey.opacity(0.2))
        .cornerRadius(20)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No active modules. Use the plus button to create a new mission.")
    }
    
    private func deleteQuest(_ quest: Quest) {
        withAnimation {
            modelContext.delete(quest)
            try? modelContext.save()
            Haptics.shared.notify(.warning)
        }
    }
}


// MARK: - Quest Row (Upgraded)
struct QuestRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var quest: Quest
    var hero: Hero
    var isCompleted: Bool
    var onEdit: (() -> Void)?
    var onDelete: () -> Void
    
    @State private var isExpanded: Bool = false
    @State private var newSubTitle: String = ""
    @State private var newSubDifficulty: QuestDifficulty = .routine
    @State private var showDeleteConfirm = false
    
    // Overtime detection
    @AppStorage("focusDuration") private var focusDuration: Int = 25
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1005
    @State private var showOvertimeAlert = false
    @State private var overtimeAlertShown = false
    @State private var showRechargeFromOvertime = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // --- HEADER ---
            HStack(spacing: 12) {
                // Complete button
                Button { toggleMainQuest() } label: {
                    Image(systemName: isCompleted ? "checkmark.seal.fill" : "circle.inset.filled")
                        .font(.title2)
                        .foregroundStyle(
                            isCompleted ? Color.toxicLime
                            : (quest.isBoss ? Color.alertRed : Color.electricCyan)
                        )
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.system(.headline, design: .monospaced))
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted ? Color.ashGrey : Color.white)
                    
                    if quest.isBoss && !isCompleted {
                        Text("⚠ TECHNICAL DEBT")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.alertRed)
                            .foregroundStyle(.black)
                            .cornerRadius(4)
                    }
                    
                    // Mini Progress Bar
                    if !isCompleted && !quest.subQuests.isEmpty {
                        HStack(spacing: 6) {
                            ProgressView(value: quest.progress)
                                .tint(quest.isBoss ? Color.alertRed : Color.electricCyan)
                                .frame(maxWidth: 100)
                            
                            Text("\(Int(quest.progress * 100))%")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.ashGrey)
                        }
                    }
                }
                
                Spacer()
                
                // XP Badge
                if !isCompleted {
                    Text("\(quest.totalXP) XP")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Color.carbonGrey)
                        .foregroundStyle(Color.ballisticOrange)
                        .cornerRadius(8)
                }
                
                // Expand chevron
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.ashGrey)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
                Haptics.shared.play(.light)
            }
            
            // --- EXPANDED SECTION ---
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    // Description
                    if !quest.details.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MODULE DOCUMENTATION")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.ashGrey)
                            Text(quest.details)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color.smokeWhite.opacity(0.8))
                        }
                    }
                    
                    // Timer Controls (only for active quests)
                    if !isCompleted {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("REACTOR INITIALIZATION")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.ashGrey)
                            
                            if quest.isActive && quest.isTimerActive {
                                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                                    let elapsed = questElapsedTime(at: context.date)
                                    let limitSeconds = TimeInterval(focusDuration * 60)
                                    let isOvertime = elapsed > limitSeconds
                                    let overtimeSeconds = max(0, elapsed - limitSeconds)
                                    
                                    VStack(spacing: 4) {
                                        // Overtime warning badge
                                        if isOvertime {
                                            HStack(spacing: 6) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 9))
                                                Text("OVERTIME +\(formatOvertime(overtimeSeconds))")
                                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                            }
                                            .foregroundStyle(Color.alertRed)
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Color.alertRed.opacity(0.12))
                                            .cornerRadius(6)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        }
                                        
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(isOvertime ? Color.alertRed.opacity(0.15) : Color.carbonGrey.opacity(0.5))
                                                LiveQuestTimer(quest: quest)
                                                    .foregroundStyle(isOvertime ? Color.alertRed : Color.toxicLime)
                                            }
                                            .frame(maxWidth: .infinity).frame(height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isOvertime ? Color.alertRed.opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                            
                                            Button(role: .destructive) {
                                                toggleGlobalTimer(quest)
                                            } label: {
                                                Label("STOP", systemImage: "stop.fill")
                                                    .font(.system(.caption, design: .monospaced)).bold()
                                                    .frame(maxWidth: .infinity).padding(12)
                                                    .background(Color.alertRed.opacity(0.2))
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                    .onChange(of: isOvertime) { _, newValue in
                                        if newValue && !overtimeAlertShown {
                                            triggerOvertimeAlert()
                                        }
                                    }
                                }
                            } else {
                                Menu {
                                    Button {
                                        quest.isActive = true
                                        toggleGlobalTimer(quest)
                                    } label: {
                                        Label("Start Timer", systemImage: "timer")
                                    }
                                    Button {
                                        quest.isActive = true
                                        quest.isFlowMode = true
                                        toggleGlobalTimer(quest)
                                    } label: {
                                        Label("Flow State (∞)", systemImage: "infinity")
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                        Text("ENGAGE REACTOR")
                                    }
                                    .font(.system(.caption, design: .monospaced)).bold()
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity).padding(12)
                                    .background(Color.toxicLime)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Sub-Quests
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SUB-MODULES")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.ashGrey)
                        
                        if quest.subQuests.isEmpty {
                            Text("No sub-modules yet")
                                .font(.caption)
                                .foregroundStyle(Color.ashGrey.opacity(0.5))
                        } else {
                            ForEach(quest.subQuests, id: \.id) { subQuest in
                                HStack(spacing: 10) {
                                    Button { toggleSubQuest(subQuest) } label: {
                                        Image(systemName: subQuest.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(subQuest.isCompleted ? Color.toxicLime : Color.ashGrey)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isCompleted)
                                    
                                    Text(subQuest.title)
                                        .font(.system(.subheadline, design: .monospaced))
                                        .strikethrough(subQuest.isCompleted)
                                        .foregroundStyle(subQuest.isCompleted ? Color.ashGrey : .white)
                                    
                                    Spacer()
                                    
                                    Text(subQuest.difficulty.rawValue)
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundStyle(difficultyColor(subQuest.difficulty))
                                    
                                    Text("+\(subQuest.difficulty.xpReward)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.ballisticOrange)
                                }
                            }
                        }
                        
                        // Inline Add Sub-Quest
                        if !isCompleted {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(Color.electricCyan)
                                        .font(.caption)
                                    
                                    TextField("New sub-module...", text: $newSubTitle)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .textFieldStyle(.plain)
                                }
                                
                                if !newSubTitle.isEmpty {
                                    HStack {
                                        Picker("", selection: $newSubDifficulty) {
                                            ForEach(QuestDifficulty.allCases, id: \.self) { diff in
                                                Text(diff.rawValue).tag(diff)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        
                                        Button {
                                            addSubQuestInline()
                                        } label: {
                                            Text("ADD")
                                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(Color.electricCyan)
                                                .cornerRadius(8)
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(10)
                            .background(Color.voidBlack.opacity(0.4))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Action Buttons: Edit + Delete
                    if !isCompleted {
                        HStack(spacing: 12) {
                            if let onEdit = onEdit {
                                Button {
                                    onEdit()
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .font(.system(.caption, design: .monospaced)).bold()
                                        .foregroundStyle(Color.electricCyan)
                                        .frame(maxWidth: .infinity).padding(10)
                                        .background(Color.electricCyan.opacity(0.1))
                                        .cornerRadius(10)
                                }
                            }
                            
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .font(.system(.caption, design: .monospaced)).bold()
                                    .foregroundStyle(Color.alertRed)
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(Color.alertRed.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            quest.isBoss && !isCompleted
            ? Color.alertRed.opacity(0.04)
            : Color.carbonGrey.opacity(0.3)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    quest.isBoss && !isCompleted
                    ? Color.alertRed.opacity(0.2)
                    : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
        .alert("Delete Module?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove \"\(quest.title)\" and all sub-modules.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(quest.title)\(quest.isBoss && !isCompleted ? ", technical debt" : ""), \(isCompleted ? "completed" : "\(Int(quest.progress * 100)) percent complete"), \(quest.totalXP) XP")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") details")
        // Overtime popup overlay
        .overlay {
            if showOvertimeAlert {
                questRowOvertimeAlert
            }
        }
        .fullScreenCover(isPresented: $showRechargeFromOvertime) {
            NavigationStack {
                RechargeHubView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { showRechargeFromOvertime = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.ashGrey)
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Logic
    
    private func addSubQuestInline() {
        guard !newSubTitle.isEmpty else { return }
        let sub = SubQuest(title: newSubTitle, difficulty: newSubDifficulty)
        sub.parentQuest = quest
        quest.subQuests.append(sub)
        newSubTitle = ""
        newSubDifficulty = .routine
        try? modelContext.save()
        Haptics.shared.play(.light)
    }
    
    private func toggleMainQuest() {
        withAnimation {
            quest.isCompleted.toggle()
            if quest.isCompleted {
                for sub in quest.subQuests { sub.isCompleted = true }
                hero.addXP(amount: quest.totalXP)
                quest.isActive = false
                Haptics.shared.notify(.success)
            } else {
                hero.currentXP -= quest.totalXP
                if hero.currentXP < 0 { hero.currentXP = 0 }
            }
            try? modelContext.save()
        }
    }
    
    private func toggleSubQuest(_ subQuest: SubQuest) {
        if let index = quest.subQuests.firstIndex(where: { $0.id == subQuest.id }) {
            withAnimation {
                quest.subQuests[index].isCompleted.toggle()
                let reward = quest.subQuests[index].difficulty.xpReward
                
                if quest.subQuests[index].isCompleted {
                    hero.addXP(amount: reward)
                    Haptics.shared.play(.light)
                } else {
                    hero.currentXP -= reward
                    if hero.currentXP < 0 { hero.currentXP = 0 }
                }
                
                if quest.subQuests.allSatisfy({ $0.isCompleted }) {
                    quest.isCompleted = true
                    quest.isActive = false
                    hero.addXP(amount: 50)
                    Haptics.shared.notify(.success)
                }
                try? modelContext.save()
            }
        }
    }
    
    private func toggleGlobalTimer(_ quest: Quest) {
        withAnimation(.spring()) {
            if quest.isTimerActive {
                let elapsed = Date().timeIntervalSince(quest.lastStartedAt ?? Date())
                quest.timeSpent += elapsed
                quest.isTimerActive = false
                quest.lastStartedAt = nil
                hero.totalFocusMinutes += (elapsed / 60)
                
                let session = Session(taskName: quest.title, duration: elapsed)
                modelContext.insert(session)
                overtimeAlertShown = false
                Haptics.shared.play(.medium)
            } else {
                quest.lastStartedAt = Date()
                quest.isTimerActive = true
                quest.isActive = true
                overtimeAlertShown = false
                Haptics.shared.play(.light)
            }
            try? modelContext.save()
        }
    }
    
    // MARK: - Overtime Helpers
    
    private func questElapsedTime(at date: Date) -> TimeInterval {
        var currentSession: TimeInterval = 0
        if quest.isTimerActive, let start = quest.lastStartedAt {
            currentSession = date.timeIntervalSince(start)
        }
        return quest.timeSpent + currentSession
    }
    
    private func formatOvertime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 { return "\(mins)m \(secs)s" }
        return "\(secs)s"
    }
    
    private func triggerOvertimeAlert() {
        overtimeAlertShown = true
        AudioServicesPlaySystemSound(SystemSoundID(selectedSoundID))
        Haptics.shared.notify(.warning)
        hero.burnoutLevel = min(1.0, hero.burnoutLevel + 0.1)
        try? modelContext.save()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showOvertimeAlert = true
        }
    }
    
    // MARK: - Overtime Alert View
    private var questRowOvertimeAlert: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showOvertimeAlert = false }
                }
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.alertRed.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.ballisticOrange)
                }
                
                VStack(spacing: 6) {
                    Text("FOCUS LIMIT EXCEEDED")
                        .font(.system(.subheadline, design: .monospaced)).bold()
                        .foregroundStyle(Color.alertRed)
                    Text("You've been focused for more than \(focusDuration) min. Take a break to prevent burnout.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.smokeWhite.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 8) {
                    Button {
                        withAnimation { showOvertimeAlert = false }
                        showRechargeFromOvertime = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gamecontroller.fill")
                            Text("GO RECHARGE")
                                .font(.system(.caption, design: .monospaced)).bold()
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color.toxicLime, Color.electricCyan],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                    
                    Button {
                        withAnimation { showOvertimeAlert = false }
                    } label: {
                        Text("CONTINUE ANYWAY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.ashGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(20)
            .background(Color.carbonGrey)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.alertRed.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }
    
    private func difficultyColor(_ d: QuestDifficulty) -> Color {
        switch d {
        case .routine: return .toxicLime
        case .complex: return .ballisticOrange
        case .legacy: return .alertRed
        }
    }
}


// MARK: - Quest Edit View
struct QuestEditView: View {
    @Bindable var quest: Quest
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var editTitle: String = ""
    @State private var editDetails: String = ""
    @State private var newSubTitle: String = ""
    @State private var newSubDifficulty: QuestDifficulty = .routine
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Module Details
                        settingsCard(title: "MODULE DETAILS") {
                            VStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Title")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.ashGrey)
                                    TextField("Module name", text: $editTitle)
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
                                    TextField("Technical details...", text: $editDetails, axis: .vertical)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .lineLimit(3...6)
                                        .padding(12)
                                        .background(Color.voidBlack.opacity(0.5))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        
                        // Sub-Modules
                        settingsCard(title: "SUB-MODULES (\(quest.subQuests.count))") {
                            VStack(spacing: 10) {
                                ForEach(quest.subQuests, id: \.id) { sub in
                                    HStack {
                                        Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(sub.isCompleted ? Color.toxicLime : Color.ashGrey)
                                        Text(sub.title)
                                            .font(.system(.subheadline, design: .monospaced))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        
                                        // Delete sub-quest
                                        Button {
                                            if let idx = quest.subQuests.firstIndex(where: { $0.id == sub.id }) {
                                                quest.subQuests.remove(at: idx)
                                                modelContext.delete(sub)
                                                try? modelContext.save()
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(Color.alertRed.opacity(0.6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                Divider().overlay(Color.white.opacity(0.05))
                                
                                // Add new sub-quest
                                VStack(spacing: 8) {
                                    TextField("New sub-module...", text: $newSubTitle)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(Color.voidBlack.opacity(0.5))
                                        .cornerRadius(8)
                                    
                                    HStack {
                                        Picker("Difficulty", selection: $newSubDifficulty) {
                                            ForEach(QuestDifficulty.allCases, id: \.self) { diff in
                                                Text(diff.rawValue).tag(diff)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        
                                        Button {
                                            guard !newSubTitle.isEmpty else { return }
                                            let sub = SubQuest(title: newSubTitle, difficulty: newSubDifficulty)
                                            sub.parentQuest = quest
                                            quest.subQuests.append(sub)
                                            newSubTitle = ""
                                            try? modelContext.save()
                                            Haptics.shared.play(.light)
                                        } label: {
                                            Text("ADD")
                                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(Color.toxicLime)
                                                .cornerRadius(8)
                                        }
                                        .disabled(newSubTitle.isEmpty)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Module")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ashGrey)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        quest.title = editTitle
                        quest.details = editDetails
                        try? modelContext.save()
                        Haptics.shared.notify(.success)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(Color.toxicLime)
                    .disabled(editTitle.isEmpty)
                }
            }
            .onAppear {
                editTitle = quest.title
                editDetails = quest.details
            }
        }
    }
    
    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
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
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
    }
}