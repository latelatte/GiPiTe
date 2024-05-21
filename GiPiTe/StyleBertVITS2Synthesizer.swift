//
//  SettingsViewController.swift
//  GiPiTe
//
//  Created by Seiya Ikeda on 2024/05/21.
//

import Foundation
import AVFoundation

class StyleBertVITS2Synthesizer: NSObject {
    private var audioPlayer: AVAudioPlayer?
    var onAudioPlaybackFinished: (() -> Void)?

    func synthesizeSpeech(from text: String, completion: @escaping (Error?) -> Void) {
        // モーラリストを生成
        generateMoraToneList(from: text) { moraToneList, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let moraToneList = moraToneList else {
                completion(NSError(domain: "StyleBertVITS2Synthesizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "モーラトーンリストの生成に失敗しました"]))
                return
            }
            
            let apiURL = URL(string: "http://35.197.220.55:8000/api/multi_synthesis")!
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            
            let json: [String: Any] = [
                "lines": [
                    [
                        "model": "himari",  // モデル名を適切に設定
                        "modelFile": "model_assets/himari/himari_e100_s2100.safetensors",  // モデルファイル名を適切に設定
                        "text": text,
                        "moraToneList": moraToneList,
                        "style": "Neutral",
                        "styleWeight": 5,
                        "assistText": "",
                        "assistTextWeight": 1,
                        "speed": 1.25,
                        "noise": 0.6,
                        "noisew": 0.8,
                        "sdpRatio": 0.2,
                        "language": "JP",
                        "silenceAfter": 1,
                        "pitchScale": 1,
                        "intonationScale": 1,
                        "speaker": "speaker-id"  // スピーカーIDを適切に設定
                    ]
                ]
            ]
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonData = try! JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(NSError(domain: "StyleBertVITS2Synthesizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "音声データがありません"]))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.playAudioData(data, completion: completion)
                }
            }
            
            task.resume()
        }
    }
    
    private func generateMoraToneList(from text: String, completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        let apiURL = URL(string: "http://35.197.220.55:8000/api/g2p")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        
        let json: [String: Any] = ["text": text]
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "StyleBertVITS2Synthesizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "モーラデータがありません"]))
                }
                return
            }
            
            do {
                if let moraToneList = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    DispatchQueue.main.async {
                        completion(moraToneList, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "StyleBertVITS2Synthesizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "モーラトーンリストの解析に失敗しました"]))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    private func playAudioData(_ data: Data, completion: @escaping (Error?) -> Void) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

extension StyleBertVITS2Synthesizer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 音声再生が完了した後に、コールバックを呼び出す
        onAudioPlaybackFinished?()
    }
}
