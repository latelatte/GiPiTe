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
    private var audioPlayer: AVAudioPlayer?
    private var recognizedText: String = ""
    var conversationHistory: [[String: String]] = []
    private var isConversationActive = false
    private let synthesizer = StyleBertVITS2Synthesizer()
    
    // 初期設定の変数
    private var apiKey: String = ""
    private var gptModel: String = ""
    private var gptName: String = ""
    private var systemMessage: [String: String] = [:]
    
    // APIのURLを定数として宣言
    private let gptApiUrl = "https://api.openai.com/v1/chat/completions"
    
    
    // 会話履歴ボタンと閲覧ボタンの位置設定
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        loadSettings()
        setupNavigationBar()
        self.view.backgroundColor = UIColor(red:0.53, green:0.56, blue:0.79, alpha:1.0)
        speechRecognizer?.delegate = self
        synthesizer.onAudioPlaybackFinished = { [weak self] in
            self?.startSpeechRecognition()
        }
        requestSpeechAuthorization()
        
        setupUIElements()
    }
    
    
    private func setupUIElements() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 100),
            statusLabel.widthAnchor.constraint(equalToConstant: 240),
            statusLabel.heightAnchor.constraint(equalToConstant: 420)
        ])
        
        textOutput.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textOutput)
        NSLayoutConstraint.activate([
            textOutput.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 350),
            textOutput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 33),
            textOutput.widthAnchor.constraint(equalToConstant: 240),
            textOutput.heightAnchor.constraint(equalToConstant: 385)
        ])
        
        view.addSubview(viewHistoryButton)
        NSLayoutConstraint.activate([
            viewHistoryButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 370),
            viewHistoryButton.leadingAnchor.constraint(equalTo: textOutput.trailingAnchor, constant: 5),
            viewHistoryButton.widthAnchor.constraint(equalToConstant: 100),
            viewHistoryButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        view.addSubview(saveConversationButton)
        NSLayoutConstraint.activate([
            saveConversationButton.topAnchor.constraint(equalTo: viewHistoryButton.bottomAnchor, constant: 20),
            saveConversationButton.leadingAnchor.constraint(equalTo: textOutput.trailingAnchor, constant: 5),
            saveConversationButton.widthAnchor.constraint(equalToConstant: 100),
            saveConversationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupNavigationBar() {
        if let settingsImage = UIImage(named: "settings_icon")?.withRenderingMode(.alwaysOriginal) {
            let settingsButton = UIBarButtonItem(image: settingsImage, style: .plain, target: self, action: #selector(openSettings))
            self.navigationItem.rightBarButtonItem = settingsButton
        }
    }
    
    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let apiKey = defaults.string(forKey: "apiKey") {
            self.apiKey = apiKey
        }
        if let model = defaults.string(forKey: "model") {
            self.gptModel = model
        }
        if let systemMessageContent = defaults.string(forKey: "systemMessage") {
            self.systemMessage = ["role": "system", "content": systemMessageContent]
        }
        if let gptName = defaults.string(forKey: "gptName"), !gptName.isEmpty {
            self.gptName = gptName
        } else {
            self.gptName = self.gptModel
        }
    }

    
    private func initializeConversationHistory() {
        conversationHistory = [["role": "system", "content": systemMessage["content"] ?? ""]]
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
        
        textOutput.font = UIFont(name: "RoundedMplus1c", size: 15)
        textOutput.textColor = UIColor.darkGray
        textOutput.isEditable = false
    }
    
    
    @IBAction func startRecognition(_ sender: UIButton) {
        if !isConversationActive {
            isConversationActive = true
            loadSettings()
            textOutput.text = "ここに会話が記録されます  \n"
            initializeConversationHistory()
        }
        startButton.isEnabled = false
        stopButton.isEnabled = true
        startSpeechRecognition()
    }
    
    @IBAction func stopRecognition(_ sender: UIButton) {
        endConversation()
    }
    
    private func startSpeechRecognition() {
        if !audioEngine.isRunning {
            UIApplication.shared.isIdleTimerDisabled = true
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
                        self.textOutput.text += "\nわたし: \(self.recognizedText)  \n"
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
//                startSilenceTimer()
            } catch {
                statusLabel.text = "音声エンジンを開始できませんでした。エラー: \(error.localizedDescription)"
            }
        }
    }
    
    private func stopSpeechRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            UIApplication.shared.isIdleTimerDisabled = false
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        updateUIForStoppedRecognition()
        startSilenceTimer()
    }
    
    private func endConversation() {
        isConversationActive = false
        stopSpeechRecognition()
        statusLabel.text = "会話を終了しました。"
        startButton.isEnabled = true
        stopButton.isEnabled = false
        saveConversationButton.isHidden = false
        UIApplication.shared.isIdleTimerDisabled = false
        
        synthesizer.audioPlayer?.stop()
    }
    
    private func updateUIForStoppedRecognition() {
        startButton.isEnabled = true
        stopButton.isEnabled = true
        statusLabel.text = "音声認識が停止しました"
        silenceTimer?.invalidate()
    }
    
    private func startSilenceTimer() {
        silenceTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(handleSilenceTimeout), userInfo: nil, repeats: false)
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
    
    func restoreTextOutput(from fileURL: URL) {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            textOutput.text = content
        } catch {
            print("Error loading conversation detail: \(error)")
        }
        scrollTextViewToBottom()
    }

    func appendToConversationHistory(_ history: [[String: String]]) {
        conversationHistory.append(contentsOf: history)
        isConversationActive = true  // 会話がアクティブであることを設定
    }
    
    private func sendToGPT(_ text: String) {
        let serverURL = URL(string: gptApiUrl)!
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
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
                            self.textOutput.text += "\n\(self.gptName): \(content)  \n"
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
        stopSpeechRecognition()
        UIApplication.shared.isIdleTimerDisabled = true
        synthesizer.synthesizeSpeech(from: text) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.statusLabel.text = "音声合成エラー: \(error.localizedDescription)"
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                return
            }

            // Audio playback will be handled in the `playAudioData` method of `StyleBertVITS2Synthesizer`
        }
    }




    private func scrollTextViewToBottom() {
        DispatchQueue.main.async {
            let bottom = NSMakeRange(self.textOutput.text.count - 1, 1)
            self.textOutput.scrollRangeToVisible(bottom)
        }
    }



    private let viewHistoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("会話履歴閲覧", for: .normal)
        button.backgroundColor = UIColor(red:0.53, green:0.56, blue:0.79, alpha:1.0)
        button.titleLabel?.font = UIFont(name: "RoundedMplus1c", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(viewConversationHistory), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let saveConversationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("会話履歴保存", for: .normal)
        button.backgroundColor = UIColor(red: 0.639, green: 0.855, blue: 0.839, alpha: 1.0)
        button.titleLabel?.font = UIFont(name: "RoundedMplus1c", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(promptForFileNameAndSave), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    @objc private func promptForFileNameAndSave() {
        let alertController = UIAlertController(title: "ファイル名", message: "保存するファイル名を入力してください。\n空欄の場合は日時がファイル名として使用されます。", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "ファイル名"
        }
        
        let saveAction = UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let fileName = alertController.textFields?.first?.text ?? ""
            self.confirmAndSaveConversation(withFileName: fileName)
        }
        alertController.addAction(saveAction)
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    private func confirmAndSaveConversation(withFileName fileName: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var finalFileName = fileName

        if finalFileName.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            finalFileName = dateFormatter.string(from: Date())
        }

        let textFileURL = documentsURL.appendingPathComponent("\(finalFileName).txt")
        let jsonFileURL = documentsURL.appendingPathComponent("\(finalFileName).json")

        if fileManager.fileExists(atPath: textFileURL.path) || fileManager.fileExists(atPath: jsonFileURL.path) {
            // 上書き確認ダイアログを表示
            let overwriteAlert = UIAlertController(title: "上書き確認", message: "同じ名前のファイルが既に存在します。上書きしますか？", preferredStyle: .alert)
            
            let overwriteAction = UIAlertAction(title: "上書き", style: .destructive) { [weak self] _ in
                self?.saveConversationFiles(at: textFileURL, jsonFileURL: jsonFileURL)
            }
            overwriteAlert.addAction(overwriteAction)
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
            overwriteAlert.addAction(cancelAction)
            
            present(overwriteAlert, animated: true, completion: nil)
        } else {
            saveConversationFiles(at: textFileURL, jsonFileURL: jsonFileURL)
        }
    }

    private func saveConversationFiles(at textFileURL: URL, jsonFileURL: URL) {
        let conversationText = textOutput.text ?? ""

        do {
            try conversationText.write(to: textFileURL, atomically: true, encoding: .utf8)
        } catch {
            showAlert(title: "保存エラー", message: "会話履歴の保存に失敗しました: \(error.localizedDescription)")
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: conversationHistory, options: .prettyPrinted)
            try jsonData.write(to: jsonFileURL)
            showAlert(title: "保存完了", message: "会話履歴が保存されました")
        } catch {
            showAlert(title: "保存エラー", message: "会話履歴の保存に失敗しました: \(error.localizedDescription)")
        }
    }


    @objc private func viewConversationHistory() {
        let historyVC = ConversationHistoryViewController()
        navigationController?.pushViewController(historyVC, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    
}
extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 音声再生が終了したときの処理
        startSpeechRecognition()
    }
}
