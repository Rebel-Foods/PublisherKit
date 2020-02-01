//
//  Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that republishes all non-`nil` results of calling a closure with each received element.
    struct CompactMap<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let compactMapSubscriber = InternalSink(downstream: subscriber, transform: transform)
            upstream.subscribe(compactMapSubscriber)
        }
    }
}

extension PKPublishers.CompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) -> T?) -> PKPublishers.CompactMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T? = { output in
            if let newOutput = self.transform(output) {
                return transform(newOutput)
            } else {
                return nil
            }
        }
        
        return PKPublishers.CompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> PKPublishers.CompactMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T? = { output in
            if let newOutput = self.transform(output) {
                return transform(newOutput)
            } else {
                return nil
            }
        }
        
        return PKPublishers.CompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}

extension PKPublishers.CompactMap {
    
    // MARK: COMPACTMAP SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Output) -> Output?
        
        init(downstream: Downstream, transform: @escaping (Upstream.Output) -> Output?) {
            self.transform = transform
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            let output = self.transform(input)
            if let value = output {
                _ = downstream?.receive(value)
            }
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
