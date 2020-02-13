//
//  NSObject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension NSObject: PublisherCompatible {
}

extension NSObject {
    
    /// A publisher that emits events when the value of a KVO-compliant property changes.
    public struct KeyValueObservingPKPublisher<Subject: NSObject, Value>: Equatable, Publisher {
        
        public typealias Output = Value
        
        public typealias Failure = Never
        
        /// The object that contains the property to observe.
        public let object: Subject
        
        /// The key path of a property to observe.
        public let keyPath: KeyPath<Subject, Value>
        
        /// The observing options for the property.
        public let options: NSKeyValueObservingOptions
        
        public init(object: Subject, keyPath: KeyPath<Subject, Value>, options: NSKeyValueObservingOptions) {
            self.object = object
            self.keyPath = keyPath
            self.options = options
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let nsObjectSubscriber = Inner(downstream: subscriber, object: object, keyPath: keyPath, options: options)
            
            subscriber.receive(subscription: nsObjectSubscriber)
            nsObjectSubscriber.request(.unlimited)
            
            nsObjectSubscriber.observe()
        }
        
        public static func == (lhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>, rhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>) -> Bool {
            lhs.keyPath == rhs.keyPath && lhs.options == rhs.options
        }
    }
}

extension NSObject.KeyValueObservingPKPublisher {
    
    // MARK: NSOBJECT SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var observer: NSKeyValueObservation?
        
        private var object: Subject?
        
        private let keyPath: KeyPath<Subject, Value>
        
        private let options: NSKeyValueObservingOptions
        
        init(downstream: Downstream, object: Subject, keyPath: KeyPath<Subject, Value>, options: NSKeyValueObservingOptions) {
            self.object = object
            self.keyPath = keyPath
            self.options = options
            super.init(downstream: downstream)
        }
        
        func observe() {
            observer = object?.observe(keyPath, options: options) { [weak self] (object, valueChange) in
                
                if let oldValue = valueChange.oldValue {
                    self?.receive(input: oldValue)
                }
                
                if let newValue = valueChange.newValue {
                    self?.receive(input: newValue)
                }
            }
        }
        
        override func receive(input: Value) {
            guard !isTerminated else { return }
            _ = downstream?.receive(input)
        }
        
        override func cancel() {
            super.cancel()
            observer?.invalidate()
            observer = nil
            object = nil
        }
        
        override var description: String {
            "NSObject KeyValueObserving"
        }
    }
}
