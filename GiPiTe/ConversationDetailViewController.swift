import UIKit
import Down

class ConversationDetailViewController: UIViewController {
    
    private let fileURL: URL
    private var textView: UITextView!
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = fileURL.deletingPathExtension().lastPathComponent
        view.backgroundColor = .white
        
        textView = UITextView()
        textView.isEditable = false
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60) // Adjusted for button
        ])
        
        loadConversationDetail()
        setupContinueButton()
    }
    
    private func loadConversationDetail() {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            displayMarkdownContent(content)
        } catch {
            print("Error loading conversation detail: \(error)")
        }
    }
    
    private func setupContinueButton() {
            let continueButton = UIButton(type: .system)
            continueButton.setTitle("この会話を続ける", for: .normal)
            continueButton.addTarget(self, action: #selector(continueConversation), for: .touchUpInside)
            continueButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(continueButton)

            NSLayoutConstraint.activate([
                continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                continueButton.widthAnchor.constraint(equalToConstant: 200),
                continueButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }

        @objc private func continueConversation() {
            let jsonFileURL = fileURL.deletingPathExtension().appendingPathExtension("json")
            
            do {
                let jsonData = try Data(contentsOf: jsonFileURL)
                if let loadedHistory = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: String]] {
                    let viewController = self.navigationController?.viewControllers.first as? ViewController
                    viewController?.appendToConversationHistory(loadedHistory)
                    viewController?.restoreTextOutput(from: fileURL) // ファイルから直接読み込む
                    navigationController?.popToRootViewController(animated: true)
                }
            } catch {
                showAlert(title: "読み込みエラー", message: "会話履歴の読み込みに失敗しました: \(error.localizedDescription)")
            }
        }
    
    private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    
    private func displayMarkdownContent(_ markdown: String) {
        do {
            let down = Down(markdownString: markdown)
            let attributedString = try down.toAttributedString()
            textView.attributedText = attributedString
        } catch {
            textView.text = markdown
            print("Error converting markdown to attributed string: \(error)")
        }
    }
}
