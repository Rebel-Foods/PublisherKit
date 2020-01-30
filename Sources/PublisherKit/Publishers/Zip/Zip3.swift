//
//  Zip3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the zip function to three upstream publishers.
    public struct Zip3<A: PKPublisher, B: PKPublisher, C: PKPublisher>: PKPublisher where A.Failure == B.Failure, B.Failure == C.Failure {
        
        public typealias Output = (A.Output, B.Output, C.Output)
        
        public typealias Failure = A.Failure
        
        public let a: A
        
        public let b: B
        
        public let c: C
        
        public init(_ a: A, _ b: B, _ c: C) {
            self.a = a
            self.b = b
            self.c = c
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let zipSubscriber = InternalSink(downstream: subscriber)
            
            zipSubscriber.receiveSubscription()
            
            subscriber.receive(subscription: zipSubscriber)
            
            zipSubscriber.sendRequest()
            
            c.subscribe(zipSubscriber.cSubscriber)
            b.subscribe(zipSubscriber.bSubscriber)
            a.subscribe(zipSubscriber.aSubscriber)
        }
    }
}

extension PKPublishers.Zip3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    
    public static func == (lhs: PKPublishers.Zip3<A, B, C>, rhs: PKPublishers.Zip3<A, B, C>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}

extension PKPublishers.Zip3 {
    
    // MARK: ZIP3 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutputs: [A.Output] = []
        private var bOutputs: [B.Output] = []
        private var cOutputs: [C.Output] = []
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
            receive(subscription: cSubscriber)
        }
        
        override func sendRequest() {
            request(.unlimited)
            aSubscriber.request(.unlimited)
            bSubscriber.request(.unlimited)
            cSubscriber.request(.unlimited)
        }
        
        private func receive(a input: A.Output, downstream: CombineSink<Downstream>?) {
            aOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: CombineSink<Downstream>?) {
            bOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(c input: C.Output, downstream: CombineSink<Downstream>?) {
            cOutputs.append(input)
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard !aOutputs.isEmpty, !bOutputs.isEmpty, !cOutputs.isEmpty else {
                return
            }
            
            let aOutput = aOutputs.removeFirst()
            let bOutput = bOutputs.removeFirst()
            let cOutput = cOutputs.removeFirst()
            
            receive(input: (aOutput, bOutput, cOutput))
        }
    }
}
