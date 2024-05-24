import UIKit

class ConversationHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView: UITableView!
    private var conversationFiles: [URL] = []
    private var isSelecting = false
    private var selectedFiles: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "会話履歴"
        view.backgroundColor = .white
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadConversationFiles()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "選択", style: .plain, target: self, action: #selector(toggleSelectionMode))
    }
    
    private func loadConversationFiles() {
        let documentsURL = getDocumentsDirectory()
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            conversationFiles = fileURLs.filter { $0.pathExtension == "txt" }
            tableView.reloadData()
        } catch {
            print("Error loading conversation files: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let fileURL = conversationFiles[indexPath.row]
        cell.textLabel?.text = fileURL.deletingPathExtension().lastPathComponent
        
        if isSelecting {
            cell.accessoryType = selectedFiles.contains(fileURL) ? .checkmark : .none
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSelecting {
            let fileURL = conversationFiles[indexPath.row]
            if selectedFiles.contains(fileURL) {
                selectedFiles.removeAll { $0 == fileURL }
            } else {
                selectedFiles.append(fileURL)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            let fileURL = conversationFiles[indexPath.row]
            let detailVC = ConversationDetailViewController(fileURL: fileURL)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    // スワイプアクションを追加
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, handler) in
            let fileURL = self.conversationFiles[indexPath.row]
            do {
                try FileManager.default.removeItem(at: fileURL)
                self.conversationFiles.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                handler(true)
            } catch {
                print("Error deleting conversation file: \(error)")
                handler(false)
            }
        }
        deleteAction.backgroundColor = .red
        
        let renameAction = UIContextualAction(style: .normal, title: "名前の変更") { (action, view, handler) in
            self.showRenameAlert(for: indexPath)
            handler(true)
        }
        renameAction.backgroundColor = .orange
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        return configuration
    }
    
    private func showRenameAlert(for indexPath: IndexPath) {
        let alertController = UIAlertController(title: "名前の変更", message: "新しいファイル名を入力してください", preferredStyle: .alert)
        alertController.addTextField { textField in
            let fileURL = self.conversationFiles[indexPath.row]
            textField.text = fileURL.deletingPathExtension().lastPathComponent

            // クリアボタンを追加
            textField.clearButtonMode = .whileEditing
        }
        
        let renameAction = UIAlertAction(title: "名前の変更", style: .default) { _ in
            if let newName = alertController.textFields?.first?.text, !newName.isEmpty {
                self.renameFile(at: indexPath, to: newName)
            }
        }
        alertController.addAction(renameAction)
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func renameFile(at indexPath: IndexPath, to newName: String) {
        let oldURL = conversationFiles[indexPath.row]
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension("txt")
        
        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            conversationFiles[indexPath.row] = newURL
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } catch {
            print("Error renaming file: \(error)")
        }
    }
    
    @objc private func toggleSelectionMode() {
        isSelecting.toggle()
        selectedFiles.removeAll()
        tableView.reloadData()
        
        if isSelecting {
            navigationItem.rightBarButtonItem?.title = "キャンセル"
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "削除", style: .plain, target: self, action: #selector(confirmDeleteSelectedFiles))
        } else {
            navigationItem.rightBarButtonItem?.title = "選択"
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    @objc private func confirmDeleteSelectedFiles() {
        let alertController = UIAlertController(title: "確認", message: "選択したファイルを削除してもよろしいですか？", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "削除", style: .destructive) { _ in
            self.deleteSelectedFiles()
        }
        alertController.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func deleteSelectedFiles() {
        for fileURL in selectedFiles {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Error deleting file: \(error)")
            }
        }
        loadConversationFiles()
        toggleSelectionMode()
    }
}
