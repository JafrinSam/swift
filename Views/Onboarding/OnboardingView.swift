import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var selectedIdentity = "Full Stack Dev"
    @State private var animateIcon = false
    
    private let identities = [
        "Full Stack Dev", "iOS Engineer", "ML Researcher",
        "Cybersecurity", "Game Dev", "Data Scientist",
        "Backend Dev", "UI/UX Designer"
    ]
    
    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                questPage.tag(1)
                focusPage.tag(2)
                setupPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            // Page indicator + navigation
            VStack {
                Spacer()
                
                if currentPage < 3 {
                    // Page dots + Next button
                    HStack {
                        // Page dots
                        HStack(spacing: 8) {
                            ForEach(0..<4) { i in
                                Circle()
                                    .fill(i == currentPage ? Color.toxicLime : Color.ashGrey.opacity(0.3))
                                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                                    .clipShape(Capsule())
                                    .animation(.spring(response: 0.3), value: currentPage)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            HStack(spacing: 8) {
                                Text("NEXT")
                                    .font(.headline.bold())
                                Image(systemName: "arrow.right")
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.toxicLime)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.toxicLime.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateIcon ? 1.3 : 1.0)
                    .opacity(animateIcon ? 0.0 : 0.5)
                
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.toxicLime)
                    .scaleEffect(animateIcon ? 1.0 : 0.5)
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    animateIcon = true
                }
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    // Pulse ring
                }
            }
            
            Text("FORGEFLOW")
                .font(.system(size: 38, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            
            Text("Your Productivity Command Center")
                .font(.title3)
                .foregroundStyle(Color.ashGrey)
            
            Text("Transform deep work into an\nengaging system of progress.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ashGrey.opacity(0.8))
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Page 2: Quests
    private var questPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "list.bullet.rectangle.stack.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.electricCyan)
            
            Text("MISSION REGISTRY")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "target", text: "Break work into focused missions")
                featureRow(icon: "bolt.fill", text: "Earn XP and level up your profile")
                featureRow(icon: "flame.fill", text: "Track burnout to stay sustainable")
                featureRow(icon: "trophy.fill", text: "Complete challenges for rewards")
            }
            .padding(24)
            .background(Color.carbonGrey)
            .cornerRadius(20)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Page 3: Focus Engine
    private var focusPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 60))
                .foregroundStyle(Color.toxicLime)
            
            Text("VITALITY ENGINE")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "timer", text: "Precision focus timer with Flow Mode")
                featureRow(icon: "chart.bar.fill", text: "Daily stats with temporal analysis")
                featureRow(icon: "mic.fill", text: "Voice notes linked to missions")
                featureRow(icon: "brain.head.profile", text: "Smart burnout detection system")
            }
            .padding(24)
            .background(Color.carbonGrey)
            .cornerRadius(20)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Page 4: Setup
    private var setupPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 50))
                .foregroundStyle(Color.toxicLime)
            
            Text("INITIALIZE PROFILE")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            
            // Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("OPERATOR NAME")
                    .font(.caption.bold())
                    .foregroundStyle(Color.ashGrey)
                    .tracking(2)
                
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(.plain)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.carbonGrey)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.toxicLime.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            
            // Identity Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("SPECIALIZATION")
                    .font(.caption.bold())
                    .foregroundStyle(Color.ashGrey)
                    .tracking(2)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(identities, id: \.self) { identity in
                        Button {
                            selectedIdentity = identity
                            Haptics.shared.play(.light)
                        } label: {
                            Text(identity)
                                .font(.caption.bold())
                                .foregroundStyle(selectedIdentity == identity ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedIdentity == identity ? Color.toxicLime : Color.carbonGrey)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedIdentity == identity ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Launch Button
            Button {
                createHeroAndLaunch()
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("INITIALIZE SYSTEM")
                        .font(.headline.bold())
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.toxicLime)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Color.toxicLime)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.smokeWhite)
        }
    }
    
    private func createHeroAndLaunch() {
        let hero = Hero(
            name: userName.trimmingCharacters(in: .whitespaces),
            identity: selectedIdentity
        )
        modelContext.insert(hero)
        try? modelContext.save()
        
        Haptics.shared.notify(.success)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            hasSeenOnboarding = true
        }
    }
}
