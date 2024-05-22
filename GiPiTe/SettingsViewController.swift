import UIKit

class SettingsViewController: UIViewController {
    
    let models = ["gpt-3.5-turbo", "gpt-4"]
    var selectedModel: String? = "gpt-3.5-turbo"

    let apiKeyTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "APIキーを入力"
        textField.borderStyle = .roundedRect
        return textField
    }()

    let apiKeyURLLabel: UILabel = {
        let label = UILabel()
        label.text = "APIキーはここ: HTTP://URL"
        label.textColor = .gray
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
        button.setTitle("GPT-4", for: .normal)
        button.tag = 1
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.addTarget(self, action: #selector(modelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    let gpt35Button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GPT-3.5", for: .normal)
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
        return label
    }()
    
    let gptSettingsTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        return textView
    }()

    let buttonContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 1
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
        view.addSubview(gptSettingsLabel)
        view.addSubview(gptSettingsTextView)
        buttonContainer.addArrangedSubview(gpt4Button)
        buttonContainer.addArrangedSubview(gpt35Button)
        view.addSubview(buttonContainer)

        apiKeyTextField.translatesAutoresizingMaskIntoConstraints = false
        apiKeyURLLabel.translatesAutoresizingMaskIntoConstraints = false
        pasteButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        gptSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
        gptSettingsTextView.translatesAutoresizingMaskIntoConstraints = false
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

            gptSettingsLabel.topAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: 20),
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

        loadSettings()
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

    @objc func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(apiKeyTextField.text, forKey: "apiKey")
        defaults.set(selectedModel, forKey: "model")
        defaults.set(gptSettingsTextView.text, forKey: "systemMessage")

        navigationController?.popViewController(animated: true)
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
