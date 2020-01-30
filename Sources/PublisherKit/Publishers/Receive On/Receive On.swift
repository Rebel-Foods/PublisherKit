//
//  Receive On.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

extension PKPublishers {
    
    public struct ReceiveOn<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        public let scheduler: PKScheduler
        
        public init(upstream: Upstream, on scheduler: PKScheduler) {
            self.upstream = upstream
            self.scheduler = scheduler
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let receiveOnSubscriber = InternalSink(downstream: subscriber, scheduler: scheduler)
            
            subscriber.receive(subscription: receiveOnSubscriber)
            receiveOnSubscriber.request(.unlimited)
            upstream.subscribe(receiveOnSubscriber)
        }
    }
}

extension PKPublishers.ReceiveOn {
    
    // MARK: RECEIVEON SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let scheduler: PKScheduler
        
        init(downstream: Downstream, scheduler: PKScheduler) {
            self.scheduler = scheduler
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            scheduler.schedule {
                self.downstream?.receive(input: input)
            }
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            scheduler.schedule {
                self.downstream?.receive(completion: completion)
            }
        }
    }
}
