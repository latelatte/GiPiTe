//
//  ConversationDetailViewController.swift
//  GiPiTe
//
//  Created by Seiya Ikeda on 2024/05/23.
//

import UIKit

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
        title = fileURL.lastPathComponent
        view.backgroundColor = .white
        
        textView = UITextView()
        textView.isEditable = false
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadConversationDetail()
    }
    
    private func loadConversationDetail() {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            textView.text = content
        } catch {
            print("Error loading conversation detail: \(error)")
        }
    }
}
