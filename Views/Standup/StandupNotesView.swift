import SwiftUI
import SwiftData

struct StandupNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StandupNote.date, order: .reverse) private var allNotes: [StandupNote]
    
    @State private var showEditor = false
    @State private var editingNote: StandupNote?
    
    private var todaysNote: StandupNote? {
        let cal = Calendar.current
        return allNotes.first { cal.isDateInToday($0.date) }
    }
    
    private var pastNotes: [StandupNote] {
        let cal = Calendar.current
        return allNotes.filter { !cal.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        todayCard
                        if !pastNotes.isEmpty {
                            historySection
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Standup")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let note = todaysNote {
                            editingNote = note
                        } else {
                            showEditor = true
                        }
                    } label: {
                        Image(systemName: todaysNote == nil ? "plus.circle.fill" : "pencil.circle.fill")
                            .foregroundStyle(Color.toxicLime)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                StandupEditorView(existingNote: nil)
            }
            .sheet(item: $editingNote) { note in
                StandupEditorView(existingNote: note)
            }
        }
    }
    
    // MARK: - Today's Card
    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            todayHeader
            
            if let note = todaysNote {
                filledTodayCard(note)
            } else {
                emptyTodayCard
            }
        }
    }
    
    private var todayHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY'S STANDUP")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
                Text(todayDateString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.ashGrey.opacity(0.6))
            }
            Spacer()
            Text("\(allNotes.count) entries")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.ashGrey.opacity(0.5))
        }
    }
    
    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f.string(from: Date())
    }
    
    private func filledTodayCard(_ note: StandupNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            standupField(icon: "checkmark.circle.fill", label: "YESTERDAY", text: note.yesterday, color: Color.toxicLime)
            Divider().overlay(Color.white.opacity(0.03))
            standupField(icon: "target", label: "TODAY", text: note.today, color: Color.ballisticOrange)
            Divider().overlay(Color.white.opacity(0.03))
            standupField(icon: "exclamationmark.triangle.fill", label: "BLOCKERS", text: note.blockers, color: Color.alertRed)
            
            HStack {
                Button {
                    editingNote = note
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.electricCyan)
                }
                
                Spacer()
                
                ShareLink(item: note.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.carbonGrey.opacity(0.5))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.toxicLime.opacity(0.15)))
    }
    
    private var emptyTodayCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 30))
                .foregroundStyle(Color.ashGrey.opacity(0.3))
            Text("No standup logged yet today")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            Button {
                showEditor = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("LOG STANDUP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color.toxicLime)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.carbonGrey.opacity(0.3))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.03)))
    }
    
    private func standupField(icon: String, label: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
            
            let displayText = text.isEmpty ? "—" : text
            Text(displayText)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(text.isEmpty ? Color.ashGrey.opacity(0.4) : Color.smokeWhite)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - History
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📜 HISTORY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            ForEach(pastNotes) { note in
                pastNoteRow(note)
            }
        }
    }
    
    private func pastNoteRow(_ note: StandupNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.fullDateLabel.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.electricCyan)
                Spacer()
                
                HStack(spacing: 8) {
                    ShareLink(item: note.shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.ashGrey.opacity(0.5))
                    }
                    
                    Button {
                        deleteNote(note)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.alertRed.opacity(0.5))
                    }
                }
            }
            
            if !note.yesterday.isEmpty {
                miniField(label: "Done", text: note.yesterday)
            }
            if !note.today.isEmpty {
                miniField(label: "Plan", text: note.today)
            }
            if !note.blockers.isEmpty {
                miniField(label: "Blocked", text: note.blockers)
            }
        }
        .padding(14)
        .background(Color.carbonGrey.opacity(0.3))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.03)))
    }
    
    private func miniField(label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
                .frame(width: 45, alignment: .leading)
            Text(text)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.smokeWhite.opacity(0.8))
                .lineLimit(2)
        }
    }
    
    private func deleteNote(_ note: StandupNote) {
        modelContext.delete(note)
        try? modelContext.save()
        Haptics.shared.notify(.warning)
    }
}

// MARK: - Standup Editor
struct StandupEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var existingNote: StandupNote?
    
    @State private var yesterday = ""
    @State private var today = ""
    @State private var blockers = ""
    
    private var isEditing: Bool { existingNote != nil }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        editorField(
                            icon: "checkmark.circle.fill",
                            label: "WHAT DID YOU DO YESTERDAY?",
                            placeholder: "Refactored auth module, fixed 3 bugs...",
                            text: $yesterday,
                            color: Color.toxicLime
                        )
                        
                        editorField(
                            icon: "target",
                            label: "WHAT WILL YOU DO TODAY?",
                            placeholder: "Implement payment API, write tests...",
                            text: $today,
                            color: Color.ballisticOrange
                        )
                        
                        editorField(
                            icon: "exclamationmark.triangle.fill",
                            label: "ANY BLOCKERS?",
                            placeholder: "Waiting on design specs, CI is down...",
                            text: $blockers,
                            color: Color.alertRed
                        )
                        
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Standup" : "Daily Standup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ashGrey)
                }
            }
            .onAppear {
                if let note = existingNote {
                    yesterday = note.yesterday
                    today = note.today
                    blockers = note.blockers
                }
            }
        }
    }
    
    private func editorField(icon: String, label: String, placeholder: String, text: Binding<String>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
            
            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(3...6)
                .padding(14)
                .background(Color.carbonGrey.opacity(0.5))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.1)))
        }
    }
    
    private var saveButton: some View {
        let hasContent = !yesterday.isEmpty || !today.isEmpty || !blockers.isEmpty
        
        return Button { save() } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text(isEditing ? "UPDATE STANDUP" : "LOG STANDUP")
                    .font(.system(.headline, design: .monospaced)).bold()
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity).padding(16)
            .background(hasContent ? Color.toxicLime : Color.ashGrey)
            .cornerRadius(16)
        }
        .disabled(!hasContent)
        .padding(.bottom, 30)
    }
    
    private func save() {
        if let note = existingNote {
            note.yesterday = yesterday
            note.today = today
            note.blockers = blockers
        } else {
            let note = StandupNote(
                date: Date(),
                yesterday: yesterday,
                today: today,
                blockers: blockers
            )
            modelContext.insert(note)
        }
        try? modelContext.save()
        Haptics.shared.notify(.success)
        dismiss()
    }
}
