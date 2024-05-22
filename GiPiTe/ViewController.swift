import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var textOutput: UITextView!

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var recognizedText: String = ""
    private var conversationHistory: [[String: String]] = []
    private var isConversationActive = false
    private let synthesizer = StyleBertVITS2Synthesizer()
    
    // 初期設定の変数
    private var systemMessage: [String: String] = [:]
    
    // APIのURLを定数として宣言
    private let gptApiUrl = "https://api.openai.com/v1/chat/completions"

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        loadSettings()
        setupNavigationBar()
        speechRecognizer?.delegate = self
        synthesizer.onAudioPlaybackFinished = { [weak self] in
            self?.startSpeechRecognition()
        }
        requestSpeechAuthorization()
    }

    private func setupNavigationBar() {
        let settingsButton = UIBarButtonItem(title: "設定", style: .plain, target: self, action: #selector(openSettings))
        self.navigationItem.rightBarButtonItem = settingsButton
    }

    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let systemMessageContent = defaults.string(forKey: "systemMessage") {
            self.systemMessage = ["role": "system", "content": systemMessageContent]
        }
        conversationHistory = [systemMessage]
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.startButton.isEnabled = true
                case .denied, .restricted, .notDetermined:
                    self.startButton.isEnabled = false
                    self.statusLabel.text = "音声認識の許可がありません"
                @unknown default:
                    self.startButton.isEnabled = false
                    self.statusLabel.text = "不明なエラーが発生しました"
                }
            }
        }
    }
    
    private func configureUI() {
        var startButtonConfig = UIButton.Configuration.plain()
        startButtonConfig.title = "会話を始める！"
        startButtonConfig.baseForegroundColor = UIColor(red:0.98, green:0.63, blue:0.71, alpha:1.0)
        startButtonConfig.attributedTitle?.font = UIFont(name: "RoundedMplus1c-Bold", size: 26)
        startButton.configuration = startButtonConfig

        var stopButtonConfig = UIButton.Configuration.plain()
        stopButtonConfig.title = "会話を終える！"
        stopButtonConfig.baseForegroundColor = UIColor(red:0.53, green:0.56, blue:0.79, alpha:1.0)
        stopButtonConfig.attributedTitle?.font = UIFont(name: "RoundedMplus1c-Bold", size: 26)
        stopButton.configuration = stopButtonConfig

        statusLabel.font = UIFont(name: "RoundedMplus1c-Bold", size: 17)
        statusLabel.textColor = UIColor.darkGray
        statusLabel.numberOfLines = 0
        statusLabel.lineBreakMode = .byWordWrapping

        textOutput.font = UIFont(name: "RoundedMplus1c-Bold", size: 17)
        textOutput.textColor = UIColor.darkGray
    }
    
    @IBAction func startRecognition(_ sender: UIButton) {
        isConversationActive = true
        startButton.isEnabled = false
        stopButton.isEnabled = true
        startSpeechRecognition()
    }

    @IBAction func stopRecognition(_ sender: UIButton) {
        endConversation()
    }
    
    private func startSpeechRecognition() {
        if !audioEngine.isRunning {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                statusLabel.text = "認識リクエストを作成できませんでした。"
                return
            }

            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                statusLabel.text = "オーディオセッションの設定に失敗しました。エラー: \(error.localizedDescription)"
                return
            }

            let inputNode = audioEngine.inputNode
            recognitionRequest.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "音声認識エラー: \(error.localizedDescription)"
                    }
                    self.stopSpeechRecognition()
                    return
                }

                guard let result = result else {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "音声認識結果がありません。"
                    }
                    self.stopSpeechRecognition()
                    return
                }

                self.recognizedText = result.bestTranscription.formattedString
                self.statusLabel.text = "認識中: \(self.recognizedText)"

                if result.isFinal {
                    inputNode.removeTap(onBus: 0)
                    self.audioEngine.stop()
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.updateUIForStoppedRecognition()
                    if !self.recognizedText.isEmpty {
                        self.textOutput.text += "\nわたし: \(self.recognizedText)\n"
                        self.scrollTextViewToBottom()
                        if self.recognizedText.contains("またね") {
                            self.endConversation()
                            return
                        }
                        self.sendToGPT(self.recognizedText)
                    } else {
                        DispatchQueue.main.async {
                            self.statusLabel.text = "認識結果が空です。"
                        }
                        if self.isConversationActive {
                            self.startSpeechRecognition()
                        }
                    }
                } else {
                    self.resetSilenceTimer()
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
                self.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()

            do {
                try audioEngine.start()
                statusLabel.text = "音声認識を開始しました…"
                startSilenceTimer()
            } catch {
                statusLabel.text = "音声エンジンを開始できませんでした。エラー: \(error.localizedDescription)"
            }
        }
    }
    
    private func stopSpeechRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        updateUIForStoppedRecognition()
    }

    private func endConversation() {
        isConversationActive = false
        stopSpeechRecognition()
        statusLabel.text = "会話を終了しました。"
        conversationHistory = [systemMessage]
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }

    private func updateUIForStoppedRecognition() {
        startButton.isEnabled = true
        stopButton.isEnabled = true  // "会話を終える"ボタンを有効化
        statusLabel.text = "音声認識が停止しました"
        silenceTimer?.invalidate()
    }
    
    private func startSilenceTimer() {
        silenceTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(handleSilenceTimeout), userInfo: nil, repeats: false)
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        startSilenceTimer()
    }
    
    @objc private func handleSilenceTimeout() {
        if audioEngine.isRunning {
            self.recognitionRequest?.endAudio()
        }
    }

    private func sendToGPT(_ text: String) {
        let serverURL = URL(string: gptApiUrl)!
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        // APIキーとモデルを取得
        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        let gptModel = UserDefaults.standard.string(forKey: "model") ?? "gpt-3.5-turbo"
        
        // ユーザーメッセージを追加
        conversationHistory.append(["role": "user", "content": text])

        let json: [String: Any] = [
            "model": gptModel,
            "messages": conversationHistory
        ]
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            
            // JSONデータをログに記録
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("リクエストボディ: \(jsonString)")
            }
        } catch {
            DispatchQueue.main.async {
                self.statusLabel.text = "JSONエンコードエラー: \(error.localizedDescription)"
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.statusLabel.text = "GPTリクエストエラー: \(error.localizedDescription)"
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "無効なレスポンス形式"
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "HTTPステータスコードエラー: \(httpResponse.statusCode)"
                    // レスポンスの内容をログに記録
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("レスポンス内容: \(responseString)")
                    }
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "GPTからのデータがありません。"
                }
                return
            }
            
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let choices = responseJSON["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            self.textOutput.text += "\nGPT-4: \(content)\n"
                            self.scrollTextViewToBottom()
                            self.conversationHistory.append(["role": "assistant", "content": content])
                            self.synthesizeSpeechWithStyleBertVITS2(from: content)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.statusLabel.text = "不正なレスポンス形式: \(responseJSON)"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "JSONデコードエラー"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusLabel.text = "レスポンス処理エラー: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
    
    private func synthesizeSpeechWithStyleBertVITS2(from text: String) {
        stopSpeechRecognition()  // 音声認識を一時停止
        synthesizer.synthesizeSpeech(from: text) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.statusLabel.text = "音声合成エラー: \(error.localizedDescription)"
                }
            }
            // 音声再生が完了したら、音声認識を再開
        }
    }
    
    private func scrollTextViewToBottom() {
        let range = NSMakeRange(textOutput.text.count - 1, 1)
        textOutput.scrollRangeToVisible(range)
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
