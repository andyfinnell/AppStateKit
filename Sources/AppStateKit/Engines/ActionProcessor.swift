import Foundation
import BaseKit

typealias Block = @Sendable () async -> Void

@MainActor
final class ActionProcessor<State, Action: Sendable, Output> {
    private var actions = [Action]()
    private var subscriptions = [SubscriptionID: Task<Void, Never>]()
    private var isProcessing = false
    private let reduce: (inout State, Action, AnySideEffects<Action, Output>) -> Void
    private let dependencies: DependencyScope
    private let continuation: AsyncStream<[Block]>.Continuation
    private let executionTask: Task<Void, Never>
    
    init(
        dependencies: DependencyScope,
        reduce: @escaping (inout State, Action, AnySideEffects<Action, Output>) -> Void
    ) {
        self.dependencies = dependencies
        self.reduce = reduce
        
        let (stream, continuation) = AsyncStream.makeStream(of: [Block].self)
        self.continuation = continuation
        
        executionTask = Task.detached { [stream] in
            do {
                for await blocks in stream {
                    await executeBlocks(blocks)
                    try Task.checkCancellation()
                }
                try Task.checkCancellation()
            } catch {
                // something cancelled
            }
        }
    }
    
    deinit {
        continuation.finish()
        executionTask.cancel()
    }
        
    var internals: Internals {
        Internals(dependencyScope: dependencies)
    }
    
    func process(
        _ action: Action,
        on getState: () -> State,
        _ setState: (State) -> Void,
        using sendThunk: @MainActor @Sendable @escaping (Action) -> Void,
        _ signalThunk: @MainActor @escaping (Output) -> Void,
        detachedSender: DetachedSender
    ) {
        actions.append(action)
        processNextActions(
            on: getState,
            setState,
            using: sendThunk,
            signalThunk,
            detachedSender: detachedSender
        )
    }
}

private extension ActionProcessor {
    func processNextActions(
        on getState: () -> State,
        _ setState: (State) -> Void,
        using sendThunk: @MainActor @Sendable @escaping (Action) -> Void,
        _ signalThunk: @MainActor @escaping (Output) -> Void,
        detachedSender: DetachedSender
    ) {
        // Make sure we're not recursing on ourselves
        guard !isProcessing else {
            return
        }
        
        isProcessing = true
        defer {
            isProcessing = false
        }
        
        while let nextAction = actions.first {
            actions.removeFirst()
            
            processNextAction(
                nextAction,
                on: getState, setState,
                using: sendThunk, signalThunk,
                detachedSender: detachedSender
            )
        }
    }
    
    func processNextAction(
        _ nextAction: Action,
        on getState: () -> State,
        _ setState: (State) -> Void,
        using sendThunk: @MainActor @Sendable @escaping (Action) -> Void,
        _ signalThunk: @MainActor @escaping (Output) -> Void,
        detachedSender: DetachedSender
    ) {
        let sideEffects = SideEffectsContainer<Action>(dependencyScope: dependencies)
        var state = getState()
        reduce(&state, nextAction, sideEffects.eraseToAnySideEffects(signal: signalThunk))
        setState(state)
        
        sideEffects.sendDetachedActions(with: detachedSender)
        
        // Perform immediate effects
        sideEffects.applyImmediateEffects(using: sendThunk)
        
        // Perform effects
        let blocks = sideEffects.apply(using: sendThunk)
        if !blocks.isEmpty {
            continuation.yield(blocks)
        }
        
        // Start subscriptions
        sideEffects.startSubscriptions(
            using: sendThunk,
            attachingWith: { task, subscriptionID in
                self.subscriptions[subscriptionID] = task
            },
            onFinish: { @MainActor [weak self] subscriptionID in
                guard let self else {
                    return
                }
                self.subscriptions.removeValue(forKey: subscriptionID)
            })
        
        // Cancel any subscriptions
        for subscriptionID in sideEffects.cancellations {
            guard let task = subscriptions[subscriptionID] else {
                return
            }
            task.cancel()
            subscriptions.removeValue(forKey: subscriptionID)
        }
    }
}

private nonisolated func executeBlocks(_ blocks: [Block]) async {
    await withDiscardingTaskGroup(returning: Void.self) { taskGroup in
        for block in blocks {
            taskGroup.addTask {
                await block()
            }
        }
    }
}
