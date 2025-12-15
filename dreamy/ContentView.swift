//
//  ContentView.swift
//  dreamy
//
//  Created by okan on 13.12.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var paymentManager = PaymentManager()
    @AppStorage("isSignedIn") private var isSignedIn = false
    @State private var selectedTab = 2
    
    // Custom Colors
    let appBackground = Color(red: 10/255, green: 5/255, blue: 30/255) // Deep dark purple
    let accentPurple = Color(red: 140/255, green: 80/255, blue: 250/255)
    
    init() {
        // Customize Tab Bar Appearance to match the dark theme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 10/255, green: 5/255, blue: 30/255, alpha: 1.0)
        
        // Unselected icon color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        if isSignedIn {
            TabView(selection: $selectedTab) {
                // 1. Home (Store)
                StoreView()
                    .tabItem {
                        Label(languageManager.localizedString("tab_home"), systemImage: "house")
                    }
                    .tag(0)
                
                // 3. Sleep (Main Functionality)
                SleepView(selectedTab: $selectedTab)
                    .tabItem {
                        Label(languageManager.localizedString("tab_sleep"), systemImage: "moon.stars.fill")
                    }
                    .tag(2)
                
                // 4. History
                HistoryView()
                    .tabItem {
                        Label(languageManager.localizedString("tab_history"), systemImage: "clock.arrow.circlepath")
                    }
                    .tag(3)
                
                // 5. Profile
                ProfileView(isSignedIn: $isSignedIn)
                    .tabItem {
                        Label(languageManager.localizedString("tab_profile"), systemImage: "person")
                    }
                    .tag(4)
            }
            .environmentObject(languageManager)
            .environmentObject(paymentManager)
            .accentColor(accentPurple)
            .preferredColorScheme(.dark)
            .onAppear {
                selectedTab = 2
            }
        } else {
            LoginView(isSignedIn: $isSignedIn)
                .environmentObject(languageManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct ProfileView: View {
    @Binding var isSignedIn: Bool
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 5/255, blue: 30/255).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(languageManager.localizedString("tab_profile"))
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                
                Button(action: {
                    // Clear state
                    UserDefaults.standard.removeObject(forKey: "siwa_token")
                    // Sign out
                    withAnimation {
                        isSignedIn = false
                    }
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// Renamed from HomeView to SleepView
struct SleepView: View {
    // MARK: - Environment & State
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var paymentManager: PaymentManager
    @Binding var selectedTab: Int
    @State private var dreamInput: String = ""
    @State private var interpretation: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var showInsufficientCreditsAlert = false
    
    // MARK: - Constants
    let maxChars = 1000
    
    // MARK: - Custom Colors
    let appBackground = Color(red: 10/255, green: 5/255, blue: 30/255) // Deep dark purple
    let cardBackground = Color(red: 25/255, green: 20/255, blue: 45/255) // Lighter dark purple
    let borderColor = Color(red: 60/255, green: 50/255, blue: 100/255)
    let accentPurple = Color(red: 140/255, green: 80/255, blue: 250/255)
    
    var body: some View {
        ZStack {
            // Background
            appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Top Bar with Language Switcher
                HStack {
                    Spacer()
                    Menu {
                        ForEach(Language.allCases) { language in
                            Button(action: {
                                languageManager.setLanguage(language)
                            }) {
                                HStack {
                                    Text(language.displayName)
                                    if languageManager.currentLanguage == language {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                
                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Input Card
                        VStack(alignment: .leading, spacing: 15) {
                            // Header
                            HStack {
                                Image(systemName: "pencil.and.outline")
                                    .foregroundStyle(accentPurple)
                                Text(languageManager.localizedString("tell_your_dream"))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            
                            // Text Input Area
                            ZStack(alignment: .topLeading) {
                                if dreamInput.isEmpty {
                                    Text(languageManager.localizedString("placeholder"))
                                        .foregroundStyle(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                                
                                DreamInputView(text: $dreamInput)
                                    .frame(height: 150)
                                    .onChange(of: dreamInput) { newValue in
                                        if newValue.count > maxChars {
                                            dreamInput = String(newValue.prefix(maxChars))
                                        }
                                    }
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                            
                            // Character Counter
                            HStack {
                                Spacer()
                                Text("\(dreamInput.count)/\(maxChars)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            
                            // Analyze Button
                            Button(action: analyzeDream) {
                                HStack {
                                    if isAnalyzing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text(languageManager.localizedString("analyze"))
                                    }
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [accentPurple, accentPurple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .disabled(isAnalyzing || dreamInput.isEmpty)
                        }
                        .padding(20)
                        .background(cardBackground)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        
                        // Output Card
                        VStack(alignment: .leading, spacing: 15) {
                            // Header
                            HStack {
                                Image(systemName: "eye")
                                    .foregroundStyle(accentPurple)
                                Text(languageManager.localizedString("dream_interpretation"))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            
                            // Output Text
                            Group {
                                if interpretation.isEmpty {
                                    Text(languageManager.localizedString("output_placeholder"))
                                        .foregroundStyle(.gray)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 40)
                                } else {
                                    // Use AttributedString for Markdown rendering
                                    if let attributedString = try? AttributedString(markdown: interpretation, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                        Text(attributedString)
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .topLeading)
                                    } else {
                                        Text(interpretation)
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .topLeading)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .padding(20)
                        .background(cardBackground)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(borderColor, lineWidth: 1)
                        )
                    }
                    .padding(.top, 20)
                }
            }
        }
        .alert(languageManager.localizedString("credits"), isPresented: $showInsufficientCreditsAlert) {
            Button(languageManager.localizedString("buy")) {
                selectedTab = 0 // Go to Store
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You need 1 credit to analyze a dream.")
        }
    }
    
    func analyzeDream() {
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 1. Check if input is valid
        guard !dreamInput.isEmpty else { return }
        
        isAnalyzing = true
        interpretation = languageManager.localizedString("analyzing")
        
        // 2. Fetch latest credits from backend
        APIManager.shared.fetchCredits { result in
            DispatchQueue.main.async {
                self.handleCreditFetchResult(result)
            }
        }
    }
    
    private func handleCreditFetchResult(_ result: Result<Int, Error>) {
        switch result {
        case .success(let backendCredits):
            // Update local manager
            paymentManager.credits = backendCredits
            
            // 3. Check sufficiency
            if paymentManager.hasSufficientCredits(cost: 1) {
                // Deduct locally for UI feedback
                paymentManager.deductCredits(cost: 1)
                
                // 4. Call Analyze API
                APIManager.shared.analyzeDream(prompt: dreamInput) { result in
                    DispatchQueue.main.async {
                        self.handleAnalysisResult(result)
                    }
                }
            } else {
                isAnalyzing = false
                interpretation = "" // Clear "Analyzing..." text
                showInsufficientCreditsAlert = true
            }
            
        case .failure(let error):
            isAnalyzing = false
            interpretation = "Error fetching credits: \(error.localizedDescription)"
        }
    }
    
    private func handleAnalysisResult(_ result: Result<String, Error>) {
        isAnalyzing = false
        switch result {
        case .success(let text):
            interpretation = text
        case .failure(let error):
            // Check for 402 Payment Required
            if let apiError = error as? APIError, apiError == .paymentRequired {
                interpretation = "" // Clear text
                showInsufficientCreditsAlert = true
                
                // Refund logic is tricky here:
                // If the server returned 402, it means it DID NOT deduct credit.
                // But we deducted 1 credit locally in `handleCreditFetchResult`.
                // So we MUST refund it locally to keep sync.
                paymentManager.credits += 1
            } else {
                interpretation = "Error: \(error.localizedDescription)"
                // Refund credit on other errors too
                paymentManager.credits += 1
            }
        }
    }
}

#Preview {
    ContentView()
}
