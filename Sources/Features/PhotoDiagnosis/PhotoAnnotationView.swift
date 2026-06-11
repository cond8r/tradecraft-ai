import SwiftUI

struct PhotoAnnotationView: View {
    let baseImage: UIImage
    let onDone: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var strokes: [AnnotationStroke] = []
    @State private var currentPoints: [CGPoint] = []
    @State private var strokeColor: Color = .red
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: baseImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                    Canvas { context, _ in
                        for stroke in strokes { draw(&context, stroke.points, stroke.color) }
                        if !currentPoints.isEmpty { draw(&context, currentPoints, strokeColor) }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { currentPoints.append($0.location) }
                            .onEnded { _ in
                                if !currentPoints.isEmpty {
                                    strokes.append(AnnotationStroke(points: currentPoints, color: strokeColor))
                                    currentPoints = []
                                }
                            }
                    )
                }
                .onAppear { canvasSize = geo.size }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Annotate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 14) {
                        ForEach([Color.red, Color.yellow, Color.white], id: \.self) { c in
                            Circle()
                                .fill(c)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle().stroke(strokeColor == c ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture { strokeColor = c }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            if !strokes.isEmpty { strokes.removeLast() }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(strokes.isEmpty)

                        Button("Done") {
                            onDone(renderAnnotated())
                            dismiss()
                        }
                        .bold()
                    }
                }
            }
        }
    }

    private func draw(_ context: inout GraphicsContext, _ points: [CGPoint], _ color: Color) {
        guard !points.isEmpty else { return }
        if points.count == 1 {
            let pt = points[0]
            context.fill(
                Path(ellipseIn: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)),
                with: .color(color)
            )
            return
        }
        var path = Path()
        path.move(to: points[0])
        for pt in points.dropFirst() { path.addLine(to: pt) }
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
    }

    @MainActor
    private func renderAnnotated() -> UIImage {
        guard canvasSize != .zero else { return baseImage }
        let imgSize = baseImage.size
        let scale = min(canvasSize.width / imgSize.width, canvasSize.height / imgSize.height)
        let scaledW = imgSize.width * scale
        let scaledH = imgSize.height * scale
        let ox = (canvasSize.width - scaledW) / 2
        let oy = (canvasSize.height - scaledH) / 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: scaledW, height: scaledH))
        return renderer.image { _ in
            baseImage.draw(in: CGRect(x: 0, y: 0, width: scaledW, height: scaledH))
            for stroke in strokes {
                guard !stroke.points.isEmpty else { continue }
                let pts = stroke.points.map { CGPoint(x: $0.x - ox, y: $0.y - oy) }
                UIColor(stroke.color).setStroke()
                let path = UIBezierPath()
                path.move(to: pts[0])
                for pt in pts.dropFirst() { path.addLine(to: pt) }
                path.lineWidth = 6
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }
        }
    }
}

private struct AnnotationStroke {
    var points: [CGPoint]
    var color: Color
}
