import UIKit

class SettingsViewController: UIViewController {
    
    let models = ["gpt-3.5-turbo", "gpt-4o"]
    var selectedModel: String? = "gpt-3.5-turbo"

    let apiKeyTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "APIキーを入力"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true  // APIキーをセキュアな入力フィールドに設定
        return textField
    }()

    let apiKeyURLLabel: UILabel = {
        let label = UILabel()
        label.text = "APIキーはこちらから取得できます: https://openai.com/index/openai-api/"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14)  // フォントサイズを14に設定
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

    let gpt4Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GPT-4o", for: .normal)
        button.tag = 1
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.addTarget(self, action: #selector(modelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    let gpt35Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GPT-3.5-turbo", for: .normal)
        button.tag = 0
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.addTarget(self, action: #selector(modelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    let gptSettingsLabel: UILabel = {
        let label = UILabel()
        label.text = "GPTの設定を入力"
        label.font = UIFont.boldSystemFont(ofSize: 16)  // フォントサイズを16に設定
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
        label.font = UIFont.systemFont(ofSize: 14)  // フォントサイズを14に設定
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

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        title = "設定"

        // すべてのビューを共通の親ビューに追加
        view.addSubview(apiKeyTextField)
        view.addSubview(apiKeyURLLabel)
        view.addSubview(pasteButton)
        view.addSubview(saveButton)
        view.addSubview(gptSettingsLabel)
        view.addSubview(gptSettingsTextView)
        view.addSubview(gptDescriptionLabel)
        buttonContainer.addArrangedSubview(gpt4Button)
        buttonContainer.addArrangedSubview(gpt35Button)
        view.addSubview(buttonContainer)

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
        gptSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
        gptSettingsTextView.translatesAutoresizingMaskIntoConstraints = false
        gptDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false

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
            gptSettingsTextView.heightAnchor.constraint(equalToConstant: 100),

            saveButton.topAnchor.constraint(equalTo: gptSettingsTextView.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSettings()
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
    
    // URLを開く処理
    @objc func openURL() {
        if let url = URL(string: "https://openai.com/index/openai-api/") {
            UIApplication.shared.open(url)
        }
    }

    @objc func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(apiKeyTextField.text, forKey: "apiKey")
        defaults.set(selectedModel, forKey: "model")
        defaults.set(gptSettingsTextView.text, forKey: "systemMessage")
        
        // 保存成功のアラートを表示
        let alertController = UIAlertController(title: "保存完了", message: "設定が保存されました", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            // メイン画面に戻る処理
            self.navigationController?.popViewController(animated: true)
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
            selectedModel = models.first
            let button = buttonContainer.arrangedSubviews[0] as? UIButton
            button?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
