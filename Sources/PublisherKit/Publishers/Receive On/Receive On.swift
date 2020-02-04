//
//  Receive On.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher that publishes elements to its downstream subscriber on a specific scheduler.
    public struct ReceiveOn<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The scheduler on which elements are published.
        public let scheduler: PKScheduler
        
        public init(upstream: Upstream, on scheduler: PKScheduler) {
            self.upstream = upstream
            self.scheduler = scheduler
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let receiveOnSubscriber = InternalSink(downstream: subscriber, scheduler: scheduler)
            upstream.subscribe(receiveOnSubscriber)
        }
    }
}

extension Publishers.ReceiveOn {
    
    // MARK: RECEIVEON SINK
    private final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let scheduler: PKScheduler
        
        init(downstream: Downstream, scheduler: PKScheduler) {
            self.scheduler = scheduler
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            
            scheduler.schedule {
                _ = self.downstream?.receive(input)
            }
            
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            scheduler.schedule {
                self.downstream?.receive(completion: completion)
            }
        }
    }
}
