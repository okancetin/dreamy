//
//  APIManager.swift
//  dreamy
//
//  Created by okan on 13.12.25.
//

import Foundation

struct DreamRequest: Codable, Sendable {
    let prompt: String
}

struct DreamResponse: Codable, Sendable {
    let text: String?
    let response: String?
    let reply: String?
    let content: String?
    let message: String?
    
    var outputText: String {
        return text ?? response ?? reply ?? content ?? message ?? ""
    }
}

class APIManager {
    static let shared = APIManager()
    
    func analyzeDream(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://drm-et6t.onrender.com/llm-chat") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = DreamRequest(prompt: prompt)
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -1, userInfo: nil)))
                return
            }
            
            // Debug: Print raw JSON to console
            if let str = String(data: data, encoding: .utf8) {
                print("API Response: \(str)")
            }
            
            do {
                // 1. Try to decode as struct
                if let decoded = try? JSONDecoder().decode(DreamResponse.self, from: data), !decoded.outputText.isEmpty {
                     completion(.success(decoded.outputText))
                     return
                }
                
                // 2. Try generic dictionary lookup (Priority to "text")
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let text = dict["text"] as? String { completion(.success(text)); return }
                    if let text = dict["response"] as? String { completion(.success(text)); return }
                    if let text = dict["reply"] as? String { completion(.success(text)); return }
                    if let text = dict["message"] as? String { completion(.success(text)); return }
                    if let text = dict["content"] as? String { completion(.success(text)); return }
                }

                // 3. Fallback: Return raw string if parsing failed
                if let str = String(data: data, encoding: .utf8) {
                    completion(.success(str))
                } else {
                    completion(.failure(NSError(domain: "Parsing Error", code: -1, userInfo: nil)))
                }
            }
        }.resume()
    }
}
