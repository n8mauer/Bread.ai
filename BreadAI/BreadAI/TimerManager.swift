import Foundation
import SwiftUI
import UserNotifications

// MARK: - Timer Preset Model
struct TimerPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let icon: String
    let color: Color
}

// MARK: - Timer Manager
class TimerManager: ObservableObject {
    static let shared = TimerManager()

    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var timerName = ""

    private var timer: Timer?
    private var endTime: Date?
    private var initialDuration: TimeInterval = 0

    // Preset timers
    static let presets: [TimerPreset] = [
        TimerPreset(
            name: "Proofing",
            duration: 3600, // 60 minutes
            icon: "clock.fill",
            color: .blue
        ),
        TimerPreset(
            name: "Bulk Ferment",
            duration: 14400, // 4 hours
            icon: "clock.arrow.circlepath",
            color: .orange
        ),
        TimerPreset(
            name: "Bake",
            duration: 2700, // 45 minutes
            icon: "flame.fill",
            color: .red
        ),
        TimerPreset(
            name: "Quick Rest",
            duration: 1200, // 20 minutes
            icon: "moon.fill",
            color: .purple
        ),
        TimerPreset(
            name: "Bench Rest",
            duration: 1800, // 30 minutes
            icon: "bed.double.fill",
            color: .green
        )
    ]

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Timer Control Methods

    func start(duration: TimeInterval, name: String) {
        stop() // Stop any existing timer

        self.timeRemaining = duration
        self.initialDuration = duration
        self.timerName = name
        self.endTime = Date().addingTimeInterval(duration)
        self.isRunning = true

        scheduleNotification(for: duration, name: name)
        startTimer()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        cancelNotification()
    }

    func resume() {
        guard !isRunning, timeRemaining > 0 else { return }
        isRunning = true
        endTime = Date().addingTimeInterval(timeRemaining)
        scheduleNotification(for: timeRemaining, name: timerName)
        startTimer()
    }

    func reset() {
        stop()
        timeRemaining = 0
        timerName = ""
        initialDuration = 0
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        cancelNotification()
    }

    // MARK: - Progress Calculation

    var progress: Double {
        guard initialDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / initialDuration)
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let endTime = self.endTime else { return }

            let remaining = endTime.timeIntervalSinceNow
            if remaining <= 0 {
                self.timerComplete()
            } else {
                self.timeRemaining = remaining
            }
        }
    }

    private func timerComplete() {
        stop()
        timeRemaining = 0

        // Play haptic feedback
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    // MARK: - Notification Methods

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleNotification(for duration: TimeInterval, name: String) {
        cancelNotification()

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = "\(name) timer has finished"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(identifier: "BreadTimerNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["BreadTimerNotification"])
    }
}

// MARK: - Helper Extensions

extension TimeInterval {
    var formattedTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var shortFormattedTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
