public enum MousePhase { case down, up, drag }
public enum NavigationDecision: Equatable { case pass, swallow, back, forward }

/// Keep each intercepted press/release paired, even if focus changes mid-click.
public struct NavigationRouter {
    private var capturedButtons: Set<Int64> = []

    public init() {}

    public mutating func handle(button: Int64, phase: MousePhase,
                                finderActive: Bool, enabled: Bool,
                                reversed: Bool) -> NavigationDecision {
        switch phase {
        case .up:
            return capturedButtons.remove(button) != nil ? .swallow : .pass
        case .drag:
            return capturedButtons.contains(button) ? .swallow : .pass
        case .down:
            if capturedButtons.contains(button) { return .swallow }
            guard enabled, finderActive, button == 3 || button == 4 else { return .pass }
            capturedButtons.insert(button)
            return (button == 3) != reversed ? .back : .forward
        }
    }
}
