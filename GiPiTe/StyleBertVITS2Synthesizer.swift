//
//  VoiceVox.swift
//  GiPiTe
//
//  Created by Seiya Ikeda on 2024/05/17.
//

import Foundation

class Voicevox {
    let host = "127.0.0.1"
    let port = 50021

    func speak(text: String, speaker: Int = 14, speedScale: Float = 1.2, pitchScale: Float = 0.03, intonationScale: Float = 1.25, volumeScale: Float = 1.0, completion: @escaping (Data?) -> Void) {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        components.path = "/audio_query"
        components.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "speaker", value: String(speaker))
        ]
        
        guard let url = components.url else {
            print("Invalid URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to generate audio query: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }

            var audioQuery = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            audioQuery?["speedScale"] = speedScale
            audioQuery?["pitchScale"] = pitchScale
            audioQuery?["intonationScale"] = intonationScale
            audioQuery?["volumeScale"] = volumeScale

            guard let updatedAudioQuery = audioQuery, let audioQueryData = try? JSONSerialization.data(withJSONObject: updatedAudioQuery, options: []) else {
                completion(nil)
                return
            }

            components.path = "/synthesis"
            var synthesisRequest = URLRequest(url: components.url!)
            synthesisRequest.httpMethod = "POST"
            synthesisRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            synthesisRequest.httpBody = audioQueryData

            let synthesisTask = URLSession.shared.dataTask(with: synthesisRequest) { synthesisData, synthesisResponse, synthesisError in
                guard let synthesisData = synthesisData, synthesisError == nil else {
                    print("Synthesis failed: \(synthesisError?.localizedDescription ?? "No data")")
                    completion(nil)
                    return
                }

                completion(synthesisData)
            }
            synthesisTask.resume()
        }
        task.resume()
    }
}
