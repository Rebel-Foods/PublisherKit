//
//  Timer.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

import Foundation

extension Timer {
    
    /// Returns a publisher that repeatedly emits the current date on the given interval.
    ///
    /// - Parameters:
    ///   - interval: The time interval on which to publish events. For example, a value of `0.5` publishes an event approximately every half-second.
    ///   - tolerance: The allowed timing variance when emitting events. Defaults to `nil`, which allows any variance.
    ///   - runLoop: The run loop on which the timer runs.
    ///   - mode: The run loop mode in which to run the timer.
    ///   - options: Scheduler options passed to the timer. Defaults to `nil`.
    /// - Returns: A publisher that repeatedly emits the current date on the given interval.
    public static func pkPublish(every interval: TimeInterval, tolerance: TimeInterval? = nil, on runLoop: RunLoop, in mode: RunLoop.Mode, options: RunLoop.PKSchedulerOptions? = nil) -> Timer.TimerPKPublisher {
        Timer.TimerPKPublisher(interval: interval, tolerance: tolerance, runLoop: runLoop, mode: mode, options: options)
    }
    
    /// A publisher that repeatedly emits the current date on a given interval.
    final public class TimerPKPublisher: ConnectablePublisher {
        
        public typealias Output = Date
        
        public typealias Failure = Never
        
        final public let interval: TimeInterval
        
        final public let tolerance: TimeInterval?
        
        final public let runLoop: RunLoop
        
        final public let mode: RunLoop.Mode
        
        final public let options: RunLoop.PKSchedulerOptions?
        
        private var lock = Lock()
        
        private var subscriptions: [Inner] = []
        
        private var connection: Cancellable?
        
        /// Creates a publisher that repeatedly emits the current date on the given interval.
        ///
        /// - Parameters:
        ///   - interval: The interval on which to publish events.
        ///   - tolerance: The allowed timing variance when emitting events. Defaults to `nil`, which allows any variance.
        ///   - runLoop: The run loop on which the timer runs.
        ///   - mode: The run loop mode in which to run the timer.
        ///   - options: Scheduler options passed to the timer. Defaults to `nil`.
        public init(interval: TimeInterval, tolerance: TimeInterval? = nil, runLoop: RunLoop, mode: RunLoop.Mode, options: RunLoop.PKSchedulerOptions? = nil)  {
            self.interval = interval
            self.tolerance = tolerance
            self.runLoop = runLoop
            self.mode = mode
            self.options = options
        }
        
        deinit {
            subscriptions = []
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let timerSubscription = Inner(downstream: AnySubscriber(subscriber))

            subscriber.receive(subscription: timerSubscription)
            timerSubscription.request(.unlimited)

            subscriptions.append(timerSubscription)
        }
        
        final public func connect() -> Cancellable {
            lock.lock()
            
            if let connection = connection {
                lock.unlock()
                return connection
            }
            
            lock.unlock()
            
            let timer: Timer
            if #available(OSX 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
                timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] (timer) in
                    self?.sendOutput()
                }
            } else {
                timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(scheduledAction(_:)), userInfo: nil, repeats: true)
            }
            
            if let tolerance = tolerance {
                timer.tolerance = tolerance
            }
            
            runLoop.add(timer, forMode: mode)
            
            let cancellable = AnyCancellable { timer.invalidate() }
            
            lock.lock()
            connection = cancellable
            lock.unlock()
            
            return cancellable
        }
        
        @objc private func scheduledAction(_ timer: Timer) {
            if timer.isValid {
                sendOutput()
            }
        }
        
        @inline(__always)
        private func sendOutput() {
            let date = Date()
            subscriptions.forEach { (subscription) in
                subscription.receive(input: date)
            }
        }
    }
}

extension Timer.TimerPKPublisher {
    
    // MARK: TIMER SINK
    private final class Inner: Subscriptions.Internal<AnySubscriber<Output, Failure>, Output, Failure> {
        
        override var description: String {
            "Timer"
        }
    }
}
