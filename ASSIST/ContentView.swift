import SwiftUI
import AVFoundation
import AVKit
import Vision
import FoundationModels
import Combine
import UIKit
import Speech

// MARK: - Localization System
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case chinese = "zh"
    case french = "fr"
    case arabic = "ar"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .chinese: return "中文"
        case .french: return "Français"
        case .arabic: return "العربية"
        }
    }
    
    var nativeName: String {
        // native / localized short name used alongside displayName when needed
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .chinese: return "中文"
        case .french: return "Français"
        case .arabic: return "العربية"
        }
    }

    var isRTL: Bool { self == .arabic }

    /// Region-qualified locale for speech recognition (bare language codes aren't always recognized).
    var speechLocaleIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-ES"
        case .chinese: return "zh-CN"
        case .french: return "fr-FR"
        case .arabic: return "ar-SA"
        }
    }
}

// Application screens
enum AppScreen: Equatable {
    case login, home, language, history, video, menu, recording
    case historyDetail(Int), accessibility, notifications, about, videoSettings
}

struct LocalizedStrings {
    let scanHint: String
    let recordingText: String
    let stopSendButton: String
    let langTitle: String
    let historyTitle: String
    let historySubtitle: String
    let accountTitle: String
    let cloudStorage: String
    let signOut: String
    let menuHome: String
    let menuHistory: String
    let menuSettings: String
}

let translations: [AppLanguage: LocalizedStrings] = [
    .english: LocalizedStrings(
        scanHint: "Tap to scan · Hold for video AI",
        recordingText: "AI is listening to your question...",
        stopSendButton: "Release or tap to process",
        langTitle: "Select Language",
        historyTitle: "History",
        historySubtitle: "Your saved scans and video memories.",
        accountTitle: "Account Settings",
        cloudStorage: "Cloud Storage Used",
        signOut: "Sign Out",
        menuHome: "Home",
        menuHistory: "History",
        menuSettings: "Settings"
    ),
    .spanish: LocalizedStrings(
        scanHint: "Toque para escanear · Mantenga para IA de video",
        recordingText: "La IA está escuchando tu pregunta...",
        stopSendButton: "Suelte o toque para procesar",
        langTitle: "Seleccionar idioma",
        historyTitle: "Historial",
        historySubtitle: "Sus memorias de escaneo y video guardadas.",
        accountTitle: "Configuración de cuenta",
        cloudStorage: "Almacenamiento en la nube utilizado",
        signOut: "Cerrar sesión",
        menuHome: "Inicio",
        menuHistory: "Historial",
        menuSettings: "Ajustes"
    ),
    .chinese: LocalizedStrings(
        scanHint: "轻点扫描 · 长按视频AI",
        recordingText: "AI正在聆听您的问题...",
        stopSendButton: "松开或轻点以处理",
        langTitle: "选择语言",
        historyTitle: "历史记录",
        historySubtitle: "您保存的扫描和视频记忆。",
        accountTitle: "账户设置",
        cloudStorage: "云存储已用",
        signOut: "退出登录",
        menuHome: "首页",
        menuHistory: "历史",
        menuSettings: "设置"
    ),
    .french: LocalizedStrings(
        scanHint: "Appuyez pour scanner · Maintenez pour l'IA vidéo",
        recordingText: "L'IA écoute votre question...",
        stopSendButton: "Relâchez ou appuyez pour traiter",
        langTitle: "Choisir la langue",
        historyTitle: "Historique",
        historySubtitle: "Vos analyses et souvenirs vidéo enregistrés.",
        accountTitle: "Paramètres du compte",
        cloudStorage: "Stockage cloud utilisé",
        signOut: "Se déconnecter",
        menuHome: "Accueil",
        menuHistory: "Historique",
        menuSettings: "Paramètres"
    ),
    .arabic: LocalizedStrings(
        scanHint: "اضغط للمسح · استمر للذكاء الاصطناعي للفيديو",
        recordingText: "الذكاء الاصطناعي يستمع لسؤالك...",
        stopSendButton: "اترك أو اضغط للمعالجة",
        langTitle: "اختر اللغة",
        historyTitle: "السجل",
        historySubtitle: "عمليات المسح والذكريات المرئية المحفوظة.",
        accountTitle: "إعدادات الحساب",
        cloudStorage: "مساحة السحابة المستخدمة",
        signOut: "تسجيل الخروج",
        menuHome: "الرئيسية",
        menuHistory: "السجل",
        menuSettings: "الإعدادات"
    )
]

enum HistoryTab: Hashable {
    case scans, videos, trash
}

struct HistoryItem: Identifiable {
    let id: Int
    let type: String
    let imageURL: String
    var desc: String
    let time: String
    let date: String
    var deleted: Bool
    var previewURL: String?
    var videoURL: String? = nil
}

struct ChatMessage: Identifiable {
    var id = UUID()
    let role: String
    let text: String
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var screen: AppScreen = .login
    @Published var isLoggedIn = false
    @Published var userEmail = ""
    @Published var currentLanguage: AppLanguage = .english
    @Published var historyItems: [HistoryItem] = [
        HistoryItem(id: 1, type: "scan", imageURL: "https://images.unsplash.com/photo-1489824904134-891ab64532f1?w=120&h=120&fit=crop&auto=format", desc: "Movie theater with people", time: "3:42 PM", date: "Jun 20th, 2025", deleted: false, previewURL: nil),
        HistoryItem(id: 2, type: "scan", imageURL: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=120&h=120&fit=crop&auto=format", desc: "Stop Sign — señal de stop", time: "11:08 AM", date: "Jun 20th, 2025", deleted: false, previewURL: nil),
        HistoryItem(id: 3, type: "scan", imageURL: "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=120&h=120&fit=crop&auto=format", desc: "Broccoli — brócoli", time: "6:15 PM", date: "Jun 5th, 2025", deleted: false, previewURL: nil),
        HistoryItem(id: 4, type: "video", imageURL: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=120&h=120&fit=crop&auto=format", desc: "Pasta carbonara cooking tutorial", time: "2:10 PM", date: "Jun 5th, 2025", deleted: false, previewURL: nil),
        HistoryItem(id: 5, type: "video", imageURL: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=120&h=120&fit=crop&auto=format", desc: "Restaurant — Ask about the menu", time: "12:30 PM", date: "Jun 5th, 2025", deleted: false, previewURL: nil),
    ]
    @Published var historyTab: HistoryTab = .scans
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: "user", text: "What is being cooked in this video?"),
        ChatMessage(role: "ai", text: "The video shows someone preparing a classic pasta carbonara. They are sautéing guanciale (cured pork) in a pan, then mixing egg yolks with Pecorino Romano cheese."),
        ChatMessage(role: "user", text: "How long does it take to cook?"),
        ChatMessage(role: "ai", text: "This dish takes about 20–25 minutes total. Boiling the pasta takes 10–12 minutes, and the sauce comes together in about 8 minutes off the heat."),
    ]
    @Published var isPlaying = false
    @Published var chatInput = ""
    @Published var isRecording = false

    // Live scan result state (updated after each real scan)
    @Published var lastScanTitle: String = ""
    @Published var lastScanDescription: String = ""
    @Published var lastScanQuestion: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var isGeneratingResponse: Bool = false

    // Video settings
    @Published var videoQuality: String = "1080p"
    @Published var videoMaxDuration: Int = 60
    @Published var notificationsEnabled = true
    @Published var fontSizeMultiplier: Double = 1.0
    @Published var highContrast = false
    @Published var voiceSpeed: Double = 1.0
    @Published var isDarkMode = false
    @Published var lastPlayedVideoURL: String? = nil

    private var videoChatSession: LanguageModelSession?

    var text: LocalizedStrings {
        translations[currentLanguage] ?? translations[.english]!
    }

    let languages = AppLanguage.allCases

    func deleteItem(_ id: Int) {
        if let idx = historyItems.firstIndex(where: { $0.id == id }) {
            historyItems[idx].deleted = true
        }
    }

    func restoreItem(_ id: Int) {
        if let idx = historyItems.firstIndex(where: { $0.id == id }) {
            historyItems[idx].deleted = false
        }
    }

    func permanentlyDelete(_ id: Int) {
        historyItems.removeAll { $0.id == id }
    }

    // MARK: - AI: Scan analysis (Vision → FoundationModels)

    func analyzeScan(imageURL: URL) async {
        await MainActor.run { isAnalyzing = true }

        // Vision: classify what's in the photo
        var topLabels: [String] = []
        do {
            let request = ClassifyImageRequest()
            let results = try await request.perform(on: imageURL)
            topLabels = results
                .filter { $0.confidence > 0.3 }
                .prefix(4)
                .compactMap { obs in
                    obs.identifier
                        .components(separatedBy: ",").first?
                        .trimmingCharacters(in: .whitespaces)
                        .capitalized
                }
        } catch {
            // Vision failed — continue with LLM only
        }

        let visionContext = topLabels.isEmpty ? "an object" : topLabels.joined(separator: ", ")
        let question = questionForLanguage(currentLanguage)
        let langName = currentLanguage.displayName

        // FoundationModels: generate description
        do {
            let localeHint = Locale.Language(identifier: "en_US").isEquivalent(to: Locale.current.language)
                ? "" : "The person's locale is \(Locale.current.identifier). "
            let langInstruction = currentLanguage == .english
                ? "Respond in English."
                : "You MUST respond in \(langName)."
            let session = LanguageModelSession(
                instructions: "\(localeHint)\(langInstruction) You are a visual AI assistant that identifies objects concisely."
            )
            let prompt: String
            if currentLanguage == .english {
                prompt = "The image contains: \(visionContext). Reply with exactly 2 lines. Line 1: 'Category → Specific name' (example: 'Vegetable → Broccoli'). Line 2: one short sentence description."
            } else {
                prompt = "The image contains: \(visionContext). Reply with exactly 2 lines. Line 1: English name → \(langName) translation (example: 'Broccoli → Brócoli'). Line 2: one short sentence description in \(langName)."
            }
            let response = try await session.respond(to: prompt)
            let lines = response.content
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            let title = lines.first ?? (topLabels.first ?? "Object")
            let description = lines.dropFirst().first ?? "Detected: \(visionContext)."

            await MainActor.run {
                lastScanQuestion = question
                lastScanTitle = title
                lastScanDescription = description
                if let idx = historyItems.firstIndex(where: { $0.imageURL == imageURL.absoluteString }) {
                    historyItems[idx].desc = title
                }
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                lastScanQuestion = question
                lastScanTitle = topLabels.first ?? "Object"
                lastScanDescription = topLabels.isEmpty ? "Scan complete." : "Detected: \(visionContext)."
                if let idx = historyItems.firstIndex(where: { $0.imageURL == imageURL.absoluteString }) {
                    historyItems[idx].desc = lastScanTitle
                }
                isAnalyzing = false
            }
        }
    }

    // MARK: - AI: Video chat (FoundationModels)

    func sendMessage() {
        let trimmed = chatInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isGeneratingResponse else { return }
        messages.append(ChatMessage(role: "user", text: trimmed))
        chatInput = ""
        isGeneratingResponse = true
        Task { await generateVideoResponse(for: trimmed) }
    }

    @MainActor
    private func generateVideoResponse(for userText: String) async {
        defer { isGeneratingResponse = false }
        do {
            if videoChatSession == nil {
                videoChatSession = LanguageModelSession(
                    instructions: "You are a helpful AI video assistant. Answer questions about what the user filmed. Be concise — 1-2 sentences."
                )
            }
            let response = try await videoChatSession!.respond(to: userText)
            messages.append(ChatMessage(role: "ai", text: response.content))
        } catch {
            messages.append(ChatMessage(role: "ai", text: "I couldn't process that. Please try again."))
        }
    }

    func stopRecordingAndSend() {
        isRecording = false
        videoChatSession = nil
        messages = []
        screen = .video
        isGeneratingResponse = true
        Task { await startVideoConversation() }
    }

    @MainActor
    private func startVideoConversation() async {
        defer { isGeneratingResponse = false }
        do {
            videoChatSession = LanguageModelSession(
                instructions: "You are a helpful AI video assistant. The user just recorded a video with their phone camera."
            )
            let response = try await videoChatSession!.respond(
                to: "The user just finished recording a video. Greet them briefly and ask what they'd like to know about what they filmed. One sentence only."
            )
            messages.append(ChatMessage(role: "ai", text: response.content))
        } catch {
            messages.append(ChatMessage(role: "ai", text: "Video saved! What would you like to know about what you just recorded?"))
        }
    }

    private func questionForLanguage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "What is this?"
        case .spanish: return "¿Qué es esto?"
        case .chinese: return "这是什么？"
        case .french: return "Qu'est-ce que c'est ?"
        case .arabic: return "ما هذا؟"
        }
    }
}

// MARK: - Colors

extension Color {
    static let appPrimary = Color(red: 0.31, green: 0.42, blue: 0.97)
    static let appAccent  = Color(red: 0.49, green: 0.23, blue: 0.93)

    static let systemBg          = Color(UIColor.systemBackground)
    static let secondarySystemBg = Color(UIColor.secondarySystemBackground)
    static let systemGray5Color  = Color(UIColor.systemGray5)
    static let systemGray6Color  = Color(UIColor.systemGray6)
    static let separatorColor    = Color(UIColor.separator)
}

// MARK: - Camera

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var isSetup = false
    @Published var lastCapturedImageURL: URL? = nil
    @Published var lastCapturedVideoURL: URL? = nil
    @Published var lastCapturedVideoThumbnailURL: URL? = nil

    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var photoCaptureDelegates: [PhotoCaptureDelegate] = []
    private var movieRecordingDelegates: [MovieRecordingDelegate] = []
    var isRecording: Bool { movieOutput.isRecording }

    // MARK: - Live speech transcription (what the user actually says while recording)
    private let audioDataOutput = AVCaptureAudioDataOutput()
    private let audioProcessingQueue = DispatchQueue(label: "com.assist.audioProcessing")
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    @Published var liveTranscript: String = ""

    func setup() {
        guard !isSetup else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            requestAudioThenConfigure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.requestAudioThenConfigure() }
            }
        default:
            break
        }
    }

    /// Recorded video needs audio too — resolve mic permission before wiring up the session
    /// rather than relying on an implicit prompt when the session starts running.
    private func requestAudioThenConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
                DispatchQueue.main.async { self?.configureSession() }
            }
        default:
            configureSession()
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        if session.canSetSessionPreset(.high) { session.sessionPreset = .high }
        if session.canAddInput(input) { session.addInput(input) }
        // Add audio input so recorded movies include microphone audio
        if let audioDevice = AVCaptureDevice.default(for: .audio), let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
            if session.canAddInput(audioInput) { session.addInput(audioInput) }
        }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
        audioDataOutput.setSampleBufferDelegate(self, queue: audioProcessingQueue)
        if session.canAddOutput(audioDataOutput) { session.addOutput(audioDataOutput) }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async { self?.isSetup = true }
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (URL?) -> Void) {
        var delegate: PhotoCaptureDelegate? = nil
        delegate = PhotoCaptureDelegate { [weak self] url in
            completion(url)
            if let delegate = delegate {
                self?.photoCaptureDelegates.removeAll(where: { $0 === delegate })
            }
        }
        if let delegate = delegate {
            photoCaptureDelegates.append(delegate)
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    // MARK: - Video Recording
    private var pendingRecordingCompletion: ((URL?) -> Void)?

    func startRecording(maxDuration: Int? = nil, transcriptionLocale: Locale = Locale(identifier: "en-US")) {
        guard isSetup, !movieOutput.isRecording else { return }
        // Save directly to Documents so recordings persist
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docs.appendingPathComponent(UUID().uuidString + ".mov")

        if let max = maxDuration {
            movieOutput.maxRecordedDuration = CMTimeMake(value: Int64(max), timescale: 1)
        }

        let delegate = MovieRecordingDelegate(parent: self, fileURL: fileURL)
        movieRecordingDelegates.append(delegate)
        movieOutput.startRecording(to: fileURL, recordingDelegate: delegate)
        startTranscription(locale: transcriptionLocale)
    }

    func stopRecording(completion: ((URL?) -> Void)? = nil) {
        stopTranscription()
        guard movieOutput.isRecording else {
            completion?(nil)
            return
        }
        pendingRecordingCompletion = completion
        movieOutput.stopRecording()
    }

    private func startTranscription(locale: Locale) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            self?.audioProcessingQueue.async { self?.beginRecognition(locale: locale) }
        }
    }

    private func beginRecognition(locale: Locale) {
        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(),
              recognizer.isAvailable else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        DispatchQueue.main.async { self.liveTranscript = "" }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.liveTranscript = text }
            }
            if error != nil || result?.isFinal == true {
                self.audioProcessingQueue.async {
                    self.recognitionTask = nil
                    self.recognitionRequest = nil
                }
            }
        }
    }

    private func stopTranscription() {
        audioProcessingQueue.async { [weak self] in
            self?.recognitionRequest?.endAudio()
            self?.recognitionTask?.cancel()
            self?.recognitionTask = nil
            self?.recognitionRequest = nil
        }
    }

    fileprivate func handleRecordingFinished(_ fileURL: URL?) {
        guard let fileURL = fileURL else {
            // notify failure
            DispatchQueue.main.async {
                if let cb = self.pendingRecordingCompletion {
                    self.pendingRecordingCompletion = nil
                    cb(nil)
                }
            }
            return
        }

        // generate thumbnail asynchronously — never block this queue waiting on it
        generateThumbnailAsync(for: fileURL) { [weak self] thumbURL in
            guard let self else { return }
            DispatchQueue.main.async {
                self.lastCapturedVideoURL = fileURL
                self.lastCapturedVideoThumbnailURL = thumbURL
                if let cb = self.pendingRecordingCompletion {
                    self.pendingRecordingCompletion = nil
                    cb(fileURL)
                }
            }
        }
    }

    private func generateThumbnailAsync(for url: URL, completion: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: url)
        let imgGen = AVAssetImageGenerator(asset: asset)
        imgGen.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: 1, timescale: 2) // 0.5s

        imgGen.generateCGImageAsynchronously(for: time) { cgImage, _, _ in
            guard let cgImage else { completion(nil); return }
            let ui = UIImage(cgImage: cgImage)
            guard let data = ui.jpegData(compressionQuality: 0.8) else { completion(nil); return }
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let thumbURL = docs.appendingPathComponent(url.deletingPathExtension().lastPathComponent + "_thumb.jpg")
            do {
                try data.write(to: thumbURL)
                completion(thumbURL)
            } catch {
                completion(nil)
            }
        }
    }

    var recordedDurationSeconds: Double {
        return CMTimeGetSeconds(movieOutput.recordedDuration)
    }

    func setVideoQuality(_ quality: String) {
        session.beginConfiguration()
        switch quality {
        case "720p":
            if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }
        case "1080p":
            if session.canSetSessionPreset(.hd1920x1080) { session.sessionPreset = .hd1920x1080 }
        case "4K":
            if session.canSetSessionPreset(.hd4K3840x2160) { session.sessionPreset = .hd4K3840x2160 }
        default:
            if session.canSetSessionPreset(.high) { session.sessionPreset = .high }
        }
        session.commitConfiguration()
    }

    private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
        let completion: (URL?) -> Void
        init(completion: @escaping (URL?) -> Void) { self.completion = completion }
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let data = photo.fileDataRepresentation() else { completion(nil); return }
            let tempDir = FileManager.default.temporaryDirectory
            let url = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")
            do {
                try data.write(to: url)
                completion(url)
            } catch {
                completion(nil)
            }
        }
    }

    private class MovieRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
        weak var parent: CameraManager?
        let fileURL: URL

        init(parent: CameraManager, fileURL: URL) {
            self.parent = parent
            self.fileURL = fileURL
        }

        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            defer {
                // remove self from parent's delegate list to avoid leaks
                DispatchQueue.main.async { [weak self] in
                    if let p = self?.parent, let selfRef = self {
                        p.movieRecordingDelegates.removeAll { $0 === selfRef }
                    }
                }
            }

            if let err = error {
                print("Movie recording error: \(err)")
                parent?.handleRecordingFinished(nil)
                return
            }

            // Ensure file exists
            guard FileManager.default.fileExists(atPath: outputFileURL.path) else { parent?.handleRecordingFinished(nil); return }
            parent?.handleRecordingFinished(outputFileURL)
        }
    }

    // helper to clean up delegates if needed
    private func removeRecordingDelegate(_ d: MovieRecordingDelegate) {
        movieRecordingDelegates.removeAll { $0 === d }
    }
}

extension CameraManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        recognitionRequest?.appendAudioSampleBuffer(sampleBuffer)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}

    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var state  = AppState()
    @StateObject private var camera = CameraManager()

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch state.screen {
                case .login:       LoginView(state: state)
                case .home:        HomeView(state: state, camera: camera)
                case .language:    LanguageView(state: state)
                case .history:     HistoryView(state: state)
                case .video:       VideoView(state: state, camera: camera)
                case .recording:   RecordingView(state: state, camera: camera)
                case .menu:        MenuView(state: state)
                case .historyDetail(let id): HistoryDetailView(state: state, itemId: id)
                case .accessibility: AccessibilityView(state: state)
                case .notifications: NotificationsView(state: state)
                case .about:       AboutView(state: state)
                case .videoSettings: VideoSettingsView(state: state, camera: camera)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.22), value: state.screen)

            if state.isLoggedIn && state.screen != .login {
                BottomNavBar(state: state)
                    .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear { camera.setup() }
    }
}

// MARK: - Login View

struct LoginView: View {
    @ObservedObject var state: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.31, green: 0.42, blue: 0.97),
                    Color(red: 0.49, green: 0.23, blue: 0.93)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.2)).frame(width: 80, height: 80)
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }

                    Text("Visual AI")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your eyes powered by AI")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        TextField("Enter your email", text: $email)
                            .font(.system(size: 15))
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        SecureField("Enter your password", text: $password)
                            .font(.system(size: 15))
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if showError {
                        Text("Invalid email or password")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }

                    Button {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isLoading = false
                            if !email.isEmpty && !password.isEmpty {
                                state.userEmail = email
                                state.isLoggedIn = true
                                state.screen = .home
                            } else {
                                showError = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showError = false
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(Color(red: 0.31, green: 0.42, blue: 0.97))
                                }
                                Text(isLoading ? "Signing in..." : "Sign In")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(red: 0.31, green: 0.42, blue: 0.97))
                            }
                        }
                        .frame(height: 48)
                    }
                    .disabled(isLoading)
                }

                VStack(spacing: 12) {
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                        Text("or").font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                        Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                    }

                    Button {
                        // Demo: Autofill for testing
                        email = "demo@visualai.com"
                        password = "demo123"
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isLoading = false
                            state.userEmail = email
                            state.isLoggedIn = true
                            state.screen = .home
                        }
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Text("G").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                            Text("Demo Account")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}

// MARK: - Bottom Nav

struct BottomNavBar: View {
    @ObservedObject var state: AppState

    private var isHome:    Bool { state.screen == .home }
    private var isHistory: Bool { state.screen == .history }
    private var isMenu:    Bool { state.screen == .menu }

    var body: some View {
        HStack(spacing: 0) {
            Button { state.screen = isMenu ? .home : .menu } label: {
                VStack(spacing: 3) {
                    Image(systemName: isMenu ? "xmark" : "line.3.horizontal")
                        .font(.system(size: 20))
                    Text(isMenu ? "Close" : "Menu")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(isMenu ? .appPrimary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
            }

            Button { state.screen = .home } label: {
                VStack(spacing: 3) {
                    if isHome {
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 60, height: 60)
                                .shadow(color: .appPrimary.opacity(0.35), radius: 8, y: 4)
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .offset(y: -10)
                    } else {
                        Image(systemName: "house")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    Text("Home")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isHome ? .appPrimary : .secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
            }

            Button { state.screen = .history } label: {
                VStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                    Text("History")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(isHistory ? .appPrimary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
            }
        }
        .background(
            Color.systemBg
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Scan Corner Brackets

struct ScanCorners: View {
    var color: Color = .white

    var body: some View {
        GeometryReader { geo in
            let arm: CGFloat = 24
            let t:   CGFloat = 3.5
            let p:   CGFloat = 16
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: p, y: p + arm))
                    path.addLine(to: CGPoint(x: p, y: p))
                    path.addLine(to: CGPoint(x: p + arm, y: p))
                }.stroke(color, lineWidth: t)

                Path { path in
                    path.move(to: CGPoint(x: w - p - arm, y: p))
                    path.addLine(to: CGPoint(x: w - p, y: p))
                    path.addLine(to: CGPoint(x: w - p, y: p + arm))
                }.stroke(color, lineWidth: t)

                Path { path in
                    path.move(to: CGPoint(x: p, y: h - p - arm))
                    path.addLine(to: CGPoint(x: p, y: h - p))
                    path.addLine(to: CGPoint(x: p + arm, y: h - p))
                }.stroke(color, lineWidth: t)

                Path { path in
                    path.move(to: CGPoint(x: w - p - arm, y: h - p))
                    path.addLine(to: CGPoint(x: w - p, y: h - p))
                    path.addLine(to: CGPoint(x: w - p, y: h - p - arm))
                }.stroke(color, lineWidth: t)
            }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @ObservedObject var state: AppState
    @ObservedObject var camera: CameraManager
    @State private var showingScanSaved = false
    @State private var isSpeaking = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles").foregroundColor(.appPrimary)
                        Text("Visual AI").font(.system(size: 17, weight: .bold))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Viewfinder
                ZStack {
                    Color.black
                    if camera.isSetup {
                        CameraPreview(session: camera.session)
                    } else {
                        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=700&h=500&fit=crop&auto=format")) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color.systemGray5Color
                        }
                    }
                    ScanCorners()

                    VStack {
                        HStack {
                            Button {
                                state.screen = .language
                            } label: {
                                HStack(spacing: 5) {
                                    Text("\(state.currentLanguage.displayName) / \(state.currentLanguage.nativeName)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.appPrimary)
                                .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .frame(height: 248)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 16)

                // Last question card
                VStack(alignment: .leading, spacing: 4) {
                    Text("LAST QUESTION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1)
                    Text(state.lastScanQuestion.isEmpty ? "No scans yet" : state.lastScanQuestion)
                        .font(.system(size: 22, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.secondarySystemBg)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                // AI result card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 13))
                            Text("AI DESCRIPTION")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(1)
                        }
                        Spacer()
                        Button {
                            speakDescription()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(isSpeaking ? Color.white.opacity(0.4) : Color.white.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                        }
                        .disabled(state.isAnalyzing)
                    }
                    if state.isAnalyzing {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Analyzing image…")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    } else if state.lastScanTitle.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(.white.opacity(0.85))
                            Text("Point your camera at something and tap to scan.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    } else {
                        Text(state.lastScanTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(state.lastScanDescription)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(16)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)

                // Capture button
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(state.isAnalyzing ? Color.gray.opacity(0.5) : Color.appAccent)
                            .frame(width: 80, height: 80)
                            .shadow(color: .appAccent.opacity(state.isAnalyzing ? 0 : 0.4), radius: 12, y: 4)
                        if state.isAnalyzing {
                            ProgressView().tint(.white).scaleEffect(1.4)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture {
                        guard !state.isAnalyzing else { return }
                        capturePhoto()
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        guard !state.isAnalyzing else { return }
                        state.isRecording = true
                        state.screen = .recording
                    }
                    Text(state.isAnalyzing ? "Analyzing…" : state.text.scanHint)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .overlay(alignment: .top) {
                if showingScanSaved {
                    Text("Scan saved!")
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .transition(.opacity)
                        .zIndex(100)
                        .padding(.top, 40)
                }
            }
        }
    }

    private func capturePhoto() {
        camera.capturePhoto { url in
            if let url = url {
                DispatchQueue.main.async {
                    let newId = (state.historyItems.map { $0.id }.max() ?? 0) + 1
                    let timeString = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
                    let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
                    state.historyItems.insert(HistoryItem(
                        id: newId,
                        type: "scan",
                        imageURL: url.absoluteString,
                        desc: "Analyzing…",
                        time: timeString,
                        date: dateString,
                        deleted: false,
                        previewURL: url.absoluteString
                    ), at: 0)
                    showingScanSaved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showingScanSaved = false }
                    }
                    // Run Vision + FoundationModels analysis
                    Task { await state.analyzeScan(imageURL: url) }
                }
            }
        }
    }

    private func speakDescription() {
        let descText = "\(state.lastScanTitle). \(state.lastScanDescription)"
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        let utterance = AVSpeechUtterance(string: descText)
        utterance.voice = AVSpeechSynthesisVoice(language: state.currentLanguage.rawValue)
        utterance.rate = Float(state.voiceSpeed) * AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
        isSpeaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            isSpeaking = false
        }
    }
}

// MARK: - Language View

struct LanguageView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { state.screen = .home }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
                .padding(.leading, 8)
                Text(state.text.langTitle)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.leading, 8)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(Color.systemBg)
            Divider()
            List {
                ForEach(state.languages) { lang in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(lang.displayName)
                                .font(.system(size: 18, weight: .semibold))
                            if lang.nativeName != lang.displayName {
                                Text(lang.nativeName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if lang == state.currentLanguage {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appPrimary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        state.currentLanguage = lang
                        state.screen = .home
                    }
                }
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

// MARK: - Shared Helper Views

/// Displays either a local file (captured photo/thumbnail) or a remote URL (demo data).
struct ThumbnailImage: View {
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString), url.isFileURL, let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else if let url = URL(string: urlString) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.systemGray5Color
                }
            } else {
                Color.systemGray5Color
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 40) }
            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(message.role == "user" ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.role == "user" ? Color.appPrimary : Color.systemGray6Color)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if message.role != "user" { Spacer(minLength: 40) }
        }
    }
}

/// Consistent back-chevron + title header used by detail/settings screens.
struct DetailHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appPrimary)
            }
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .padding(.leading, 8)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(.appPrimary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - History

struct HistoryView: View {
    @ObservedObject var state: AppState

    private var filteredItems: [HistoryItem] {
        switch state.historyTab {
        case .scans:  return state.historyItems.filter { $0.type == "scan" && !$0.deleted }
        case .videos: return state.historyItems.filter { $0.type == "video" && !$0.deleted }
        case .trash:  return state.historyItems.filter { $0.deleted }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.text.historyTitle).font(.system(size: 28, weight: .bold))
                Text(state.text.historySubtitle).font(.system(size: 13)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Picker("", selection: $state.historyTab) {
                Text("Scans").tag(HistoryTab.scans)
                Text("Videos").tag(HistoryTab.videos)
                Text("Trash").tag(HistoryTab.trash)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if filteredItems.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.system(size: 36)).foregroundColor(.secondary)
                    Text(state.historyTab == .trash ? "Trash is empty" : "Nothing here yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(filteredItems) { item in
                        HStack(spacing: 12) {
                            ThumbnailImage(urlString: item.imageURL)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.desc).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                                Text("\(item.date) · \(item.time)").font(.system(size: 12)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: item.type == "video" ? "video.fill" : "photo.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 13))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if state.historyTab != .trash {
                                state.screen = .historyDetail(item.id)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if state.historyTab == .trash {
                                Button(role: .destructive) { state.permanentlyDelete(item.id) } label: { Label("Delete", systemImage: "trash") }
                                Button { state.restoreItem(item.id) } label: { Label("Restore", systemImage: "arrow.uturn.backward") }
                                    .tint(.appPrimary)
                            } else {
                                Button(role: .destructive) { state.deleteItem(item.id) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

struct VideoPlayerSheet: View {
    let url: URL?

    var body: some View {
        if let url {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()
        } else {
            Text("Video unavailable").foregroundColor(.secondary)
        }
    }
}

struct HistoryDetailView: View {
    @ObservedObject var state: AppState
    var itemId: Int
    @State private var showPlayer = false

    private var item: HistoryItem? {
        state.historyItems.first { $0.id == itemId }
    }

    var body: some View {
        VStack(spacing: 0) {
            DetailHeader(title: "Details") { state.screen = .history }
            Divider()

            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ThumbnailImage(urlString: item.imageURL)
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 260)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.desc).font(.system(size: 20, weight: .bold))
                            Text("\(item.date) · \(item.time)").font(.system(size: 13)).foregroundColor(.secondary)
                        }

                        if item.type == "video", let vURLString = item.videoURL, !vURLString.isEmpty {
                            Button { showPlayer = true } label: {
                                Label("Play Video", systemImage: "play.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .background(Color.appPrimary)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if item.deleted {
                            Button {
                                state.restoreItem(item.id)
                                state.screen = .history
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .background(Color.secondarySystemBg)
                            .foregroundColor(.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Button(role: .destructive) {
                                state.deleteItem(item.id)
                                state.screen = .history
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                }
                .sheet(isPresented: $showPlayer) {
                    VideoPlayerSheet(url: URL(string: item.videoURL ?? ""))
                }
            } else {
                Spacer()
                Text("Item not found").foregroundColor(.secondary)
                Spacer()
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

// MARK: - Video Chat

struct VideoView: View {
    @ObservedObject var state: AppState
    @ObservedObject var camera: CameraManager
    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { state.screen = .home } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
                Spacer()
                Text("Video AI").font(.system(size: 17, weight: .bold))
                Spacer()
                Color.clear.frame(width: 20, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            Divider()

            if let url = camera.lastCapturedVideoURL {
                VideoPlayer(player: player)
                    .frame(height: 220)
                    .background(Color.black)
                    .onAppear {
                        if player == nil { player = AVPlayer(url: url) }
                    }
            } else {
                ZStack {
                    Color.systemGray6Color
                    Image(systemName: "video.slash").font(.system(size: 32)).foregroundColor(.secondary)
                }
                .frame(height: 220)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(state.messages) { msg in
                            ChatBubble(message: msg).id(msg.id)
                        }
                        if state.isGeneratingResponse {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Thinking…").font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: state.messages.count) { _, _ in
                    if let last = state.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()
            HStack(spacing: 10) {
                TextField("Ask about the video…", text: $state.chatInput)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(Color.systemGray6Color)
                    .clipShape(Capsule())
                    .onSubmit { state.sendMessage() }
                Button {
                    state.sendMessage()
                } label: {
                    ZStack {
                        Circle().fill(Color.appPrimary).frame(width: 40, height: 40)
                        Image(systemName: "arrow.up").foregroundColor(.white).font(.system(size: 15, weight: .bold))
                    }
                }
                .disabled(state.chatInput.trimmingCharacters(in: .whitespaces).isEmpty || state.isGeneratingResponse)
            }
            .padding(12)
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

// MARK: - Recording

struct RecordingView: View {
    @ObservedObject var state: AppState
    @ObservedObject var camera: CameraManager
    @State private var elapsed: Int = 0
    @State private var timer: Timer?
    @State private var isStopping = false

    private var formattedDuration: String {
        let m = elapsed / 60, s = elapsed % 60
        return String(format: "%01d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if camera.isSetup {
                CameraPreview(session: camera.session).ignoresSafeArea()
            }
            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear, Color.black.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack(spacing: 8) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("REC").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    Text(formattedDuration).font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                Text(state.text.recordingText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, 6)

                Text(camera.liveTranscript.isEmpty ? "Listening…" : camera.liveTranscript)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut(duration: 0.15), value: camera.liveTranscript)

                Spacer().frame(height: 40)

                Button {
                    stopAndSend()
                } label: {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 84, height: 84)
                        if isStopping {
                            ProgressView().tint(.appPrimary)
                        } else {
                            Image(systemName: "stop.fill").font(.system(size: 28)).foregroundColor(.red)
                        }
                    }
                }
                .disabled(isStopping)

                Text(isStopping ? "Processing…" : state.text.stopSendButton)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 10)
                    .padding(.bottom, 40)
            }
        }
        .onAppear { startRecordingFlow() }
        .onDisappear { timer?.invalidate(); timer = nil }
    }

    private func startRecordingFlow() {
        camera.startRecording(
            maxDuration: state.videoMaxDuration,
            transcriptionLocale: Locale(identifier: state.currentLanguage.speechLocaleIdentifier)
        )
        elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
            if elapsed >= state.videoMaxDuration {
                stopAndSend()
            }
        }
    }

    private func stopAndSend() {
        guard !isStopping else { return }
        isStopping = true
        timer?.invalidate()
        timer = nil
        camera.stopRecording { url in
            if let url = url {
                let newId = (state.historyItems.map { $0.id }.max() ?? 0) + 1
                let timeString = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
                let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
                state.historyItems.insert(HistoryItem(
                    id: newId,
                    type: "video",
                    imageURL: camera.lastCapturedVideoThumbnailURL?.absoluteString ?? url.absoluteString,
                    desc: "Video recording",
                    time: timeString,
                    date: dateString,
                    deleted: false,
                    previewURL: camera.lastCapturedVideoThumbnailURL?.absoluteString,
                    videoURL: url.absoluteString
                ), at: 0)
                state.stopRecordingAndSend()
            } else {
                isStopping = false
                state.isRecording = false
                state.screen = .home
            }
        }
    }
}

// MARK: - Menu

struct MenuView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { state.screen = .home } label: {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundColor(.appPrimary)
                }
                Spacer()
                Text("Menu").font(.system(size: 17, weight: .bold))
                Spacer()
                Color.clear.frame(width: 20, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.appPrimary.opacity(0.15)).frame(width: 48, height: 48)
                                Text(String(state.userEmail.first ?? "U").uppercased())
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.appPrimary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(state.text.accountTitle).font(.system(size: 15, weight: .bold))
                                Text(state.userEmail.isEmpty ? "—" : state.userEmail)
                                    .font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        HStack {
                            Text(state.text.cloudStorage).font(.system(size: 12)).foregroundColor(.secondary)
                            Spacer()
                            Text("128 MB").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color.secondarySystemBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)

                    VStack(spacing: 0) {
                        MenuRow(icon: "house", title: state.text.menuHome) { state.screen = .home }
                        Divider().padding(.leading, 52)
                        MenuRow(icon: "clock", title: state.text.menuHistory) { state.screen = .history }
                        Divider().padding(.leading, 52)
                        MenuRow(icon: "gearshape", title: state.text.menuSettings) { state.screen = .videoSettings }
                        Divider().padding(.leading, 52)
                        MenuRow(icon: "accessibility", title: "Accessibility") { state.screen = .accessibility }
                        Divider().padding(.leading, 52)
                        MenuRow(icon: "bell", title: "Notifications") { state.screen = .notifications }
                        Divider().padding(.leading, 52)
                        MenuRow(icon: "info.circle", title: "About") { state.screen = .about }
                    }
                    .background(Color.secondarySystemBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)

                    Button {
                        state.isLoggedIn = false
                        state.userEmail = ""
                        state.screen = .login
                    } label: {
                        Text(state.text.signOut)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Color.secondarySystemBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

// MARK: - Settings Screens

struct AccessibilityView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            DetailHeader(title: "Accessibility") { state.screen = .menu }
            Divider()
            Form {
                Section("Text") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text(String(format: "%.0f%%", state.fontSizeMultiplier * 100)).foregroundColor(.secondary)
                        }
                        Slider(value: $state.fontSizeMultiplier, in: 0.8...1.6, step: 0.1)
                    }
                    Toggle("High Contrast", isOn: $state.highContrast)
                }
                Section("Voice") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Speech Speed")
                            Spacer()
                            Text(String(format: "%.1fx", state.voiceSpeed)).foregroundColor(.secondary)
                        }
                        Slider(value: $state.voiceSpeed, in: 0.5...2.0, step: 0.1)
                    }
                }
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

struct NotificationsView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            DetailHeader(title: "Notifications") { state.screen = .menu }
            Divider()
            Form {
                Toggle("Enable Notifications", isOn: $state.notificationsEnabled)
                if state.notificationsEnabled {
                    Text("You'll be notified when a scan or video analysis finishes.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

struct AboutView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            DetailHeader(title: "About") { state.screen = .menu }
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.appPrimary.opacity(0.15)).frame(width: 72, height: 72)
                        Image(systemName: "sparkles").font(.system(size: 32)).foregroundColor(.appPrimary)
                    }
                    .padding(.top, 24)
                    Text("Visual AI").font(.system(size: 20, weight: .bold))
                    Text("Version 1.0").font(.system(size: 13)).foregroundColor(.secondary)
                    Text("Your eyes powered by AI. Point your camera at anything to get an instant description, or record a video and ask follow-up questions — all powered entirely on-device.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

struct VideoSettingsView: View {
    @ObservedObject var state: AppState
    @ObservedObject var camera: CameraManager
    private let qualities = ["720p", "1080p", "4K"]
    private let durations = [30, 60, 120]

    var body: some View {
        VStack(spacing: 0) {
            DetailHeader(title: state.text.menuSettings) { state.screen = .menu }
            Divider()
            Form {
                Section("Video Quality") {
                    Picker("Quality", selection: $state.videoQuality) {
                        ForEach(qualities, id: \.self) { q in
                            Text(q).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: state.videoQuality) { _, newValue in
                        camera.setVideoQuality(newValue)
                    }
                }
                Section("Max Recording Length") {
                    Picker("Duration", selection: $state.videoMaxDuration) {
                        ForEach(durations, id: \.self) { d in
                            Text("\(d)s").tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .background(Color.systemBg.ignoresSafeArea())
    }
}

// End of file
