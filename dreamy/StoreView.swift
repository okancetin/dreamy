//
//  StoreView.swift
//  dreamy
//
//  Created by okan on 13.12.25.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var paymentManager: PaymentManager
    
    // Custom Colors
    let appBackground = Color(red: 10/255, green: 5/255, blue: 30/255)
    let cardBackground = Color(red: 25/255, green: 20/255, blue: 45/255)
    let accentPurple = Color(red: 140/255, green: 80/255, blue: 250/255)
    
    var body: some View {
        ZStack {
            appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text(languageManager.localizedString("tab_home"))
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.white)
                    Spacer()
                    
                    // Balance Badge
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20)) // Slightly larger star
                            .foregroundStyle(.yellow)
                        Text("\(paymentManager.credits)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(cardBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding()
                .onAppear {
                    // Refresh credits when viewing the store
                    paymentManager.fetchBackendCredits()
                }
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(paymentManager.packages) { package in
                            Button(action: {
                                Task {
                                    await paymentManager.purchase(package)
                                }
                            }) {
                                HStack {
                                    HStack {
                                        Image(systemName: "star.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.yellow)
                                        
                                        Text("\(package.credits) \(languageManager.localizedString("credits"))")
                                            .font(.title3)
                                            .bold()
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    // If we fetched the real product, use its localized price, otherwise show loading
                                    if let product = paymentManager.products.first(where: { $0.id == package.id }) {
                                        Text(product.displayPrice)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(accentPurple)
                                            .cornerRadius(10)
                                    } else {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                    }
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await paymentManager.restorePurchases()
                            }
                        }) {
                            Text(languageManager.localizedString("restore_purchases"))
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                .underline()
                        }
                        .padding(.top, 20)
                        
                        // Terms and Privacy Links
                        VStack(spacing: 5) {
                            HStack(spacing: 5) {
                                Link("Terms of Use", destination: AppConstants.termsOfUseURL)
                                Text("•")
                                    .foregroundStyle(.gray)
                                Link("Privacy Policy", destination: AppConstants.privacyPolicyURL)
                            }
                            .font(.caption)
                            .foregroundStyle(.gray)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    StoreView()
        .environmentObject(LanguageManager())
}
