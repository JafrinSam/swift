import SwiftUI

struct DevUtilitiesView: View {
    @State private var selectedTool = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    toolPicker
                    
                    TabView(selection: $selectedTool) {
                        JSONFormatterTool()
                            .tag(0)
                        Base64Tool()
                            .tag(1)
                        RegexTesterTool()
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Dev Tools")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var toolPicker: some View {
        HStack(spacing: 0) {
            toolTab(icon: "curlybraces", label: "JSON", index: 0)
            toolTab(icon: "lock.fill", label: "Base64", index: 1)
            toolTab(icon: "textformat.abc", label: "Regex", index: 2)
        }
        .padding(4)
        .background(Color.carbonGrey.opacity(0.5))
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func toolTab(icon: String, label: String, index: Int) -> some View {
        let isActive = selectedTool == index
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedTool = index }
            Haptics.shared.play(.light)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isActive ? .black : Color.ashGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.toxicLime : Color.clear)
            .cornerRadius(10)
        }
    }
}

// MARK: - 1. JSON Formatter
struct JSONFormatterTool: View {
    @State private var input = ""
    @State private var output = ""
    @State private var errorMsg = ""
    @State private var isValid = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                toolHeader(
                    icon: "curlybraces",
                    title: "JSON FORMATTER",
                    subtitle: "Paste raw JSON to validate & pretty-print"
                )
                
                inputEditor(text: $input, placeholder: "{\"name\":\"ForgeFlow\",\"version\":1}")
                
                actionRow
                statusBadge
                
                if !output.isEmpty {
                    outputDisplay(text: output, label: "FORMATTED OUTPUT")
                }
            }
            .padding()
        }
    }
    
    private var actionRow: some View {
        HStack(spacing: 10) {
            Button { formatJSON() } label: {
                actionLabel(icon: "wand.and.stars", text: "FORMAT")
            }
            .disabled(input.isEmpty)
            
            Button { minifyJSON() } label: {
                actionLabel(icon: "arrow.down.right.and.arrow.up.left", text: "MINIFY")
            }
            .disabled(input.isEmpty)
            
            Button {
                UIPasteboard.general.string = output.isEmpty ? input : output
                Haptics.shared.notify(.success)
            } label: {
                actionLabel(icon: "doc.on.doc", text: "COPY")
            }
            .disabled(output.isEmpty && input.isEmpty)
            
            Button { input = ""; output = ""; errorMsg = "" } label: {
                actionLabel(icon: "trash", text: "CLEAR")
            }
        }
    }
    
    private var statusBadge: some View {
        Group {
            if !errorMsg.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.alertRed)
                    Text(errorMsg)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.alertRed)
                    Spacer()
                }
                .padding(10)
                .background(Color.alertRed.opacity(0.08))
                .cornerRadius(10)
            } else if isValid && !output.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.toxicLime)
                    Text("Valid JSON")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                    Spacer()
                }
                .padding(10)
                .background(Color.toxicLime.opacity(0.08))
                .cornerRadius(10)
            }
        }
    }
    
    private func formatJSON() {
        errorMsg = ""
        isValid = false
        guard let data = input.data(using: .utf8) else {
            errorMsg = "Invalid input encoding"
            return
        }
        do {
            let obj = try JSONSerialization.jsonObject(with: data)
            let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
            output = String(data: pretty, encoding: .utf8) ?? ""
            isValid = true
            Haptics.shared.notify(.success)
        } catch {
            errorMsg = error.localizedDescription
            output = ""
        }
    }
    
    private func minifyJSON() {
        errorMsg = ""
        isValid = false
        guard let data = input.data(using: .utf8) else {
            errorMsg = "Invalid input encoding"
            return
        }
        do {
            let obj = try JSONSerialization.jsonObject(with: data)
            let compact = try JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
            output = String(data: compact, encoding: .utf8) ?? ""
            isValid = true
            Haptics.shared.notify(.success)
        } catch {
            errorMsg = error.localizedDescription
            output = ""
        }
    }
}

// MARK: - 2. Base64 Encoder/Decoder
struct Base64Tool: View {
    @State private var input = ""
    @State private var output = ""
    @State private var isEncodeMode = true
    @State private var errorMsg = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                toolHeader(
                    icon: "lock.fill",
                    title: "BASE64 CODEC",
                    subtitle: "Encode or decode Base64 strings"
                )
                
                // Mode toggle
                HStack(spacing: 0) {
                    modeButton(label: "ENCODE", active: isEncodeMode) { isEncodeMode = true }
                    modeButton(label: "DECODE", active: !isEncodeMode) { isEncodeMode = false }
                }
                .background(Color.carbonGrey.opacity(0.5))
                .cornerRadius(10)
                
                inputEditor(text: $input, placeholder: isEncodeMode ? "Hello, World!" : "SGVsbG8sIFdvcmxkIQ==")
                
                HStack(spacing: 10) {
                    Button { convert() } label: {
                        actionLabel(icon: isEncodeMode ? "lock.fill" : "lock.open.fill", text: isEncodeMode ? "ENCODE" : "DECODE")
                    }
                    .disabled(input.isEmpty)
                    
                    Button {
                        UIPasteboard.general.string = output
                        Haptics.shared.notify(.success)
                    } label: {
                        actionLabel(icon: "doc.on.doc", text: "COPY")
                    }
                    .disabled(output.isEmpty)
                    
                    Button {
                        // Swap input/output
                        let tmp = output
                        output = input
                        input = tmp
                        isEncodeMode.toggle()
                        Haptics.shared.play(.light)
                    } label: {
                        actionLabel(icon: "arrow.up.arrow.down", text: "SWAP")
                    }
                    .disabled(output.isEmpty)
                    
                    Button { input = ""; output = ""; errorMsg = "" } label: {
                        actionLabel(icon: "trash", text: "CLEAR")
                    }
                }
                
                if !errorMsg.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.alertRed)
                        Text(errorMsg)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.alertRed)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.alertRed.opacity(0.08))
                    .cornerRadius(10)
                }
                
                if !output.isEmpty {
                    outputDisplay(text: output, label: isEncodeMode ? "ENCODED" : "DECODED")
                }
            }
            .padding()
        }
    }
    
    private func modeButton(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            Haptics.shared.play(.light)
        }) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(active ? .black : Color.ashGrey)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(active ? Color.toxicLime : Color.clear)
                .cornerRadius(10)
        }
    }
    
    private func convert() {
        errorMsg = ""
        if isEncodeMode {
            guard let data = input.data(using: .utf8) else {
                errorMsg = "Invalid input"
                return
            }
            output = data.base64EncodedString()
            Haptics.shared.notify(.success)
        } else {
            guard let data = Data(base64Encoded: input) else {
                errorMsg = "Invalid Base64 string"
                output = ""
                return
            }
            guard let decoded = String(data: data, encoding: .utf8) else {
                errorMsg = "Could not decode to UTF-8"
                output = ""
                return
            }
            output = decoded
            Haptics.shared.notify(.success)
        }
    }
}

// MARK: - 3. Regex Tester
struct RegexTesterTool: View {
    @State private var pattern = ""
    @State private var testString = ""
    @State private var matches: [String] = []
    @State private var errorMsg = ""
    @State private var matchCount = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                toolHeader(
                    icon: "textformat.abc",
                    title: "REGEX TESTER",
                    subtitle: "Test regular expressions in real-time"
                )
                
                // Pattern input
                VStack(alignment: .leading, spacing: 6) {
                    Text("PATTERN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ballisticOrange)
                    TextField("e.g. \\d{3}-\\d{4}", text: $pattern)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.carbonGrey.opacity(0.5))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ballisticOrange.opacity(0.2)))
                        .onChange(of: pattern) { _, _ in testRegex() }
                }
                
                // Test string
                VStack(alignment: .leading, spacing: 6) {
                    Text("TEST STRING")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.electricCyan)
                    TextField("Text to test against...", text: $testString, axis: .vertical)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.carbonGrey.opacity(0.5))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.electricCyan.opacity(0.2)))
                        .onChange(of: testString) { _, _ in testRegex() }
                }
                
                // Results
                resultSection
                
                // Match list
                if !matches.isEmpty {
                    matchListSection
                }
                
                if !errorMsg.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.alertRed)
                        Text(errorMsg)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.alertRed)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.alertRed.opacity(0.08))
                    .cornerRadius(10)
                }
                
                // Quick patterns
                quickPatternsSection
            }
            .padding()
        }
    }
    
    private var resultSection: some View {
        HStack(spacing: 12) {
            let hasResults = matchCount > 0 && !pattern.isEmpty
            VStack(spacing: 2) {
                Text("\(matchCount)")
                    .font(.system(.title, design: .monospaced)).bold()
                    .foregroundStyle(hasResults ? Color.toxicLime : Color.ashGrey)
                Text("MATCHES")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.ashGrey)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(hasResults ? Color.toxicLime.opacity(0.06) : Color.carbonGrey.opacity(0.3))
            .cornerRadius(12)
            
            Button { pattern = ""; testString = ""; matches = []; errorMsg = ""; matchCount = 0 } label: {
                VStack(spacing: 2) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(Color.ashGrey)
                    Text("CLEAR")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.carbonGrey.opacity(0.3))
                .cornerRadius(12)
            }
        }
    }
    
    private var matchListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MATCHES")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.toxicLime)
            
            ForEach(Array(matches.enumerated()), id: \.offset) { idx, match in
                HStack(spacing: 8) {
                    Text("#\(idx + 1)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ashGrey)
                    Text(match)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.toxicLime)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = match
                        Haptics.shared.play(.light)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.ashGrey.opacity(0.5))
                    }
                }
                .padding(8)
                .background(Color.toxicLime.opacity(0.04))
                .cornerRadius(8)
            }
        }
    }
    
    private var quickPatternsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK PATTERNS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ashGrey)
            
            let patterns: [(String, String)] = [
                ("Email", "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"),
                ("URL", "https?://[^\\s]+"),
                ("IP Address", "\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b"),
                ("Phone", "\\+?\\d{1,3}[-.\\s]?\\d{3,4}[-.\\s]?\\d{4}"),
                ("Hex Color", "#[0-9A-Fa-f]{3,8}"),
            ]
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(patterns, id: \.0) { name, pat in
                        Button {
                            pattern = pat
                            testRegex()
                            Haptics.shared.play(.light)
                        } label: {
                            Text(name)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.electricCyan)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.electricCyan.opacity(0.08))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.electricCyan.opacity(0.15)))
                        }
                    }
                }
            }
        }
    }
    
    private func testRegex() {
        matches = []
        matchCount = 0
        errorMsg = ""
        
        guard !pattern.isEmpty, !testString.isEmpty else { return }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(testString.startIndex..., in: testString)
            let results = regex.matches(in: testString, range: range)
            matchCount = results.count
            
            matches = results.compactMap { result in
                guard let r = Range(result.range, in: testString) else { return nil }
                return String(testString[r])
            }
        } catch {
            errorMsg = "Invalid regex: \(error.localizedDescription)"
        }
    }
}

// MARK: - Shared Helpers
private func toolHeader(icon: String, title: String, subtitle: String) -> some View {
    VStack(spacing: 6) {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.toxicLime)
            Text(title)
                .font(.system(.headline, design: .monospaced)).bold()
                .foregroundStyle(.white)
        }
        Text(subtitle)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(Color.ashGrey)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
}

private func inputEditor(text: Binding<String>, placeholder: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text("INPUT")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.ashGrey)
        TextField(placeholder, text: text, axis: .vertical)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.white)
            .lineLimit(3...8)
            .padding(14)
            .background(Color.carbonGrey.opacity(0.5))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05)))
    }
}

private func outputDisplay(text: String, label: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.toxicLime)
            Spacer()
            Button {
                UIPasteboard.general.string = text
                Haptics.shared.notify(.success)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.ashGrey.opacity(0.6))
            }
        }
        
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Color.smokeWhite)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.toxicLime.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.toxicLime.opacity(0.1)))
    }
}

private func actionLabel(icon: String, text: String) -> some View {
    VStack(spacing: 4) {
        Image(systemName: icon)
            .font(.system(size: 12))
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
    }
    .foregroundStyle(Color.toxicLime)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Color.toxicLime.opacity(0.06))
    .cornerRadius(12)
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.toxicLime.opacity(0.1)))
}
