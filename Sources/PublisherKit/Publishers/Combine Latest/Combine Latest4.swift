//
//  Combine Latest4.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that receives and combines the latest elements from four publishers.
    public struct CombineLatest4<A: PKPublisher, B: PKPublisher, C: PKPublisher, D: PKPublisher>: PKPublisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure {
        
        public typealias Output = (A.Output, B.Output, C.Output, D.Output)
        
        public typealias Failure = A.Failure
        
        /// A publisher.
        public let a: A
        
        /// A second publisher.
        public let b: B
        
        /// A third publisher.
        public let c: C
        
        /// A fourth publisher.
        public let d: D
        
        public init(_ a: A, _ b: B, _ c: C, _ d: D) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let combineLatestSubscriber = InternalSink(downstream: subscriber)
            
            d.subscribe(combineLatestSubscriber.dSubscriber)
            c.subscribe(combineLatestSubscriber.cSubscriber)
            b.subscribe(combineLatestSubscriber.bSubscriber)
            a.subscribe(combineLatestSubscriber.aSubscriber)
        }
    }
}

extension PKPublishers.CombineLatest4: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable {
    
    public static func == (lhs: PKPublishers.CombineLatest4<A, B, C, D>, rhs: PKPublishers.CombineLatest4<A, B, C, D>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d
    }
}

extension PKPublishers.CombineLatest4 {
    
    // MARK: COMBINELATEST4 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.ClosureOperatorSink<InternalSink, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.ClosureOperatorSink<InternalSink, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.ClosureOperatorSink<InternalSink, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = PKSubscribers.ClosureOperatorSink<InternalSink, D.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutput: A.Output?
        private var bOutput: B.Output?
        private var cOutput: C.Output?
        private var dOutput: D.Output?
        
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
        
        private func receive(d input: D.Output, downstream: InternalSink?) {
            dOutput = input
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard let aOutput = aOutput, let bOutput = bOutput, let cOutput = cOutput, let dOutput = dOutput else {
                return
            }
            
            receive(input: (aOutput, bOutput, cOutput, dOutput))
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            if let error = completion.getError() {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver && dSubscriber.isOver {
                end()
                downstream?.receive(completion: .finished)
            }
        }
    }
}
