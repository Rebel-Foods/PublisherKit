//
//  Matches.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {

    /// A publisher that publishes an array containing all the matches of the given regular pattern from the output.
    public struct Matches<Upstream: PKPublisher>: PKPublisher where Upstream.Output == String {

        public typealias Output = [NSTextCheckingResult]

        public typealias Failure = Error

        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public let pattern: String
        
        public let options: NSRegularExpression.Options
        
        public let matchOptions: NSRegularExpression.MatchingOptions

        public init(upstream: Upstream, pattern: String, options: NSRegularExpression.Options, matchOptions: NSRegularExpression.MatchingOptions) {
            self.upstream = upstream
            self.pattern = pattern
            self.options = options
            self.matchOptions = matchOptions
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            var expression: NSRegularExpression?
            var error: Error?
            
            do {
                expression = try NSRegularExpression(pattern: pattern, options: options)
            } catch let creationError {
                error = creationError
            }
            
            typealias Sub = PKSubscribers.OperatorSink<S, Upstream.Output, Failure>
            
            let upstreamSubscriber = Sub(downstream: subscriber, receiveCompletion: { (completion) in
                
                subscriber.receive(completion: completion)
                
            }) { (output) in
                
                if let error = error {
                    subscriber.receive(completion: .failure(error))
                } else if let expression = expression {
                    let matches = expression.matches(in: output, options: self.matchOptions, range: NSRange(location: 0, length: output.utf8.count))
                    _ = subscriber.receive(matches)
                }
            }
            
            let superSubscriber = PKSubscribers.OperatorSink<Sub, Upstream.Output, Upstream.Failure>(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                
                let newCompletion = completion.mapError { $0 as Failure}
                upstreamSubscriber.receive(completion: newCompletion)
                
            }) { (output) in
                _ = upstreamSubscriber.receive(output)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(superSubscriber)
        }
    }
}
