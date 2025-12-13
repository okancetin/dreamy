//
//  DreamInputView.swift
//  dreamy
//
//  Created by okan on 13.12.25.
//

import SwiftUI
import UIKit

struct DreamInputView: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        
        // Critical for nested scrolling behavior
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.showsVerticalScrollIndicator = true
        
        textView.delegate = context.coordinator
        
        // Ensure the internal text container allows scrolling
        textView.layoutManager.allowsNonContiguousLayout = false
        
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: DreamInputView
        
        init(_ parent: DreamInputView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
    }
}
