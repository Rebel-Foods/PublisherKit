//
//  Try Filter.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that republishes all elements that match a provided error-throwing closure.
    public struct TryFilter<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A error-throwing closure that indicates whether to republish an element.
        public let isIncluded: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, isIncluded: @escaping (Upstream.Output) throws -> Bool) {
            self.upstream = upstream
            self.isIncluded = isIncluded
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Subscriber = PKSubscribers.SameFailureOperatorSink<S, Upstream.Output, Failure>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber) { (output) in
                
               do {
                   let include = try self.isIncluded(output)
                   if include {
                       _ = subscriber.receive(output)
                   }
               } catch {
                   subscriber.receive(completion: .failure(error))
               }
            }
            
            let bridgeSubscriber = SameUpstreamOutputOperatorSink<Subscriber, Upstream>(downstream: upstreamSubscriber) { (completion) in
                
                let newCompletion = completion.mapError { $0 as Failure }
                upstreamSubscriber.receive(completion: newCompletion)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            bridgeSubscriber.request(.unlimited)
            upstream.receive(subscriber: bridgeSubscriber)
        }
    }
}

extension PKPublishers.TryFilter {
    
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> PKPublishers.TryFilter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) throws -> Bool = { output in
            if try self.isIncluded(output) {
                return isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.TryFilter(upstream: upstream, isIncluded: newIsIncluded)
    }
    
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> PKPublishers.TryFilter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) throws -> Bool = { output in
            if try self.isIncluded(output) {
                return try isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.TryFilter(upstream: upstream, isIncluded: newIsIncluded)
    }
}
