import SwiftUI
import SwiftData

// MARK: - Add New Todo
struct TodoInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var priority: TodoPriority = .medium
    @State private var reminderOffset: ReminderOffset = .fifteenMin
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        detailsCard
                        scheduleCard
                        reminderCard
                        previewCard
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("New Deadline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ashGrey)
                }
            }
        }
    }
    
    // MARK: - Details
    private var detailsCard: some View {
        todoCard(title: "TASK DETAILS") {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                    TextField("e.g. Email bug report to client", text: $title)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.voidBlack.opacity(0.5))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes (optional)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                    TextField("Additional details...", text: $notes, axis: .vertical)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(Color.voidBlack.opacity(0.5))
                        .cornerRadius(10)
                }
                
                // Priority Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Priority")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                    
                    HStack(spacing: 8) {
                        ForEach(TodoPriority.allCases, id: \.self) { p in
                            priorityButton(p)
                        }
                    }
                }
            }
        }
    }
    
    private func priorityButton(_ p: TodoPriority) -> some View {
        let isSelected = priority == p
        let color = priorityDisplayColor(p)
        
        return Button {
            priority = p
            Haptics.shared.play(.light)
        } label: {
            Text(p.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(isSelected ? .black : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
    
    private func priorityDisplayColor(_ p: TodoPriority) -> Color {
        switch p {
        case .critical: return .alertRed
        case .high: return .ballisticOrange
        case .medium: return .electricCyan
        case .low: return .ashGrey
        }
    }
    
    // MARK: - Schedule
    private var scheduleCard: some View {
        todoCard(title: "SCHEDULE") {
            VStack(spacing: 12) {
                DatePicker(
                    "Due Date & Time",
                    selection: $dueDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white)
                .tint(Color.electricCyan)
            }
        }
    }
    
    // MARK: - Reminder
    private var reminderCard: some View {
        todoCard(title: "🔔 REMINDER") {
            VStack(spacing: 10) {
                ForEach(ReminderOffset.allCases, id: \.self) { offset in
                    reminderOption(offset)
                }
            }
        }
    }
    
    private func reminderOption(_ offset: ReminderOffset) -> some View {
        let isSelected = reminderOffset == offset
        
        return Button {
            reminderOffset = offset
            Haptics.shared.play(.light)
        } label: {
            HStack {
                Image(systemName: isSelected ? "bell.fill" : "bell")
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.ballisticOrange : Color.ashGrey)
                
                Text(offset.rawValue)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(isSelected ? .white : Color.ashGrey)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(Color.toxicLime)
                }
            }
            .padding(10)
            .background(isSelected ? Color.ballisticOrange.opacity(0.1) : Color.voidBlack.opacity(0.3))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Preview
    private var previewCard: some View {
        todoCard(title: "DEPLOYMENT PREVIEW") {
            VStack(spacing: 8) {
                previewRow(label: "Task", value: title.isEmpty ? "—" : title)
                Divider().overlay(Color.white.opacity(0.03))
                previewRow(label: "Due", value: formattedDueDate)
                Divider().overlay(Color.white.opacity(0.03))
                previewRow(label: "Reminder", value: reminderOffset.rawValue)
                Divider().overlay(Color.white.opacity(0.03))
                previewRow(label: "XP Reward", value: "+\(priority.xpReward) XP", color: .toxicLime)
            }
        }
    }
    
    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: dueDate)
    }
    
    private func previewRow(label: String, value: String, color: Color = .ashGrey) -> some View {
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
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button { saveTodo() } label: {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                Text("SCHEDULE TASK")
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
    
    // MARK: - Save
    private func saveTodo() {
        let todo = TodoItem(
            title: title,
            notes: notes,
            dueDate: dueDate,
            reminderOffset: reminderOffset,
            priority: priority
        )
        modelContext.insert(todo)
        try? modelContext.save()
        
        // Schedule notification
        NotificationManager.shared.scheduleTodoReminder(for: todo)
        
        Haptics.shared.notify(.success)
        dismiss()
    }
    
    // MARK: - Card Helper
    private func todoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
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
}

// MARK: - Edit Existing Todo
struct TodoEditView: View {
    @Bindable var todo: TodoItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var editTitle: String = ""
    @State private var editNotes: String = ""
    @State private var editDueDate: Date = Date()
    @State private var editPriority: TodoPriority = .medium
    @State private var editReminder: ReminderOffset = .fifteenMin
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        editDetailsCard
                        editScheduleCard
                        editReminderCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ashGrey)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdits() }
                        .foregroundStyle(Color.toxicLime)
                        .disabled(editTitle.isEmpty)
                }
            }
            .onAppear {
                editTitle = todo.title
                editNotes = todo.notes
                editDueDate = todo.dueDate
                editPriority = todo.priority
                editReminder = todo.reminderOffset
            }
        }
    }
    
    private var editDetailsCard: some View {
        editCard(title: "TASK DETAILS") {
            VStack(spacing: 12) {
                TextField("Task title", text: $editTitle)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.voidBlack.opacity(0.5))
                    .cornerRadius(10)
                
                TextField("Notes...", text: $editNotes, axis: .vertical)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color.voidBlack.opacity(0.5))
                    .cornerRadius(10)
                
                Picker("Priority", selection: $editPriority) {
                    ForEach(TodoPriority.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var editScheduleCard: some View {
        editCard(title: "SCHEDULE") {
            DatePicker(
                "Due Date",
                selection: $editDueDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.system(.subheadline, design: .monospaced))
            .foregroundStyle(.white)
            .tint(Color.electricCyan)
        }
    }
    
    private var editReminderCard: some View {
        editCard(title: "REMINDER") {
            Picker("Reminder", selection: $editReminder) {
                ForEach(ReminderOffset.allCases, id: \.self) { offset in
                    Text(offset.rawValue).tag(offset)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
        }
    }
    
    private func saveEdits() {
        todo.title = editTitle
        todo.notes = editNotes
        todo.dueDate = editDueDate
        todo.priority = editPriority
        todo.reminderOffset = editReminder
        try? modelContext.save()
        
        // Reschedule notification
        NotificationManager.shared.scheduleTodoReminder(for: todo)
        
        Haptics.shared.notify(.success)
        dismiss()
    }
    
    private func editCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
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
}
