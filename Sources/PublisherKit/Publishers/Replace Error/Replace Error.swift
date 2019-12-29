//
//  Replace Error.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension NKPublishers {
    
    /// A publisher that replaces any errors in the stream with a provided element.
    struct ReplaceError<Upstream: NKPublisher>: NKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Never
        
        /// The element with which to replace errors from the upstream publisher.
        public let output: Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream, output: Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamOutputOperatorSink<S, Upstream>(downstream: subscriber) { (completion) in
                
                if let error = completion.getError() {
                    #if DEBUG
                    Logger.default.log(error: error)
                    #endif
                    _ = subscriber.receive(self.output)
                }
                subscriber.receive(completion: .finished)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
