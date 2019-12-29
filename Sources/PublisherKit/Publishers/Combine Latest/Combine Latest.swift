//
//  Combine Latest.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    /// A publisher that receives and combines the latest elements from two publishers.
    public struct CombineLatest<A: NKPublisher, B: NKPublisher>: NKPublisher where A.Failure == B.Failure {
        
        public typealias Output = (A.Output, B.Output)
        
        public typealias Failure = A.Failure
        
        public let a: A
        
        public let b: B
        
        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Sub = CombineLatestSink<S, A.Output, B.Output, Failure>
            
            let upstreamSubscriber = Sub(downstream: subscriber)

            let aUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, A>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(a: output)
            }

            let bUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, B>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(b: output)
            }
            
            upstreamSubscriber.receive(subscription: aUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: bUpstreamSubscriber)
            
            subscriber.receive(subscription: upstreamSubscriber)
            
            upstreamSubscriber.request(.unlimited)
            aUpstreamSubscriber.request(.unlimited)
            bUpstreamSubscriber.request(.unlimited)
            
            b.subscribe(bUpstreamSubscriber)
            a.subscribe(aUpstreamSubscriber)
        }
    }
}

extension NKPublishers.CombineLatest: Equatable where A: Equatable, B: Equatable{
    
    public static func == (lhs: NKPublishers.CombineLatest<A, B>, rhs: NKPublishers.CombineLatest<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

