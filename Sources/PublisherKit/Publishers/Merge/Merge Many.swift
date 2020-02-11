//
//  Merge Many.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    public struct MergeMany<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        public let publishers: [Upstream]
        
        public init(_ upstream: Upstream...) {
            publishers = upstream
        }
        
        public init<S: Swift.Sequence>(_ upstream: S) where Upstream == S.Element {
            publishers = upstream.map { $0 }
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = Inner(downstream: subscriber)
            
            publishers.forEach { (publisher) in
                publisher.subscribe(mergeSubscriber)
            }
        }
        
        public func merge(with other: Upstream) -> Publishers.MergeMany<Upstream> {
            Publishers.MergeMany(publishers + [other])
        }
    }
}

extension Publishers.MergeMany {

    // MARK: MERGE ALL SINK
    final class Inner<Downstream: Subscriber>: Subscribers.Inner<Downstream, Upstream.Output, Upstream.Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override var description: String {
            "Merge Many"
        }
    }
}
