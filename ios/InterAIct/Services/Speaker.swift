import AVFoundation
import Observation

/// On-device text-to-speech for prompts, choices, and feedback.
@Observable
final class Speaker {
    private let synthesizer = AVSpeechSynthesizer()
    /// When false, only explicit taps on a speaker button read text aloud.
    @ObservationIgnored var autoReadEnabled = true
    @ObservationIgnored var rate: Float = Float(AppSettings.defaultSpeechRate)

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    func speak(_ text: String) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.1
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
            ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func autoSpeak(_ text: String) {
        guard autoReadEnabled else { return }
        speak(text)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
