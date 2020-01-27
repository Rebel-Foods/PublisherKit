//
//  Count.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {

    /// A publisher that publishes the number of elements received from the upstream publisher.
    public struct Count<Upstream: PKPublisher>: PKPublisher {

        public typealias Output = Int

        public typealias Failure = Upstream.Failure

        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream

        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            var counter = 0
            
            let upstreamPublisher = UpstreamOperatorSink<S, Upstream>(downstream: subscriber, receiveCompletion: { (completion) in
                
                switch completion {
                case .finished:
                    _ = subscriber.receive(counter)
                    subscriber.receive(completion: .finished)
                    
                case .failure(let error):
                    subscriber.receive(completion: .failure(error))
                }
                
            }) { (_) in
                counter += 1
            }
            
            subscriber.receive(subscription: upstreamPublisher)
            upstreamPublisher.request(.unlimited)
            upstream.subscribe(upstreamPublisher)
        }
    }
}
