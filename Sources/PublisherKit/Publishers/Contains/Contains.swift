//
//  Contains.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

import Foundation

extension Publishers {
    
    /// A publisher that emits a Boolean value when a specified element is received from its upstream publisher.
    public struct Contains<Upstream: Publisher>: Publisher where Upstream.Output: Equatable {
        
        public typealias Output = Bool
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The element to scan for in the upstream publisher.
        public let output: Upstream.Output
        
        public init(upstream: Upstream, output: Upstream.Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let containsSubscriber = InternalSink(downstream: subscriber, output: output)
            upstream.subscribe(containsSubscriber)
        }
    }
}

extension Publishers.Contains {
    
    // MARK: CONTAINS SINK
    private final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        let output: Upstream.Output
        
        init(downstream: Downstream, output: Upstream.Output) {
            self.output = output
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isOver else { return .none }
            _ = downstream?.receive(input == output)
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isOver else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
