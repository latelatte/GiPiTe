import UIKit

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let models = ["gpt-4o", "gpt-3.5-turbo"]
    var selectedModel: String? = "gpt-4o"
    var presets: [String: [String: String]] = [:]

    let apiKeyTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "APIキーを入力"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        return textField
    }()

    let apiKeyURLLabel: UILabel = {
        let label = UILabel()
        let fullText = "APIキーはこちらから取得できます:\nhttps://openai.com/index/openai-api/"
        let attributedString = NSMutableAttributedString(string: fullText)
        let linkRange = (fullText as NSString).range(of: "https://openai.com/index/openai-api/")
        
        // 全体のフォントと色を設定
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: fullText.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: 0, length: fullText.count))
        
        // URL部分のスタイルを設定
        attributedString.addAttribute(.foregroundColor, value: UIColor.blue, range: linkRange)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: linkRange)
        
        label.numberOfLines = 0
        label.attributedText = attributedString
        label.isUserInteractionEnabled = true  // ユーザーインタラクションを有効にする
        return label
    }()


    let pasteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ペースト", for: .normal)
        button.addTarget(self, action: #selector(pasteApiKey), for: .touchUpInside)
        return button
    }()

    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(saveSettings), for: .touchUpInside)
        return button
    }()

    let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("クリア", for: .normal)
        button.backgroundColor = UIColor.systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(clearSettings), for: .touchUpInside)
        return button
    }()

    let gpt4Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GPT-4o", for: .normal)
        button.tag = 0
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.addTarget(self, action: #selector(modelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    let gpt35Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GPT-3.5-turbo", for: .normal)
        button.tag = 1
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.addTarget(self, action: #selector(modelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    let gptSettingsLabel: UILabel = {
        let label = UILabel()
        label.text = "GPTの設定を入力"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()

    let gptSettingsTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        return textView
    }()

    let gptDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "GPT-3.5-turboは高速、GPT-4oはより高性能です\nGPT-4oの方がコストがかかりますのでご注意ください"
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byWordWrapping
        label.textColor = .gray
        label.numberOfLines = 0
        return label
    }()

    let buttonContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    let loadPresetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("プリセットをロード/削除", for: .normal)
        button.backgroundColor = UIColor.systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(showPresetSelection), for: .touchUpInside)
        return button
    }()

    let savePresetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("プリセットを保存", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(savePreset), for: .touchUpInside)
        return button
    }()

    let presetStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 10
        return stackView
    }()

    override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .white
            title = "設定"
            view.addSubview(apiKeyTextField)
            view.addSubview(apiKeyURLLabel)
            view.addSubview(pasteButton)
            view.addSubview(saveButton)
            view.addSubview(clearButton)
            view.addSubview(gptSettingsLabel)
            view.addSubview(gptSettingsTextView)
            view.addSubview(gptDescriptionLabel)
            buttonContainer.addArrangedSubview(gpt4Button)
            buttonContainer.addArrangedSubview(gpt35Button)
            view.addSubview(buttonContainer)
            presetStackView.addArrangedSubview(loadPresetButton)
            presetStackView.addArrangedSubview(savePresetButton)
            view.addSubview(presetStackView)
            setupConstraints()
            loadSettings()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openURL))
            apiKeyURLLabel.addGestureRecognizer(tapGesture)
        }

      private func setupConstraints() {
          apiKeyTextField.translatesAutoresizingMaskIntoConstraints = false
          apiKeyURLLabel.translatesAutoresizingMaskIntoConstraints = false
          pasteButton.translatesAutoresizingMaskIntoConstraints = false
          saveButton.translatesAutoresizingMaskIntoConstraints = false
          clearButton.translatesAutoresizingMaskIntoConstraints = false
          gptSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
          gptSettingsTextView.translatesAutoresizingMaskIntoConstraints = false
          gptDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
          buttonContainer.translatesAutoresizingMaskIntoConstraints = false
          presetStackView.translatesAutoresizingMaskIntoConstraints = false

          NSLayoutConstraint.activate([
              apiKeyTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
              apiKeyTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              apiKeyTextField.trailingAnchor.constraint(equalTo: pasteButton.leadingAnchor, constant: -10),
              pasteButton.centerYAnchor.constraint(equalTo: apiKeyTextField.centerYAnchor),
              pasteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              apiKeyURLLabel.topAnchor.constraint(equalTo: apiKeyTextField.bottomAnchor, constant: 10),
              apiKeyURLLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              apiKeyURLLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              buttonContainer.topAnchor.constraint(equalTo: apiKeyURLLabel.bottomAnchor, constant: 20),
              buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              buttonContainer.heightAnchor.constraint(equalToConstant: 50),
              gptDescriptionLabel.topAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: 10),
              gptDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              gptDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              gptSettingsLabel.topAnchor.constraint(equalTo: gptDescriptionLabel.bottomAnchor, constant: 20),
              gptSettingsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              gptSettingsTextView.topAnchor.constraint(equalTo: gptSettingsLabel.bottomAnchor, constant: 5),
              gptSettingsTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              gptSettingsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              gptSettingsTextView.heightAnchor.constraint(equalToConstant: 150),
              saveButton.topAnchor.constraint(equalTo: gptSettingsTextView.bottomAnchor, constant: 20),
              saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
              saveButton.widthAnchor.constraint(equalToConstant: 100),
              saveButton.heightAnchor.constraint(equalToConstant: 40),
              clearButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 10),
              clearButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
              clearButton.widthAnchor.constraint(equalToConstant: 100),
              clearButton.heightAnchor.constraint(equalToConstant: 40),
              presetStackView.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 20),
              presetStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              presetStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              loadPresetButton.heightAnchor.constraint(equalToConstant: 40),
              savePresetButton.heightAnchor.constraint(equalToConstant: 40)
          ])
      }

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            loadSettings()
            // デフォルトの選択モデルを gpt-4o に設定
            for subview in buttonContainer.arrangedSubviews {
                if let button = subview as? UIButton {
                    button.backgroundColor = .clear
                }
            }
            if let selectedModel = selectedModel, let index = models.firstIndex(of: selectedModel) {
                let button = buttonContainer.arrangedSubviews[index] as? UIButton
                button?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            } else {
                selectedModel = models[0]
                let button = buttonContainer.arrangedSubviews[0] as? UIButton
                button?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            }
        }

    @objc func modelButtonTapped(_ sender: UIButton) {
        for subview in buttonContainer.arrangedSubviews {
            if let button = subview as? UIButton {
                button.backgroundColor = .clear
            }
        }
        sender.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        selectedModel = models[sender.tag]
    }

    @objc func pasteApiKey() {
        if let pasteboardString = UIPasteboard.general.string {
            apiKeyTextField.text = pasteboardString
        }
    }

    @objc func clearSettings() {
        gptSettingsTextView.text = ""
        for subview in buttonContainer.arrangedSubviews {
            if let button = subview as? UIButton {
                button.backgroundColor = .clear
            }
        }
        selectedModel = models.first
        let button = buttonContainer.arrangedSubviews[0] as? UIButton
        button?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
    }

    @objc func openURL() {
        if let url = URL(string: "https://openai.com/index/openai-api/") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func saveSettings() {
            guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else {
                showAlert(title: "エラー", message: "APIキーを入力してください")
                return
            }

            let defaults = UserDefaults.standard
            defaults.set(apiKey, forKey: "apiKey")
            defaults.set(selectedModel, forKey: "model")
            defaults.set(gptSettingsTextView.text, forKey: "systemMessage")

            showAlert(title: "保存完了", message: "設定が保存されました") {
                self.navigationController?.popViewController(animated: true)
            }
        }

    @objc func savePreset() {
            let alertController = UIAlertController(title: "プリセット名", message: "プリセットの名前を入力してください", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "プリセット名"
            }
            let saveAction = UIAlertAction(title: "保存", style: .default) { _ in
                if let presetName = alertController.textFields?.first?.text, !presetName.isEmpty {
                    let preset = [
                        "apiKey": self.apiKeyTextField.text ?? "",
                        "model": self.selectedModel ?? self.models.first!,
                        "systemMessage": self.gptSettingsTextView.text ?? ""
                    ]
                    self.presets[presetName] = preset
                    UserDefaults.standard.set(self.presets, forKey: "presets")
                }
            }
            alertController.addAction(saveAction)
            alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        }

        @objc func showPresetSelection() {
            let alertController = UIAlertController(title: "プリセットを選択", message: nil, preferredStyle: .actionSheet)
            for presetName in presets.keys {
                let action = UIAlertAction(title: presetName, style: .default) { _ in
                    self.showPresetOptions(for: presetName)
                }
                alertController.addAction(action)
            }
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }

        func showPresetOptions(for presetName: String) {
            let alertController = UIAlertController(title: "プリセットオプション", message: nil, preferredStyle: .actionSheet)
            let loadAction = UIAlertAction(title: "ロード", style: .default) { _ in
                self.loadPreset(named: presetName)
            }
            let deleteAction = UIAlertAction(title: "削除", style: .destructive) { _ in
                self.confirmDeletePreset(named: presetName)
            }
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
            alertController.addAction(loadAction)
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }

        func confirmDeletePreset(named presetName: String) {
            let alertController = UIAlertController(title: "削除確認", message: "\(presetName)を削除しますか？", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "削除", style: .destructive) { _ in
                self.deletePreset(named: presetName)
            }
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }

        func deletePreset(named presetName: String) {
            presets.removeValue(forKey: presetName)
            UserDefaults.standard.set(presets, forKey: "presets")
            showAlert(title: "削除完了", message: "\(presetName)を削除しました")
        }

        func loadPreset(named presetName: String) {
            if let preset = presets[presetName] {
                apiKeyTextField.text = preset["apiKey"]
                gptSettingsTextView.text = preset["systemMessage"]
                if let model = preset["model"], let index = models.firstIndex(of: model) {
                    selectedModel = model
                    for subview in buttonContainer.arrangedSubviews {
                        if let button = subview as? UIButton {
                            button.backgroundColor = .clear
                        }
                    }
                    let button = buttonContainer.arrangedSubviews[index] as? UIButton
                    button?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                }
            }
        }


    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func loadSettings() {
            let defaults = UserDefaults.standard
            apiKeyTextField.text = defaults.string(forKey: "apiKey")
            gptSettingsTextView.text = defaults.string(forKey: "systemMessage")
            if let model = defaults.string(forKey: "model"), let index = models.firstIndex(of: model) {
                selectedModel = model
                let button = buttonContainer.arrangedSubviews[index] as? UIButton
                button?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            } else {
                // デフォルトを gpt-4o に設定
                selectedModel = models[0]
                let button = buttonContainer.arrangedSubviews[0] as? UIButton
                button?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            }
            if let savedPresets = defaults.dictionary(forKey: "presets") as? [String: [String: String]] {
                presets = savedPresets
            }
        }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return presets.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(presets.keys)[row]
    }
}
