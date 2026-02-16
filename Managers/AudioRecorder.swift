import Foundation
import AVFoundation
import Observation

@Observable
class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    // MARK: - Observable State
    var isRecording = false
    var recordingURL: URL?
    var amplitude: Float = 0.0 // For real-time waveform visualization
    
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    
    override init() {
        super.init()
    }
    
    // MARK: - Session Management
    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try session.setActive(true)
    }
    
    // MARK: - Controls
    func toggleRecording() -> URL? {
        if isRecording {
            return stopRecording()
        } else {
            requestPermissions { [weak self] granted in
                guard granted else { return }
                self?.startRecording()
            }
            return nil
        }
    }
    
    private func startRecording() {
        let fileName = "ForgeNote_\(Int(Date().timeIntervalSince1970)).m4a"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100, // Higher quality for the judges
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            try configureSession()
            recorder = try AVAudioRecorder(url: path, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true // Required for the waveform
            recorder?.record()
            
            isRecording = true
            recordingURL = path
            startMonitoringAmplitude()
        } catch {
            print("ForgeFlow Error: Initialization failed - \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        recorder?.stop()
        timer?.invalidate()
        isRecording = false
        amplitude = 0
        return recordingURL
    }
    
    // MARK: - Visual Feedback Engine
    private func startMonitoringAmplitude() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            
            // Convert decibels to a 0.0 - 1.0 range for the UI
            let db = recorder.averagePower(forChannel: 0)
            let level = max(0.2, CGFloat(db + 60) / 60)
            self.amplitude = Float(level)
        }
    }
}