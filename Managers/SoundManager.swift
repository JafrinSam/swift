import SwiftUI
import AVFoundation
import MediaPlayer

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    // Ambient Players
    private var ambientPlayers: [String: AVAudioPlayer] = [:]
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    @Published var activeAmbient: Set<String> = []
    @Published var nowPlayingSong: String? = nil
    
    // 1. Toggle Ambient Sound
    func toggleAmbient(named soundName: String) {
        if activeAmbient.contains(soundName) {
            ambientPlayers[soundName]?.stop()
            activeAmbient.remove(soundName)
        } else {
            playAmbient(named: soundName)
            activeAmbient.insert(soundName)
        }
    }
    
    private func playAmbient(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 
            player.volume = 0.5
            player.play()
            ambientPlayers[soundName] = player
        } catch { print("Error: \(error)") }
    }
    
    // 2. Play Local Music (System Picker)
    func playLocalMusic(item: MPMediaItemCollection) {
        musicPlayer.setQueue(with: item)
        musicPlayer.play()
        nowPlayingSong = item.items.first?.title
    }
    
    func stopAll() {
        ambientPlayers.values.forEach { $0.stop() }
        activeAmbient.removeAll()
        musicPlayer.stop()
    }
}