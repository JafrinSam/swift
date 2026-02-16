import SwiftUI

struct ToolboxView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: ColorAlchemistView()) {
                    Label("Color Alchemist", systemImage: "paintbrush.fill")
                        .foregroundStyle(Color.toxicLime)
                }
                
                NavigationLink(destination: UnixOracleView()) {
                    Label("UNIX Oracle", systemImage: "clock.fill")
                        .foregroundStyle(Color.electricCyan)
                }
                
                NavigationLink(destination: JsonBeautifierView()) {
                    Label("JSON Beautifier", systemImage: "curlybraces")
                        .foregroundStyle(Color.hotPink)
                }
            }
            .navigationTitle("Toolbox")
        }
    }
}

// 1. Color Alchemist
struct ColorAlchemistView: View {
    @State private var selectedColor = Color.toxicLime
    
    var body: some View {
        VStack {
            ColorPicker("Pick a Color", selection: $selectedColor)
                .labelsHidden()
                .scaleEffect(2)
                .padding()
            
            Divider()
            
            Text("Code Snippet")
                .font(.caption)
                .foregroundStyle(.gray)
            
            // Note: Converting Color to Hex in SwiftUI is non-trivial without valid UIColor mapping in some contexts.
            // Approximating for standard sRGB colors.
            let hex = selectedColor.description 
            Text(hex)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .contextMenu {
                    Button("Copy") {
                        UIPasteboard.general.string = hex
                    }
                }
        }
        .padding()
        .navigationTitle("Color Alchemist")
    }
}

// 2. UNIX Oracle
struct UnixOracleView: View {
    @State private var timestampInput = ""
    @State private var convertedDate = "..."
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Unix Timestamp", text: $timestampInput)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: timestampInput) { _, newValue in
                    convert(newValue)
                }
            
            Text(convertedDate)
                .font(.title2)
                .fontWeight(.bold)
            
            Button("Current Time") {
                let now = Int(Date().timeIntervalSince1970)
                timestampInput = String(now)
            }
        }
        .padding()
        .navigationTitle("UNIX Oracle")
    }
    
    private func convert(_ input: String) {
        if let timeInterval = TimeInterval(input) {
            let date = Date(timeIntervalSince1970: timeInterval)
            convertedDate = date.formatted(date: .long, time: .standard)
        } else {
            convertedDate = "Invalid Timestamp"
        }
    }
}

// 3. JSON Beautifier
struct JsonBeautifierView: View {
    @State private var jsonInput = ""
    @State private var jsonOutput = ""
    
    var body: some View {
        VStack {
            TextEditor(text: $jsonInput)
                .border(Color.gray)
                .frame(height: 200)
                .overlay(Text("Input JSON").font(.caption).opacity(jsonInput.isEmpty ? 0.5 : 0), alignment: .center)
            
            Button("Beautify") {
                beautify()
            }
            .buttonStyle(.borderedProminent)
            
            ScrollView {
                Text(jsonOutput)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("JSON Beautifier")
    }
    
    private func beautify() {
        guard let data = jsonInput.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            jsonOutput = "Invalid JSON"
            return
        }
        jsonOutput = prettyString
    }
}
