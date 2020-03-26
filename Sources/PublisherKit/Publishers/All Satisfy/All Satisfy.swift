//
//  All Satisfy.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that publishes a single Boolean value that indicates whether all received elements pass a given predicate.
    public struct AllSatisfy<Upstream: Publisher>: Publisher {
        
        public typealias Output = Bool
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that evaluates each received element.
        ///
        ///  Return `true` to continue, or `false` to cancel the upstream and finish.
        public let predicate: (Upstream.Output) -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Upstream.Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, operation: predicate))
        }
    }
}

extension Publishers.AllSatisfy {
    
    // MARK: ALL SATISFY SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> CompletionResult<Void, Failure> {
            output = operation(input)
            return output == true ? .send : .finished
        }
        
        override var description: String {
            "AllSatisfy"
        }
    }
}
