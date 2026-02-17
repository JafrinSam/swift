import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.dueDate) private var allTodos: [TodoItem]
    @Query private var heroes: [Hero]
    
    @State private var showAddTodo = false
    @State private var searchText = ""
    @State private var showCompleted = false
    @State private var editingTodo: TodoItem?
    
    private var hero: Hero? { heroes.first }
    
    // MARK: - Filtered Lists
    private var filteredTodos: [TodoItem] {
        let active = allTodos.filter { !$0.isCompleted }
        if searchText.isEmpty { return active }
        return active.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var overdueTodos: [TodoItem] {
        filteredTodos.filter { $0.isOverdue }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    private var todayTodos: [TodoItem] {
        let cal = Calendar.current
        return filteredTodos.filter { !$0.isOverdue && cal.isDateInToday($0.dueDate) }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    private var upcomingTodos: [TodoItem] {
        let cal = Calendar.current
        return filteredTodos.filter { !$0.isOverdue && !cal.isDateInToday($0.dueDate) }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private var completedTodos: [TodoItem] {
        allTodos.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }
    
    private var activeCount: Int { allTodos.filter { !$0.isCompleted }.count }
    private var doneCount: Int { allTodos.filter { $0.isCompleted }.count }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        statsBar
                        searchBar
                        
                        if filteredTodos.isEmpty && completedTodos.isEmpty {
                            emptyState
                        } else {
                            todoSections
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Deadlines")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddTodo = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.toxicLime)
                    }
                }
            }
            .sheet(isPresented: $showAddTodo) {
                TodoInputView()
            }
            .sheet(item: $editingTodo) { todo in
                TodoEditView(todo: todo)
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
        }
    }
    
    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 12) {
            statBadge(count: overdueTodos.count, label: "OVERDUE", color: .alertRed)
            statBadge(count: todayTodos.count, label: "TODAY", color: .ballisticOrange)
            statBadge(count: upcomingTodos.count, label: "UPCOMING", color: .electricCyan)
            statBadge(count: doneCount, label: "DONE", color: .toxicLime)
        }
    }
    
    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(.title2, design: .monospaced)).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.06))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15)))
    }
    
    // MARK: - Search
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.ashGrey)
            TextField("Search tasks...", text: $searchText)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(10)
        .background(Color.carbonGrey.opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Sections
    private var todoSections: some View {
        VStack(spacing: 16) {
            if !overdueTodos.isEmpty {
                todoSection(title: "⚠️ OVERDUE", items: overdueTodos, color: .alertRed)
            }
            if !todayTodos.isEmpty {
                todoSection(title: "📌 TODAY", items: todayTodos, color: .ballisticOrange)
            }
            if !upcomingTodos.isEmpty {
                todoSection(title: "📅 UPCOMING", items: upcomingTodos, color: .electricCyan)
            }
            
            // Completed section
            if !completedTodos.isEmpty {
                completedSection
            }
        }
    }
    
    private func todoSection(title: String, items: [TodoItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            
            ForEach(items) { todo in
                TodoRow(
                    todo: todo,
                    onToggle: { toggleTodo(todo) },
                    onEdit: { editingTodo = todo },
                    onDelete: { deleteTodo(todo) }
                )
            }
        }
    }
    
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { withAnimation { showCompleted.toggle() } } label: {
                HStack {
                    Text("✅ COMPLETED (\(completedTodos.count))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                    Spacer()
                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Color.ashGrey)
                }
            }
            
            if showCompleted {
                ForEach(completedTodos) { todo in
                    TodoRow(
                        todo: todo,
                        onToggle: { toggleTodo(todo) },
                        onEdit: { editingTodo = todo },
                        onDelete: { deleteTodo(todo) }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "checklist.unchecked")
                .font(.system(size: 50))
                .foregroundStyle(Color.ashGrey.opacity(0.3))
            Text("NO ACTIVE DEADLINES")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            Text("Tap + to schedule your first task")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.ashGrey.opacity(0.6))
            
            Button { showAddTodo = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("NEW TASK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color.toxicLime)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Actions
    private func toggleTodo(_ todo: TodoItem) {
        withAnimation(.spring(response: 0.3)) {
            todo.isCompleted.toggle()
            
            if todo.isCompleted {
                todo.completedAt = Date()
                // Award XP
                if let hero = hero {
                    hero.addXP(amount: todo.priority.xpReward)
                }
                // Cancel notification
                NotificationManager.shared.cancelNotification(id: todo.notificationID)
                Haptics.shared.notify(.success)
            } else {
                todo.completedAt = nil
                // Re-schedule reminder
                NotificationManager.shared.scheduleTodoReminder(for: todo)
                Haptics.shared.play(.medium)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteTodo(_ todo: TodoItem) {
        NotificationManager.shared.cancelNotification(id: todo.notificationID)
        modelContext.delete(todo)
        try? modelContext.save()
        Haptics.shared.notify(.warning)
    }
}

// MARK: - Todo Row
struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    private var priorityColor: Color {
        switch todo.priority {
        case .critical: return .alertRed
        case .high: return .ballisticOrange
        case .medium: return .electricCyan
        case .low: return .ashGrey
        }
    }
    
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: todo.dueDate)
    }
    
    private var relativeTime: String {
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: todo.dueDate, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                checkboxIcon
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                titleRow
                detailRow
            }
            
            Spacer()
            
            // Actions
            actionButtons
        }
        .padding(12)
        .background(rowBackground)
        .cornerRadius(14)
        .overlay(rowBorder)
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \"\(todo.title)\" and cancel its reminder.")
        }
    }
    
    private var checkboxIcon: some View {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(todo.isCompleted ? Color.toxicLime : priorityColor)
    }
    
    private var titleRow: some View {
        HStack(spacing: 6) {
            Text(todo.title)
                .font(.system(.subheadline, design: .monospaced)).bold()
                .foregroundStyle(todo.isCompleted ? Color.ashGrey : .white)
                .strikethrough(todo.isCompleted)
                .lineLimit(1)
            
            if todo.isOverdue {
                Text("OVERDUE")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.alertRed)
                    .cornerRadius(4)
            }
        }
    }
    
    private var detailRow: some View {
        HStack(spacing: 8) {
            // Priority badge
            let badgeLabel = todo.priority.rawValue.uppercased()
            Text(badgeLabel)
                .font(.system(size: 7, weight: .black, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(priorityColor)
                .cornerRadius(3)
            
            // Due date
            let iconName = todo.isOverdue ? "exclamationmark.circle.fill" : "clock"
            let dateColor: Color = todo.isOverdue ? .alertRed : .ashGrey
            Image(systemName: iconName)
                .font(.system(size: 8))
                .foregroundStyle(dateColor)
            Text(timeText)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(dateColor)
            
            // Relative time
            Text("(\(relativeTime))")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.ashGrey.opacity(0.6))
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 6) {
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.electricCyan.opacity(0.6))
            }
            .buttonStyle(.plain)
            
            Button { showDeleteConfirm = true } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.alertRed.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var rowBackground: some View {
        Group {
            if todo.isOverdue {
                Color.alertRed.opacity(0.06)
            } else if todo.isCompleted {
                Color.carbonGrey.opacity(0.2)
            } else {
                Color.carbonGrey.opacity(0.4)
            }
        }
    }
    
    private var rowBorder: some View {
        let borderColor: Color = todo.isOverdue ? Color.alertRed.opacity(0.2) : Color.white.opacity(0.05)
        return RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1)
    }
}
