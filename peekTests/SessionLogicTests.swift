import Foundation
import CoreGraphics
import Testing
import UIKit
@testable import peek

struct ModifierLogicTests {
    @Test func toggleHoldsThenReleases() {
        var logic = ModifierLogic()
        #expect(logic.toggle(.command) == [.keyDown(KeySym.superLeft)])
        #expect(logic.held == [.command])
        #expect(logic.toggle(.command) == [.keyUp(KeySym.superLeft)])
        #expect(logic.held.isEmpty)
        logic.keymap = .appleRemoteDesktop
        #expect(logic.toggle(.command) == [.keyDown(KeySym.hyperLeft)])
    }

    @Test func wrapReleasesHeldModifiersAfterPress() {
        var logic = ModifierLogic()
        _ = logic.toggle(.shift)
        _ = logic.toggle(.command)
        let events = logic.wrap(ModifierLogic.press(KeySym.tab))
        #expect(events == [.keyDown(KeySym.tab), .keyUp(KeySym.tab), .keyUp(KeySym.superLeft), .keyUp(KeySym.shiftLeft)])
        #expect(logic.held.isEmpty)
        #expect(logic.wrap([.text("a")]) == [.text("a")])
    }
}

struct ScreenGeometryTests {
    let screen = CGSize(width: 1000, height: 500)
    let view = CGSize(width: 400, height: 400)

    @Test func fitScaleUsesTheTighterAxis() {
        #expect(ScreenGeometry.fitScale(screen: screen, in: view) == 0.4)
        #expect(ScreenGeometry.fitScale(screen: .zero, in: view) == 1)
    }

    @Test func fitIsCentered() {
        let t = ScreenGeometry.transform(screen: screen, view: view, zoom: 1, pan: .zero)
        #expect(t.scale == 0.4)
        #expect(t.offset == CGPoint(x: 0, y: 100))
    }

    @Test func panIsClampedWhenZoomed() {
        let t = ScreenGeometry.transform(screen: screen, view: view, zoom: 2, pan: CGSize(width: 999, height: -999))
        #expect(t.scale == 0.8)
        #expect(t.offset.x == 0, "can't pan past the left edge")
        #expect(t.offset.y == 0, "image is exactly view-height tall, so it stays centered")
        let left = ScreenGeometry.transform(screen: screen, view: view, zoom: 2, pan: CGSize(width: -999, height: 0))
        #expect(left.offset.x == view.width - 800)
    }

    @Test func framebufferPointMapsAndClamps() {
        let t = ScreenTransform(scale: 0.5, offset: CGPoint(x: 10, y: 20))
        #expect(ScreenGeometry.framebufferPoint(CGPoint(x: 10, y: 20), transform: t, screen: screen) == (0, 0))
        #expect(ScreenGeometry.framebufferPoint(CGPoint(x: 110, y: 70), transform: t, screen: screen) == (200, 100))
        #expect(ScreenGeometry.framebufferPoint(CGPoint(x: -50, y: 9999), transform: t, screen: screen) == (0, 499))
        #expect(ScreenGeometry.framebufferPoint(.zero, transform: ScreenTransform(scale: 0, offset: .zero), screen: screen) == (0, 0))
    }
}

struct ScrollAccumulatorTests {
    @Test func emitsWholeStepsAndKeepsRemainder() {
        var scroll = ScrollAccumulator(pointsPerStep: 10)
        #expect(scroll.add(CGSize(width: 0, height: -15)) == (0, 1))
        #expect(scroll.add(CGSize(width: 0, height: -5)) == (0, 1))
        #expect(scroll.add(CGSize(width: 25, height: 0)) == (-2, 0))
        scroll.reset()
        #expect(scroll.add(CGSize(width: 4, height: 4)) == (0, 0))
    }
}

struct GestureLogicTests {
    let transform = ScreenTransform(scale: 1, offset: .zero)
    let screen = CGSize(width: 100, height: 100)

    private func inputs(_ gesture: ScreenGesture) -> [RemoteInput] {
        GestureLogic.inputs(for: gesture, transform: transform, screen: screen)
    }

    @Test func clicks() {
        #expect(inputs(.tap(CGPoint(x: 5, y: 6))) == [.move(x: 5, y: 6), .buttonDown(.left, x: 5, y: 6), .buttonUp(.left, x: 5, y: 6)])
        #expect(inputs(.secondaryTap(CGPoint(x: 1, y: 1))).contains(.buttonDown(.right, x: 1, y: 1)))
        #expect(inputs(.doubleTap(.zero)).count == 6)
    }

    @Test func dragAndScroll() {
        #expect(inputs(.dragBegan(CGPoint(x: 2, y: 2))) == [.move(x: 2, y: 2), .buttonDown(.left, x: 2, y: 2)])
        #expect(inputs(.dragMoved(CGPoint(x: 3, y: 3))) == [.move(x: 3, y: 3)])
        #expect(inputs(.dragEnded(CGPoint(x: 4, y: 4))) == [.buttonUp(.left, x: 4, y: 4)])
        #expect(inputs(.scroll(steps: .zero, at: .zero)).isEmpty)
        #expect(inputs(.scroll(steps: CGSize(width: 1, height: -2), at: CGPoint(x: 9, y: 9))) == [.scroll(dx: 1, dy: -2, x: 9, y: 9)])
        #expect(inputs(.hover(CGPoint(x: 7, y: 8))) == [.move(x: 7, y: 8)])
        #expect(inputs(.swipe(.left)) == [.keyDown(KeySym.controlLeft), .keyDown(KeySym.right), .keyUp(KeySym.right), .keyUp(KeySym.controlLeft)])
        #expect(inputs(.swipe(.up)).contains(.keyDown(KeySym.up)))
        #expect(SwipeDirection.right.keysym == KeySym.left)
        #expect(SwipeDirection.down.keysym == KeySym.down)
        #expect(SwipeDirection.allCases.map(\.name) == ["left", "right", "up", "down"])
    }
}

struct HardwareKeyMapTests {
    @Test func specialKeysAndChords() {
        #expect(HardwareKeyMap.action(keyCode: .keyboardEscape, modifiers: [], characters: "") == .key(.escape))
        #expect(HardwareKeyMap.action(keyCode: .keyboardLeftArrow, modifiers: [], characters: "") == .key(.leftArrow))
        #expect(HardwareKeyMap.action(keyCode: .keyboardReturnOrEnter, modifiers: [], characters: "\r") == .key(.return))
        #expect(HardwareKeyMap.action(keyCode: .keyboardC, modifiers: [.command], characters: "c") == .chord([.command], "c"))
        #expect(HardwareKeyMap.action(keyCode: .keyboardZ, modifiers: [.command, .shift], characters: "z") == .chord([.command, .shift], "z"))
        #expect(HardwareKeyMap.action(keyCode: .keyboardTab, modifiers: [.alternate], characters: "\t") == .chord([.option], "\t"))
        #expect(HardwareKeyMap.action(keyCode: .keyboardA, modifiers: [], characters: "a") == nil, "plain typing goes through insertText")
        #expect(HardwareKeyMap.action(keyCode: .keyboardA, modifiers: [.shift], characters: "a") == nil, "shift alone is just typing")
        #expect(HardwareKeyMap.action(keyCode: .keyboardA, modifiers: [.control], characters: "") == nil)
        #expect(HardwareKeyMap.modifiers(from: [.command, .alternate, .control, .shift]) == [.command, .option, .control, .shift])
    }
}

struct FrameThrottleTests {
    @Test func coalescesUntilFlush() {
        var scheduled: [@MainActor () -> Void] = []
        let throttle = FrameThrottle(interval: 1) { _, work in scheduled.append(work) }
        var flushes = 0
        throttle.onFlush = { flushes += 1 }
        throttle.markDirty()
        throttle.markDirty()
        #expect(scheduled.count == 1)
        #expect(throttle.isPending)
        scheduled[0]()
        #expect(flushes == 1)
        #expect(!throttle.isPending)
        throttle.markDirty()
        #expect(scheduled.count == 2)
    }

    @Test func defaultSchedulerFires() async throws {
        let throttle = FrameThrottle(interval: 0.01)
        var flushed = false
        throttle.onFlush = { flushed = true }
        throttle.markDirty()
        try await Task.sleep(for: .milliseconds(200))
        #expect(flushed)
    }
}

struct ReconnectPolicyTests {
    @Test func reconnectsOnlyAfterDroppedConnections() {
        #expect(ReconnectPolicy.shouldReconnect(after: .disconnected(.connection("dropped")), userDisconnected: false))
        #expect(!ReconnectPolicy.shouldReconnect(after: .disconnected(.authentication("bad")), userDisconnected: false))
        #expect(!ReconnectPolicy.shouldReconnect(after: .disconnected(nil), userDisconnected: false))
        #expect(!ReconnectPolicy.shouldReconnect(after: .connected, userDisconnected: false))
        #expect(!ReconnectPolicy.shouldReconnect(after: .disconnected(.connection("x")), userDisconnected: true))
    }

    @Test func refreshesAfterALongBackgroundStay() {
        let now = Date()
        let longAgo = now.addingTimeInterval(-60)
        #expect(ReconnectPolicy.shouldRefresh(state: .connected, backgroundedAt: longAgo, now: now))
        #expect(!ReconnectPolicy.shouldRefresh(state: .connected, backgroundedAt: now.addingTimeInterval(-5), now: now))
        #expect(!ReconnectPolicy.shouldRefresh(state: .connected, backgroundedAt: nil, now: now))
        #expect(!ReconnectPolicy.shouldRefresh(state: .disconnected(nil), backgroundedAt: longAgo, now: now))
    }
}
