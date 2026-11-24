import SwiftUI
import AVFoundation
import UIKit

final class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var looper: AVPlayerLooper?
}

struct LoopingVideo: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.backgroundColor = .secondarySystemBackground
        view.playerLayer.videoGravity = .resizeAspectFill
        let player = AVQueuePlayer()
        player.isMuted = true
        view.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        view.playerLayer.player = player
        player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerUIView, coordinator: ()) {
        uiView.playerLayer.player?.pause()
        uiView.looper = nil
    }
}

/// Animated stick figure for exercises that have no video yet.
struct FigureView: View {
    typealias Pose = [String: CGPoint]

    static let lungeA: Pose = [
        "H": CGPoint(x: 101, y: 24), "S": CGPoint(x: 100, y: 40), "P": CGPoint(x: 99, y: 82),
        "E": CGPoint(x: 124, y: 57), "W": CGPoint(x: 146, y: 76), "K": CGPoint(x: 100, y: 115),
        "A": CGPoint(x: 100, y: 148), "T": CGPoint(x: 114, y: 150),
        "E2": CGPoint(x: 119, y: 57), "W2": CGPoint(x: 141, y: 76), "K2": CGPoint(x: 95, y: 115),
        "A2": CGPoint(x: 95, y: 148), "T2": CGPoint(x: 109, y: 150)
    ]
    static let lungeB: Pose = [
        "H": CGPoint(x: 98, y: 44), "S": CGPoint(x: 97, y: 60), "P": CGPoint(x: 94, y: 101),
        "E": CGPoint(x: 121, y: 72), "W": CGPoint(x: 146, y: 76), "K": CGPoint(x: 121, y: 106),
        "A": CGPoint(x: 119, y: 148), "T": CGPoint(x: 133, y: 150),
        "E2": CGPoint(x: 116, y: 72), "W2": CGPoint(x: 141, y: 76), "K2": CGPoint(x: 78, y: 135),
        "A2": CGPoint(x: 50, y: 140), "T2": CGPoint(x: 42, y: 149)
    ]

    var a: Pose = FigureView.lungeA
    var b: Pose = FigureView.lungeB

    private static func ease(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    private static func phase(_ x: Double) -> Double {
        if x < 0.15 { return 0 }
        if x < 0.45 { return ease((x - 0.15) / 0.3) }
        if x < 0.6 { return 1 }
        return 1 - ease((x - 0.6) / 0.4)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let ctx = context
                let s = min(size.width / 200, size.height / 160)
                let ox = (size.width - 200 * s) / 2
                let oy = (size.height - 160 * s) / 2
                func map(_ q: CGPoint) -> CGPoint { CGPoint(x: ox + q.x * s, y: oy + q.y * s) }

                let x = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3.2) / 3.2
                let k = CGFloat(FigureView.phase(x))
                func pt(_ key: String) -> CGPoint {
                    let p0 = a[key] ?? .zero, p1 = b[key] ?? .zero
                    return map(CGPoint(x: p0.x + (p1.x - p0.x) * k, y: p0.y + (p1.y - p0.y) * k))
                }
                func stroke(_ points: [CGPoint], _ width: CGFloat, _ color: Color) {
                    var path = Path()
                    path.addLines(points)
                    ctx.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: width * s, lineCap: .round, lineJoin: .round))
                }

                let prop = Color.gray.opacity(0.45)
                stroke([map(CGPoint(x: 0, y: 151)), map(CGPoint(x: 200, y: 151))], 2, prop)
                stroke([map(CGPoint(x: 150, y: 74)), map(CGPoint(x: 150, y: 150))], 5, prop)
                stroke([map(CGPoint(x: 150, y: 108)), map(CGPoint(x: 186, y: 108)), map(CGPoint(x: 186, y: 150))], 5, prop)

                let far = Color.figure.opacity(0.4)
                stroke(["P", "K2", "A2", "T2"].map(pt), 7, far)
                stroke(["S", "E2", "W2"].map(pt), 6, far)
                stroke(["H", "S", "P"].map(pt), 10, .figure)
                stroke(["P", "K", "A", "T"].map(pt), 7.5, .figure)
                stroke(["S", "E", "W"].map(pt), 6.5, .figure)
                let h = pt("H")
                ctx.fill(Path(ellipseIn: CGRect(x: h.x - 10 * s, y: h.y - 10 * s, width: 20 * s, height: 20 * s)),
                         with: .color(.figure))
            }
        }
        .background(Color(.secondarySystemBackground))
    }
}

struct ExerciseMedia: View {
    let exercise: Exercise
    var body: some View {
        Group {
            if let url = exercise.videoURL {
                LoopingVideo(url: url)
            } else {
                FigureView()
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .environment(\.layoutDirection, .leftToRight)
    }
}
