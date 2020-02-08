//
//  Print.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

import Foundation

extension Publishers {
    
    /// A publisher that prints log messages for all publishing events, optionally prefixed with a given string.
    ///
    /// This publisher prints log messages when receiving the following events:
    /// * subscription
    /// * value
    /// * normal completion
    /// * failure
    /// * cancellation
    public struct Print<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A string with which to prefix all log messages.
        public let prefix: String
        
        /// An output stream to receive the text representation of each item.
        public let stream: TextOutputStream?
        
        /// Creates a publisher that prints log messages for all publishing events.
        ///
        /// - Parameters:
        ///   - upstream: The publisher from which this publisher receives elements.
        ///   - prefix: A string with which to prefix all log messages.
        ///   - stream: An output stream to receive the text representation of each item.
        public init(upstream: Upstream, prefix: String, to stream: TextOutputStream? = nil) {
            self.upstream = upstream
            self.prefix = prefix
            self.stream = stream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let printSubscriber = InternalSink(downstream: subscriber, prefix: prefix, to: stream)
            upstream.subscribe(printSubscriber)
        }
    }
}


extension Publishers.Print {
    
    // MARK: PRINT SINK
    private final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let prefix: String
        
        private struct OutputStream: TextOutputStream {
           var stream: TextOutputStream

            mutating func write(_ string: String) {
                stream.write(string)
            }
        }
        
        private var stream: OutputStream?
        
        init(downstream: Downstream, prefix: String, to stream: TextOutputStream?) {
            self.prefix = prefix
            self.stream = stream.map { OutputStream(stream: $0) }
            super.init(downstream: downstream)
        }
        
        override func receive(subscription: Subscription) {
            guard !isOver else { return }
            print("receive subscription: (\(subscription))")
            super.receive(subscription: subscription)
        }
        
        override func request(_ demand: Subscribers.Demand) {
            guard !isOver else { return }
            
            if let max = demand.max {
                print("request max: (\(max))")
            } else {
                print("request unlimited")
            }
            
            super.request(demand)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isOver else { return .none }
            print("receive value: (\(input))")
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isOver else { return }
            
            switch completion {
            case .finished:
                print("receive finished")
            case .failure(let error):
                print("receive error: (\(error))")
            }
            
            end()
            downstream?.receive(completion: completion)
        }
        
        func print(_ text: String) {
            let text = "\(prefix)\(text)"
            
            if var stream = stream {
                Swift.print(text, to: &stream)
            } else {
                Swift.print(text)
            }
        }
    }
}
