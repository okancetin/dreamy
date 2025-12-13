//
//  LanguageManager.swift
//  dreamy
//
//  Created by okan on 13.12.25.
//

import SwiftUI
import Combine

enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"
    case german = "de"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .german: return "Deutsch"
        }
    }
}

class LanguageManager: ObservableObject {
    @Published var currentLanguage: Language = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        }
    }
    
    func setLanguage(_ language: Language) {
        withAnimation {
            currentLanguage = language
        }
    }
    
    // MARK: - Translations
    
    func localizedString(_ key: String) -> String {
        let dict = translations[currentLanguage] ?? [:]
        return dict[key] ?? key
    }
    
    private let translations: [Language: [String: String]] = [
        .english: [
            "tell_your_dream": "Tell your dream",
            "placeholder": "Write your dream here... Share what you saw, how you felt, and any details you remember.",
            "analyze": "Analyze",
            "dream_interpretation": "Dream Interpretation",
            "output_placeholder": "Write your dream and tap Analyze.",
            "simulated_response": "This dream suggests that you are exploring new creative possibilities. The symbols indicate a desire for freedom and expression in your waking life.",
            "analyzing": "Analyzing...",
            "tab_home": "Home",
            "tab_explore": "Explore",
            "tab_sleep": "Sleep",
            "tab_favorites": "Favorites",
            "tab_profile": "Profile",
            "welcome": "Welcome to Dreamy",
            "sign_in_subtitle": "Sign in to interpret your dreams",
            "continue_guest": "Continue as Guest"
        ],
        .turkish: [
            "tell_your_dream": "Rüyanı Anlat",
            "placeholder": "Rüyanı buraya yaz... Ne gördüğünü, nasıl hissettiğini ve hatırladığın detayları paylaş.",
            "analyze": "Analiz Et",
            "dream_interpretation": "Rüya Yorumu",
            "output_placeholder": "Rüyanı yaz ve Analiz Et'e dokun.",
            "simulated_response": "Bu rüya yeni yaratıcı olasılıkları keşfettiğinizi gösterir. Semboller, uyanık yaşamınızda özgürlük ve ifade arzusuna işaret ediyor.",
            "analyzing": "Analiz ediliyor...",
            "tab_home": "Ana Sayfa",
            "tab_explore": "Keşfet",
            "tab_sleep": "Uyku",
            "tab_favorites": "Favoriler",
            "tab_profile": "Profil",
            "welcome": "Dreamy'ye Hoşgeldiniz",
            "sign_in_subtitle": "Rüyalarınızı yorumlamak için giriş yapın",
            "continue_guest": "Misafir Olarak Devam Et"
        ],
        .german: [
            "tell_your_dream": "Erzähl deinen Traum",
            "placeholder": "Schreibe deinen Traum hier... Teile, was du gesehen hast, wie du dich gefühlt hast und alle Details, an die du dich erinnerst.",
            "analyze": "Analysieren",
            "dream_interpretation": "Traumdeutung",
            "output_placeholder": "Schreibe deinen Traum und tippe auf Analysieren.",
            "simulated_response": "Dieser Traum deutet darauf hin, dass Sie neue kreative Möglichkeiten erkunden. Die Symbole weisen auf einen Wunsch nach Freiheit und Ausdruck in Ihrem Wachleben hin.",
            "analyzing": "Analysieren...",
            "tab_home": "Startseite",
            "tab_explore": "Entdecken",
            "tab_sleep": "Schlaf",
            "tab_favorites": "Favoriten",
            "tab_profile": "Profil",
            "welcome": "Willkommen bei Dreamy",
            "sign_in_subtitle": "Melden Sie sich an, um Ihre Träume zu deuten",
            "continue_guest": "Als Gast fortfahren"
        ]
    ]
}
