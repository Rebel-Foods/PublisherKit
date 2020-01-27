//
//  Try All Satisfy.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKPublishers {

    /// A publisher that publishes a single Boolean value that indicates whether all received elements pass a given error-throwing predicate.
    public struct TryAllSatisfy<Upstream: PKPublisher>: PKPublisher {

        public typealias Output = Bool

        public typealias Failure = Error

        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream

        /// A closure that evaluates each received element.
        ///
        /// Return `true` to continue, or `false` to cancel the upstream and complete. The closure may throw, in which case the publisher cancels the upstream publisher and fails with the thrown error.
        public let predicate: (Upstream.Output) throws -> Bool

        public init(upstream: Upstream, predicate: @escaping (Upstream.Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Subscriber = PKSubscribers.SameFailureOperatorSink<S, Upstream.Output, Failure>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber) { (output) in
                
               do {
                    let satisfied = try self.predicate(output)
                    _ = subscriber.receive(satisfied)
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
