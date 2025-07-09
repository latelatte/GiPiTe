# お知らせ

**当プロジェクトは現在更新を停止しています。将来的には最新OSへの対応も行う予定ですが、個人プロジェクトのため計画は未確定です。**

---

# GiPiTe

このプロジェクトは、音声認識とGPTモデルを使用してユーザーとの対話を可能にするiOSアプリです。ユーザーは音声を入力し、GPTからの応答を音声で受け取ることができます。また、会話履歴を保存して後で確認したり、続けたりすることができます。

## 機能

- 音声認識による入力
- GPTモデルとの対話
- 会話履歴の保存と読み込み
- 会話の続き機能
- 会話履歴の閲覧

## 特徴
- 会話セッションはすべて音声で進みます。こちらからの認識音声は自動でGPTに送信され、GPTからの返信はAPIサーバーを通して端末で再生されます。
- 一連の会話セッションは途切れることなく進行するため、ユーザーは画面を触ることも見ることもなく利用することができます。
- セッションを終了したい際には、「またね」と言うことで、そのセッションを終了させることができます。正規表現を用いているので、文末に「またね」が含まれていれば終わってくれます。
- Style-Bert-VITS2を用いて学習させた音声合成モデルを用いているので、感情豊かな音声で返事をしてくれます。
- 日本語の他に英語もネイティブレベルで応答することができます。
- 指定した会話セッションのコンテキストを復元することができるため、続けたかった会話を後から再開することが可能です。
- GPTにどの様に振る舞ってほしいかを設定欄で入力することができます。また、GPTのモデルやAPIキーも選択、入力することができます。

## スクリーンショット

![スクリーンショット1](Resources/splashscreen.jpeg)
![スクリーンショット2](Resources/main-screen.jpeg)
![スクリーンショット3](Resources/settings-screen.jpeg)
![スクリーンショット4](Resources/history-view.jpeg)



## インストール方法

1. このリポジトリをクローンします:
    ```sh
    git clone https://github.com/latelatte/GiPiTe.git
    ```
2. 必要な依存関係をインストールします。CocoaPodsまたはSwift Package Managerを使用している場合は、それに従ってください。
3. Xcodeを使ってデバイスにビルドしてください。


## 使用方法

1. アプリを起動します。
2. 設定画面でAPIキーとGPTモデルを設定します。
3. 音声認識ボタンを押して話しかけます。
4. GPTからの応答を受け取ります。
5. 会話履歴を保存して、後で続けることができます。

## 開発者向け情報

### 貢献方法

1. リポジトリをフォークします。
2. 新しいブランチを作成します:
    ```sh
    git checkout -b feature/your-feature-name
    ```
3. 変更をコミットします:
    ```sh
    git commit -m 'Add some feature'
    ```
4. ブランチにプッシュします:
    ```sh
    git push origin feature/your-feature-name
    ```
5. プルリクエストを作成します。

#### プロジェクト構造

- `ViewController.swift`: メインの対話ロジック
- `SettingsViewController.swift`: 設定画面のロジック
- `ConversationHistoryViewController.swift`: 会話履歴の表示
- `ConversationDetailViewController.swift`: 個別の会話履歴の詳細表示

#### 依存関係

このプロジェクトは以下のオープンソースプロジェクトを使用しています：

- [Style-Bert-VITS2](https://github.com/litagin02/Style-Bert-VITS2) - GNU Affero General Public License v3.0
- [Speech](https://developer.apple.com/documentation/speech) - Appleのライセンス
- [Foundation](https://developer.apple.com/documentation/foundation) - Appleのライセンス
- [AVFoundation](https://developer.apple.com/documentation/avfoundation) - Appleのライセンス
- [MarkdownKit](https://github.com/bmoliveira/MarkdownKit) - MITライセンス
- [UIKit](https://developer.apple.com/documentation/uikit) - Appleのライセンス

### 使用しているAPI

このプロジェクトはOpenAIのAPIを使用しています。APIの使用は[OpenAIの利用規約](https://openai.com/terms)に準拠しています。

### 使用しているモデル

このプロジェクトでは、[VOICEVOX](https://voicevox.hiroshiba.jp/)の冥鳴ひまりモデルを使用しています。VOICEVOXエンジンの一部として提供される音声合成モデルを利用しています。

### 特定のモジュールのライセンス

このプロジェクトは `text/user_dict/` モジュールを使用しており、これは [GNU Lesser General Public License v3.0](LGPL_LICENSE) の下でライセンスされています。

## ライセンス

このプロジェクトは [GNU Affero General Public License v3.0](LICENSE) の下でライセンスされています。
