//
//  Filter.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that republishes all elements that match a provided closure.
    public struct Filter<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that indicates whether to republish an element.
        public let isIncluded: (Upstream.Output) -> Bool
        
        public init(upstream: Upstream, isIncluded: @escaping (Upstream.Output) -> Bool) {
            self.upstream = upstream
            self.isIncluded = isIncluded
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                
                let include = self.isIncluded(output)
                if include {
                    _ = subscriber.receive(output)
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}

extension PKPublishers.Filter {
    
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> PKPublishers.Filter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) -> Bool = { output in
            if self.isIncluded(output) {
                return isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.Filter(upstream: upstream, isIncluded: newIsIncluded)
    }
    
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> PKPublishers.TryFilter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) throws -> Bool = { output in
            if self.isIncluded(output) {
                return try isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.TryFilter(upstream: upstream, isIncluded: newIsIncluded)
    }
}
