import Foundation
import AVFoundation

class StyleBertVITS2Synthesizer: NSObject {
    var audioPlayer: AVAudioPlayer?
    var onAudioPlaybackFinished: (() -> Void)?

    func synthesizeSpeech(from text: String, completion: @escaping (Error?) -> Void) {
        let apiURL = URL(string: "http://34.81.37.8:8000/api/text_synthesis")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "text": text
        ]
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("リクエストボディ: \(jsonString)")
            }
            request.httpBody = jsonData
        } catch {
            completion(error)
            return
        }
        
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
