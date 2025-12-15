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

struct CreditsResponse: Codable, Sendable {
    let credits_left: Int
}

struct DreamHistory: Codable, Identifiable, Sendable {
    var id = UUID()
    let user_id: String
    let name: String?
    let surname: String?
    let dream: String
    let analysis: String
    let created_at: String
    
    private enum CodingKeys: String, CodingKey {
        case user_id, name, surname, dream, analysis, created_at
    }
}

enum APIError: Error, Equatable {
    case invalidURL
    case noData
    case parsingError
    case paymentRequired // 402
    case serverError(statusCode: Int)
    case custom(String)
}

class APIManager {
    static let shared = APIManager()
    
    func analyzeDream(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://drm-et6t.onrender.com/llm-chat") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include SIWA Token if available
        if let token = UserDefaults.standard.string(forKey: "siwa_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
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
            
            // Check HTTP Status Code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 402 {
                    completion(.failure(APIError.paymentRequired))
                    return
                }
                
                // You might want to handle other non-200 codes here
                if !(200...299).contains(httpResponse.statusCode) {
                    completion(.failure(APIError.serverError(statusCode: httpResponse.statusCode)))
                    return
                }
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
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
                    completion(.failure(APIError.parsingError))
                }
            }
        }.resume()
    }

    func fetchCredits(completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = URL(string: "https://drm-et6t.onrender.com/me/credits") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Include SIWA Token
        if let token = UserDefaults.standard.string(forKey: "siwa_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(NSError(domain: "No SIWA Token", code: -1, userInfo: nil)))
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
            
            do {
                let decoded = try JSONDecoder().decode(CreditsResponse.self, from: data)
                completion(.success(decoded.credits_left))
            } catch {
                print("Credit JSON decode failed: \(error)")
                
                // Fallback for "credits_left" key via dictionary if struct decode fails
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let credits = dict["credits_left"] as? Int {
                    completion(.success(credits))
                    return
                }
                
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchHistory(userID: String, completion: @escaping (Result<[DreamHistory], Error>) -> Void) {
        guard let url = URL(string: "https://drm-et6t.onrender.com/dream-history/\(userID)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "siwa_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let history = try JSONDecoder().decode([DreamHistory].self, from: data)
                completion(.success(history))
            } catch {
                print("History parsing error: \(error)")
                completion(.failure(APIError.parsingError))
            }
        }.resume()
    }
}
