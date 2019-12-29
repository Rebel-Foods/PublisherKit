//
//  Filter.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    /// A publisher that republishes all elements that match a provided closure.
    public struct Filter<Upstream: NKPublisher>: NKPublisher {
        
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
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
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

extension NKPublishers.Filter {
    
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> NKPublishers.Filter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) -> Bool = { output in
            if self.isIncluded(output) {
                return isIncluded(output)
            } else {
                return false
            }
        }
        
        return NKPublishers.Filter(upstream: upstream, isIncluded: newIsIncluded)
    }
    
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> NKPublishers.TryFilter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) throws -> Bool = { output in
            if self.isIncluded(output) {
                return try isIncluded(output)
            } else {
                return false
            }
        }
        
        return NKPublishers.TryFilter(upstream: upstream, isIncluded: newIsIncluded)
    }
}