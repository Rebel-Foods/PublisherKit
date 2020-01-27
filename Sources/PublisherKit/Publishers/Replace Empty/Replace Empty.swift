//
//  Replace Empty.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that replaces an empty stream with a provided element.
    struct ReplaceEmpty<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        public let output: Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream, output: Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            var outputReceived = false
            
            let upstreamSubscriber = UpstreamOperatorSink<S, Upstream>(downstream: subscriber, receiveCompletion: { (completion) in
                
                switch completion {
                case .finished:
                    if !outputReceived {
                        _ = subscriber.receive(self.output)
                        subscriber.receive(completion: .finished)
                    }
                    
                case .failure(let error):
                    subscriber.receive(completion: .failure(error))
                }
                
            }) { (output) in
                outputReceived = true
                _ = subscriber.receive(output)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
