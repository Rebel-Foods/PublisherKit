//
//  Combine Latest3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the zip function to two upstream publishers.
    public struct CombineLatest3<A: PKPublisher, B: PKPublisher, C: PKPublisher>: PKPublisher where A.Failure == B.Failure, B.Failure == C.Failure {
        
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
            
            let combineLatestSubscriber = InternalSink(downstream: subscriber)
            
            combineLatestSubscriber.receiveSubscription()
            
            subscriber.receive(subscription: combineLatestSubscriber)
            
            combineLatestSubscriber.sendRequest()
            
            c.subscribe(combineLatestSubscriber.cSubscriber)
            b.subscribe(combineLatestSubscriber.bSubscriber)
            a.subscribe(combineLatestSubscriber.aSubscriber)
        }
    }
}

extension PKPublishers.CombineLatest3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    
    public static func == (lhs: PKPublishers.CombineLatest3<A, B, C>, rhs: PKPublishers.CombineLatest3<A, B, C>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}

extension PKPublishers.CombineLatest3 {
    
    // MARK: COMBINELATEST3 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutput: A.Output?
        private var bOutput: B.Output?
        private var cOutput: C.Output?
        
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
        
        private func receive(a input: A.Output, downstream: InternalSink?) {
            aOutput = input
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: InternalSink?) {
            bOutput = input
            checkAndSend()
        }
        
        private func receive(c input: C.Output, downstream: InternalSink?) {
            cOutput = input
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard let aOutput = aOutput, let bOutput = bOutput, let cOutput = cOutput else {
                return
            }
            
            receive(input: (aOutput, bOutput, cOutput))
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            if let error = completion.getError() {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver {
                end()
                downstream?.receive(completion: .finished)
            }
        }
    }
}
