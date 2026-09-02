import AVFoundation
import Speech

@MainActor
@Observable
final class SpeechTranscriber {
    private let audioEngine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var hasInstalledTap = false

    var isRecording = false
    var isStarting = false
    var errorMessage: String?

    func toggle(onTranscript: @escaping (String) -> Void) async {
        if isRecording {
            stop()
            return
        }
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        errorMessage = nil
        do {
            try await start(onTranscript: onTranscript)
        } catch {
            errorMessage = error.localizedDescription
            stop()
        }
    }

    private func start(onTranscript: @escaping (String) -> Void) async throws {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speechGranted else { throw SpeechError.permissionDenied }
        guard await AVAudioApplication.requestRecordPermission() else { throw SpeechError.permissionDenied }
        guard let recognizer = SFSpeechRecognizer(), recognizer.supportsOnDeviceRecognition else {
            throw SpeechError.onDeviceUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            request.append(buffer)
        }
        hasInstalledTap = true
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result { onTranscript(result.bestTranscription.formattedString) }
                if error != nil || result?.isFinal == true { self?.stop() }
            }
        }
    }

    func stop() {
        if audioEngine.isRunning { audioEngine.stop() }
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
    }
}

private enum SpeechError: LocalizedError {
    case permissionDenied
    case onDeviceUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Microphone and speech access are required for dictation."
        case .onDeviceUnavailable: "On-device dictation is unavailable for this language or device."
        }
    }
}
