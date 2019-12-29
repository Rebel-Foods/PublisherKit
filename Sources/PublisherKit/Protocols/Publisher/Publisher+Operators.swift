//
//  Publisher+Operators.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

// MARK: OPERATORS
/// THIS EXTENSIONS LISTS ALL OPERATOR METHODS FOR PUBLISHERS





// MARK: ALL SATISFY
extension NKPublisher {

    /// Publishes a single Boolean value that indicates whether all received elements pass a given predicate.
    ///
    /// When this publisher receives an element, it runs the predicate against the element. If the predicate returns `false`, the publisher produces a `false` value and finishes. If the upstream publisher finishes normally, this publisher produces a `true` value and finishes.
    /// As a `reduce`-style operator, this publisher produces at most one value.
    /// Backpressure note: Upon receiving any request greater than zero, this publisher requests unlimited elements from the upstream publisher.
    /// - Parameter predicate: A closure that evaluates each received element. Return `true` to continue, or `false` to cancel the upstream and complete.
    /// - Returns: A publisher that publishes a Boolean value that indicates whether all received elements pass a given predicate.
    public func allSatisfy(_ predicate: @escaping (Output) -> Bool) -> NKPublishers.AllSatisfy<Self> {
        NKPublishers.AllSatisfy(upstream: self, predicate: predicate)
    }

    /// Publishes a single Boolean value that indicates whether all received elements pass a given error-throwing predicate.
    ///
    /// When this publisher receives an element, it runs the predicate against the element. If the predicate returns `false`, the publisher produces a `false` value and finishes. If the upstream publisher finishes normally, this publisher produces a `true` value and finishes. If the predicate throws an error, the publisher fails, passing the error to its downstream.
    /// As a `reduce`-style operator, this publisher produces at most one value.
    /// Backpressure note: Upon receiving any request greater than zero, this publisher requests unlimited elements from the upstream publisher.
    /// - Parameter predicate:  A closure that evaluates each received element. Return `true` to continue, or `false` to cancel the upstream and complete. The closure may throw, in which case the publisher cancels the upstream publisher and fails with the thrown error.
    /// - Returns:  A publisher that publishes a Boolean value that indicates whether all received elements pass a given predicate.
    public func tryAllSatisfy(_ predicate: @escaping (Output) throws -> Bool) -> NKPublishers.TryAllSatisfy<Self> {
        NKPublishers.TryAllSatisfy(upstream: self, predicate: predicate)
    }
}

// MARK: CATCH
public extension NKPublisher {
    
    /// Handles errors from an upstream publisher by replacing it with another publisher.
    ///
    /// The following example replaces any error from the upstream publisher and replaces the upstream with a `Just` publisher. This continues the stream by publishing a single value and completing normally.
    /// ```
    /// enum SimpleError: Error { case error }
    /// let errorPublisher = (0..<10).publisher.tryMap { v -> Int in
    ///     if v < 5 {
    ///         return v
    ///     } else {
    ///         throw SimpleError.error
    ///     }
    /// }
    ///
    /// let noErrorPublisher = errorPublisher.catch { _ in
    ///     return Just(100)
    /// }
    /// ```
    /// Backpressure note: This publisher passes through `request` and `cancel` to the upstream. After receiving an error, the publisher sends sends any unfulfilled demand to the new `Publisher`.
    /// - Parameter handler: A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
    /// - Returns: A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
    func `catch`<P: NKPublisher>(_ handler: @escaping (Failure) -> P) -> NKPublishers.Catch<Self, P> where Output == P.Output {
        NKPublishers.Catch(upstream: self, handler: handler)
    }
    
    /// Handles errors from an upstream publisher by either replacing it with another publisher or `throw`ing  a new error.
    ///
    /// - Parameter handler: A `throw`ing closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher or if an error is thrown will send the error downstream.
    /// - Returns: A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
    func tryCatch<P: NKPublisher>(_ handler: @escaping (Failure) throws -> P) -> NKPublishers.TryCatch<Self, P> where Output == P.Output {
        NKPublishers.TryCatch(upstream: self, handler: handler)
    }
}

// MARK: COMBINE LATEST
extension NKPublisher {

/// Subscribes to an additional publisher and publishes a tuple upon receiving output from either publisher.
///
/// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
/// All upstream publishers need to finish for this publisher to finsh. If an upstream publisher never publishes a value, this publisher never finishes.
/// If any of the combined publishers terminates with a failure, this publisher also fails.
/// - Parameters:
///   - other: Another publisher to combine with this one.
/// - Returns: A publisher that receives and combines elements from this and another publisher.
    public func combineLatest<P: NKPublisher>(_ other: P) -> NKPublishers.CombineLatest<Self, P> where Failure == P.Failure {
        NKPublishers.CombineLatest(self, other)
    }
    
    /// Subscribes to an additional publisher and invokes a closure upon receiving output from either publisher.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finsh. If an upstream publisher never publishes a value, this publisher never finishes.
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    /// - Parameters:
    ///   - other: Another publisher to combine with this one.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that receives and combines elements from this and another publisher.
    public func combineLatest<P: NKPublisher, T>(_ other: P, _ transform: @escaping (Output, P.Output) -> T) -> NKPublishers.Map<NKPublishers.CombineLatest<Self, P>, T> where Failure == P.Failure {
        
        let publisher = NKPublishers.CombineLatest(self, other)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
    
    // MARK: COMBINE LATEST 3

    /// Subscribes to two additional publishers and publishes a tuple upon receiving output from any of the publishers.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value, this publisher never finishes.
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    /// - Returns: A publisher that receives and combines elements from this publisher and two other publishers.
    public func combineLatest<P: NKPublisher, Q: NKPublisher>(_ publisher1: P, _ publisher2: Q) -> NKPublishers.CombineLatest3<Self, P, Q> where Failure == P.Failure, P.Failure == Q.Failure {
        NKPublishers.CombineLatest3(self, publisher1, publisher2)
    }

    /// Subscribes to two additional publishers and invokes a closure upon receiving output from any of the publishers.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value, this publisher never finishes.
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that receives and combines elements from this publisher and two other publishers.
    public func combineLatest<P: NKPublisher, Q: NKPublisher, T>(_ publisher1: P, _ publisher2: Q, _ transform: @escaping (Output, P.Output, Q.Output) -> T) -> NKPublishers.Map<NKPublishers.CombineLatest3<Self, P, Q>, T> where Failure == P.Failure, P.Failure == Q.Failure {
        
        let publisher = NKPublishers.CombineLatest3(self, publisher1, publisher2)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
    
    // MARK: COMBINE LATEST 4

    /// Subscribes to three additional publishers and publishes a tuple upon receiving output from any of the publishers.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value, this publisher never finishes.
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    ///   - publisher3: A fourth publisher to combine with this one.
    /// - Returns: A publisher that receives and combines elements from this publisher and three other publishers.
    public func combineLatest<P: NKPublisher, Q: NKPublisher, R: NKPublisher>(_ publisher1: P, _ publisher2: Q, _ publisher3: R) -> NKPublishers.CombineLatest4<Self, P, Q, R> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure {
        NKPublishers.CombineLatest4(self, publisher1, publisher2, publisher3)
    }

    /// Subscribes to three additional publishers and invokes a closure upon receiving output from any of the publishers.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value, this publisher never finishes.
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    ///   - publisher3: A fourth publisher to combine with this one.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that receives and combines elements from this publisher and three other publishers.
    public func combineLatest<P: NKPublisher, Q: NKPublisher, R: NKPublisher, T>(_ publisher1: P, _ publisher2: Q, _ publisher3: R, _ transform: @escaping (Output, P.Output, Q.Output, R.Output) -> T) -> NKPublishers.Map<NKPublishers.CombineLatest4<Self, P, Q, R>, T> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure {
        
        let publisher = NKPublishers.CombineLatest4(self, publisher1, publisher2, publisher3)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
    
    // MARK: COMBINE LATEST 5
    
    
    /// Subscribes to three additional publishers and publishes a tuple upon receiving output from any of the publishers.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value, this publisher never finishes.
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    ///   - publisher3: A fourth publisher to combine with this one.
    ///   - publisher4: A fifth publisher to combine with this one.
    /// - Returns: A publisher that receives and combines elements from this publisher and three other publishers.
    public func combineLatest<P: NKPublisher, Q: NKPublisher, R: NKPublisher, S: NKPublisher>(_ publisher1: P, _ publisher2: Q, _ publisher3: R, _ publisher4: S) -> NKPublishers.CombineLatest5<Self, P, Q, R, S> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure, R.Failure == S.Failure {
        NKPublishers.CombineLatest5(self, publisher1, publisher2, publisher3, publisher4)
    }

    /// Subscribes to three additional publishers and invokes a closure upon receiving output from any of the publishers.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value, this publisher never finishes.
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    ///   - publisher3: A fourth publisher to combine with this one.
    ///   - publisher4: A fifth publisher to combine with this one.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that receives and combines elements from this publisher and three other publishers.
    public func combineLatest<P: NKPublisher, Q: NKPublisher, R: NKPublisher, S: NKPublisher, T>(_ publisher1: P, _ publisher2: Q, _ publisher3: R, _ publisher4: S, _ transform: @escaping (Output, P.Output, Q.Output, R.Output, S.Output) -> T) -> NKPublishers.Map<NKPublishers.CombineLatest5<Self, P, Q, R, S>, T> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure, R.Failure == S.Failure {
        
        let publisher = NKPublishers.CombineLatest5(self, publisher1, publisher2, publisher3, publisher4)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
}

// MARK: COUNT
extension NKPublisher {

    /// Publishes the number of elements received from the upstream publisher.
    ///
    /// - Returns: A publisher that consumes all elements until the upstream publisher finishes, then emits a single
    /// value with the total number of elements received.
    public func count() -> NKPublishers.Count<Self> {
        NKPublishers.Count(upstream: self)
    }
}

// MARK: COMPACT MAP
public extension NKPublisher {
    
    /// Calls a closure with each received element and publishes any returned optional that has a value.
    ///
    /// - Parameter transform: A closure that receives a value and returns an optional value.
    /// - Returns: A publisher that republishes all non-`nil` results of calling the transform closure.
    func compactMap<T>(_ transform: @escaping (Output) -> T?) -> NKPublishers.CompactMap<Self, T> {
        NKPublishers.CompactMap(upstream: self, transform: transform)
    }
    
    /// Calls an error-throwing closure with each received element and publishes any returned optional that has a value.
    ///
    /// If the closure throws an error, the publisher cancels the upstream and sends the thrown error to the downstream receiver as a `Failure`.
    /// - Parameter transform: an error-throwing closure that receives a value and returns an optional value.
    /// - Returns: A publisher that republishes all non-`nil` results of calling the transform closure.
    func tryCompactMap<T>(_ transform: @escaping (Output) throws -> T?) -> NKPublishers.TryCompactMap<Self, T> {
        NKPublishers.TryCompactMap(upstream: self, transform: transform)
    }
}

// MARK: DEBOUNCE
public extension NKPublisher {
    
    /// Publishes elements only after a specified time interval elapses between events.
    ///
    /// Use this operator when you want to wait for a pause in the delivery of events from the upstream publisher. For example, call `debounce` on the publisher from a text field to only receive elements when the user pauses or stops typing. When they start typing again, the `debounce` holds event delivery until the next pause.
    /// - Parameters:
    ///   - dueTime: The time the publisher should wait before publishing an element.
    /// - Returns: A publisher that publishes events only after a specified time elapses.
    func debounce<S: NKScheduler>(for dueTime: SchedulerTime, on scheduler: S) -> NKPublishers.Debounce<Self, S> {
        NKPublishers.Debounce(upstream: self, dueTime: dueTime, on: scheduler)
    }
}

// MARK: DECODE
public extension NKPublisher {
    
    /// Decodes the output from upstream using a specified `NetworkDecoder`.
    /// For example, use `JSONDecoder`.
    /// - Parameter type: Type to decode into.
    /// - Parameter decoder: `NetworkDecoder` for decoding output.
    func decode<Item, Decoder>(type: Item.Type, decoder: Decoder) -> NKPublishers.Decode<Self, Item, Decoder> {
        NKPublishers.Decode(upstream: self, decoder: decoder)
    }
    
    /// Decodes the output from upstream using a specified `JSONDecoder`.
    /// - Parameter type: Type to decode into.
    /// - Parameter jsonKeyDecodingStrategy: JSON Key Decoding Strategy. Default value is `.useDefaultKeys`.
    func decode<Item>(type: Item.Type, jsonKeyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> NKPublishers.Decode<Self, Item, JSONDecoder> {
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = jsonKeyDecodingStrategy
        
        var publisher = NKPublishers.Decode<Self, Item, JSONDecoder>(upstream: self, decoder: decoder)
        publisher.log = true
        return publisher
    }
}

// MARK: ERASE TO ANY
extension NKPublisher {

    /// Wraps this publisher with a type eraser.
    ///
    /// Use `eraseToAnyPublisher()` to expose an instance of AnyPublisher to the downstream subscriber, rather than this publisher’s actual type.
    public func eraseToAnyPublisher() -> NKAnyPublisher<Output, Failure> {
        NKAnyPublisher(self)
    }
}

// MARK: FILTER
extension NKPublisher {

    /// Republishes all elements that match a provided closure.
    ///
    /// - Parameter isIncluded: A closure that takes one element and returns a Boolean value indicating whether to republish the element.
    /// - Returns: A publisher that republishes all elements that satisfy the closure.
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> NKPublishers.Filter<Self> {
        NKPublishers.Filter(upstream: self, isIncluded: isIncluded)
    }

    /// Republishes all elements that match a provided error-throwing closure.
    ///
    /// If the `isIncluded` closure throws an error, the publisher fails with that error.
    ///
    /// - Parameter isIncluded:  A closure that takes one element and returns a Boolean value indicating whether to republish the element.
    /// - Returns:  A publisher that republishes all elements that satisfy the closure.
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> NKPublishers.TryFilter<Self> {
        NKPublishers.TryFilter(upstream: self, isIncluded: isIncluded)
    }
}

// MARK: FLAT MAP
extension NKPublisher {

    /// Transforms all elements from an upstream publisher into a new or existing publisher.
    ///
    /// `flatMap` merges the output from all returned publishers into a single stream of output.
    ///
    /// - Parameters:
    ///   - maxPublishers: The maximum number of publishers produced by this method.
    ///   - transform: A closure that takes an element as a parameter and returns a publisher
    /// that produces elements of that type.
    /// - Returns: A publisher that transforms elements from an upstream publisher into
    /// a publisher of that element’s type.
    public func flatMap<T, P: NKPublisher>(maxPublishers: NKSubscribers.Demand = .unlimited, _ transform: @escaping (Output) -> P) -> NKPublishers.FlatMap<Self, P> where T == P.Output, Failure == P.Failure {
        NKPublishers.FlatMap(upstream: self, maxPublishers: maxPublishers, transform: transform)
    }
        
}

// MARK: HANDLE EVENTS
extension NKPublisher {
    
    /// Performs the specified closures when publisher events occur.
    ///
    /// - Parameters:
    ///   - receiveSubscription: A closure that executes when the publisher receives the subscription from the upstream publisher. Defaults to `nil`.
    ///   - receiveOutput: A closure that executes when the publisher receives a value from the upstream publisher. Defaults to `nil`.
    ///   - receiveCompletion: A closure that executes when the publisher receives the completion from the upstream publisher. Defaults to `nil`.
    ///   - receiveCancel: A closure that executes when the downstream receiver cancels publishing. Defaults to `nil`.
    ///   - receiveRequest: A closure that executes when the publisher receives a request for more elements. Defaults to `nil`.
    /// - Returns: A publisher that performs the specified closures when publisher events occur.
    public func handleEvents(receiveSubscription: ((NKSubscription) -> Void)? = nil,
                             receiveOutput: ((Output) -> Void)? = nil,
                             receiveCompletion: ((NKSubscribers.Completion<Failure>) -> Void)? = nil,
                             receiveCancel: (() -> Void)? = nil,
                             receiveRequest: ((NKSubscribers.Demand) -> Void)? = nil) -> NKPublishers.HandleEvents<Self> {
        
        NKPublishers.HandleEvents(upstream: self,
                                  receiveSubscription: receiveSubscription,
                                  receiveOutput: receiveOutput,
                                  receiveCompletion: receiveCompletion,
                                  receiveCancel: receiveCancel,
                                  receiveRequest: receiveRequest)
    }
}

// MARK: IGNORE OUTPUT
extension NKPublisher {

    /// Ingores all upstream elements, but passes along a completion state (finished or failed).
    ///
    /// The output type of this publisher is `Never`.
    /// - Returns: A publisher that ignores all upstream elements.
    public func ignoreOutput() -> NKPublishers.IgnoreOutput<Self> {
        NKPublishers.IgnoreOutput(upstream: self)
    }
}

// MARK: MATCHES
extension NKPublisher where Output == String {
    
    public func firstMatch(pattern: String, options: NSRegularExpression.Options = [], matchOptions: NSRegularExpression.MatchingOptions = []) -> NKPublishers.FirstMatch<Self> {
        NKPublishers.FirstMatch(upstream: self, pattern: pattern, options: options, matchOptions: matchOptions)
    }
    
    public func matches(pattern: String, options: NSRegularExpression.Options = [], matchOptions: NSRegularExpression.MatchingOptions = []) -> NKPublishers.Matches<Self> {
        NKPublishers.Matches(upstream: self, pattern: pattern, options: options, matchOptions: matchOptions)
    }
    
}

// MARK: MAP ERROR
public extension NKPublisher {
    
    /// Converts any failure from the upstream publisher into a new error.
    ///
    /// Until the upstream publisher finishes normally or fails with an error, the returned publisher republishes all the elements it receives.
    ///
    /// - Parameter transform: A closure that takes the upstream failure as a parameter and returns a new error for the publisher to terminate with.
    /// - Returns: A publisher that replaces any upstream failure with a new error produced by the `transform` closure.
    func mapError<E: Error>(_ transform: @escaping (Failure) -> E) -> NKPublishers.MapError<Self, E> {
        NKPublishers.MapError(upstream: self, transform: transform)
    }
}

// MARK: MAP
public extension NKPublisher {
    
    /// Transforms all elements from the upstream publisher with a provided closure.
    ///
    /// - Parameter transform: A closure that takes one element as its parameter and returns a new element.
    /// - Returns: A publisher that uses the provided closure to map elements from the upstream publisher to new elements that it then publishes.
    func map<T>(_ transform: @escaping (Output) -> T) -> NKPublishers.Map<Self, T> {
        NKPublishers.Map(upstream: self, transform: transform)
    }
    
    /// Transforms all elements from the upstream publisher with a provided error-throwing closure.
    ///
    /// If the `transform` closure throws an error, the publisher fails with the thrown error.
    /// - Parameter transform: A closure that takes one element as its parameter and returns a new element.
    /// - Returns: A publisher that uses the provided closure to map elements from the upstream publisher to new elements that it then publishes.
    func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> NKPublishers.TryMap<Self, T> {
        NKPublishers.TryMap(upstream: self, transform: transform)
    }
}

// MARK: MAP KEYPATH
public extension NKPublisher {
    
    /// Returns a publisher that publishes the value of a key path.
    ///
    /// - Parameter keyPath: The key path of a property on `Output`
    /// - Returns: A publisher that publishes the value of the key path.
    func map<T>(_ keyPath: KeyPath<Output, T>) -> NKPublishers.MapKeyPath<Self, T> {
        NKPublishers.MapKeyPath(upstream: self, keyPath: keyPath)
    }
    
    // MARK: MAP KEYPATH 2
    
    /// Returns a publisher that publishes the values of two key paths as a tuple.
    ///
    /// - Parameters:
    ///   - keyPath0: The key path of a property on `Output`
    ///   - keyPath1: The key path of another property on `Output`
    /// - Returns: A publisher that publishes the values of two key paths as a tuple.
    func map<T0, T1>(_ keyPath0: KeyPath<Output, T0>, _ keyPath1: KeyPath<Output, T1>) -> NKPublishers.MapKeyPath2<Self, T0, T1> {
        NKPublishers.MapKeyPath2(upstream: self, keyPath0: keyPath0, keyPath1: keyPath1)
    }
    
    // MARK: MAP KEYPATH 3
    
    /// Returns a publisher that publishes the values of three key paths as a tuple.
    ///
    /// - Parameters:
    ///   - keyPath0: The key path of a property on `Output`
    ///   - keyPath1: The key path of another property on `Output`
    ///   - keyPath2: The key path of a third  property on `Output`
    /// - Returns: A publisher that publishes the values of three key paths as a tuple.
    func map<T0, T1, T2>(_ keyPath0: KeyPath<Self.Output, T0>, _ keyPath1: KeyPath<Self.Output, T1>, _ keyPath2: KeyPath<Self.Output, T2>) -> NKPublishers.MapKeyPath3<Self, T0, T1, T2> {
        NKPublishers.MapKeyPath3(upstream: self, keyPath0: keyPath0, keyPath1: keyPath1, keyPath2: keyPath2)
    }
}


// MARK: MERGE
extension NKPublisher {

    /// Combines elements from this publisher with those from another publisher, delivering an interleaved sequence of elements.
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error, the merged publisher fails with that error.
    /// - Parameter other: Another publisher.
    /// - Returns: A publisher that emits an event when either upstream publisher emits an event.
    public func merge<P>(with other: P) -> NKPublishers.Merge<Self, P> {
        NKPublishers.Merge(self, other)
    }
    
    // MARK: MERGE 3

    /// Combines elements from this publisher with those from two other publishers, delivering an interleaved sequence of elements.
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    /// - Returns:  A publisher that emits an event when any upstream publisher emits
    /// an event.
    public func merge<B, C>(with b: B, _ c: C) -> NKPublishers.Merge3<Self, B, C> {
        NKPublishers.Merge3(self, b, c)
    }
    
    // MARK: MERGE 4

    /// Combines elements from this publisher with those from three other publishers, delivering
    /// an interleaved sequence of elements.
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    ///   - d: A fourth publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C, D>(with b: B, _ c: C, _ d: D) -> NKPublishers.Merge4<Self, B, C, D> {
        NKPublishers.Merge4(self, b, c, d)
    }
    
    // MARK: MERGE 5

    /// Combines elements from this publisher with those from four other publishers, delivering an interleaved sequence of elements.
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    ///   - d: A fourth publisher.
    ///   - e: A fifth publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C, D, E>(with b: B, _ c: C, _ d: D, _ e: E) -> NKPublishers.Merge5<Self, B, C, D, E> {
        NKPublishers.Merge5(self, b, c, d, e)
    }
    
    // MARK: MERGE 6

    /// Combines elements from this publisher with those from five other publishers, delivering an interleaved sequence of elements.
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    ///   - d: A fourth publisher.
    ///   - e: A fifth publisher.
    ///   - f: A sixth publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C, D, E, F>(with b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> NKPublishers.Merge6<Self, B, C, D, E, F> {
        NKPublishers.Merge6(self, b, c, d, e, f)
    }
    
    // MARK: MERGE 7

    /// Combines elements from this publisher with those from six other publishers, delivering an interleaved sequence of elements.
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    ///   - d: A fourth publisher.
    ///   - e: A fifth publisher.
    ///   - f: A sixth publisher.
    ///   - g: A seventh publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C, D, E, F, G>(with b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> NKPublishers.Merge7<Self, B, C, D, E, F, G> {
        NKPublishers.Merge7(self, b, c, d, e, f, g)
    }
    
    // MARK: MERGE 8

    /// Combines elements from this publisher with those from seven other publishers, delivering an interleaved sequence of elements.
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    ///   - d: A fourth publisher.
    ///   - e: A fifth publisher.
    ///   - f: A sixth publisher.
    ///   - g: A seventh publisher.
    ///   - h: An eighth publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C, D, E, F, G, H>(with b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> NKPublishers.Merge8<Self, B, C, D, E, F, G, H> {
        NKPublishers.Merge8(self, b, c, d, e, f, g, h)
    }

    /// Combines elements from this publisher with those from another publisher of the same type, delivering an interleaved sequence of elements.
    ///
    /// - Parameter other: Another publisher of this publisher's type.
    /// - Returns: A publisher that emits an event when either upstream publisher emits
    /// an event.
    public func merge(with other: Self) -> NKPublishers.MergeMany<Self> {
        NKPublishers.MergeMany(self, other)
    }
}


// MARK: RECEIVE ON
public extension NKPublisher {
    
    /// Shifts operation from current queue to provided queue.
    ///
    /// Use this operator when you want to shift the operations from current queue to provided queue.
    /// - Parameters:
    ///   - queue: The queue on which rest of the operations will be performed unless again changed.
    /// - Returns: A publisher that delivers elements using the specified scheduler.
    func receive(on scheduler: NKScheduler) -> NKPublishers.ReceiveOn<Self> {
        NKPublishers.ReceiveOn(upstream: self, on: scheduler)
    }
}

// MARK: REPLACE EMPTY
public extension NKPublisher {
    
    /// Replaces an empty stream with the provided element.
    ///
    /// If the upstream publisher finishes without producing any elements, this publisher emits the provided element, then finishes normally.
    /// - Parameter output: An element to emit when the upstream publisher finishes without emitting any elements.
    /// - Returns: A publisher that replaces an empty stream with the provided output element.
    func replaceEmpty(with output: Output) -> NKPublishers.ReplaceEmpty<Self> {
        NKPublishers.ReplaceEmpty(upstream: self, output: output)
    }
}

// MARK: REPLACE ERROR
public extension NKPublisher {
    
    /// Replaces any errors in the stream with the provided element.
    ///
    /// If the upstream publisher fails with an error, this publisher emits the provided element, then finishes normally.
    /// - Parameter output: An element to emit when the upstream publisher fails.
    /// - Returns: A publisher that replaces an error from the upstream publisher with the provided output element.
    func replaceError(with output: Output) -> NKPublishers.ReplaceError<Self> {
        NKPublishers.ReplaceError(upstream: self, output: output)
    }
}

// MARK: REPLACE NIL
public extension NKPublisher {
    
    /// Replaces nil elements in the stream with the proviced element.
    ///
    /// - Parameter output: The element to use when replacing `nil`.
    /// - Returns: A publisher that replaces `nil` elements from the upstream publisher with the provided element.
    func replaceNil<T>(with output: T) -> NKPublishers.Map<Self, T> where Output == T? {
        NKPublishers.Map(upstream: self) { _ in output }
    }
}

// MARK: RETRY
extension NKPublisher {

    /// Attempts to recreate a failed subscription with the upstream publisher using a specified number of attempts to establish the connection.
    ///
    /// After exceeding the specified number of retries, the publisher passes the failure to the downstream receiver.
    /// - Parameter retries: The number of times to attempt to recreate the subscription.
    /// - Returns: A publisher that attempts to recreate its subscription to a failed upstream publisher.
    public func retry(_ retries: Int) -> NKPublishers.Retry<Self> {
        NKPublishers.Retry(upstream: self, retries: retries)
    }
}

// MARK: SHARE
extension NKPublisher {

    /// Returns a publisher as a class instance.
    ///
    /// The downstream subscriber receieves elements and completion states unchanged from the upstream publisher. Use this operator when you want to use reference semantics, such as storing a publisher instance in a property.
    ///
    /// - Returns: A class instance that republishes its upstream publisher.
    public func share() -> NKPublishers.Share<Self> {
         NKPublishers.Share(upstream: self)
    }
}

// MARK: ZIP
public extension NKPublisher {
    
    /// Combine elements from another publisher and deliver pairs of elements as tuples.
    ///
    /// The returned publisher waits until both publishers have emitted an event, then delivers the oldest unconsumed event from each publisher together as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits event `c`, the zip publisher emits the tuple `(a, c)`. It won’t emit a tuple with event `b` until `P2` emits another event.
    /// If either upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameter other: Another publisher.
    /// - Returns: A publisher that emits pairs of elements from the upstream publishers as tuples.
    func zip<P: NKPublisher>(_ other: P) -> NKPublishers.Zip<Self, P> where Failure == P.Failure {
        NKPublishers.Zip(self, other)
    }
    
    /// Combine elements from another publisher and deliver a transformed output.
    ///
    /// The returned publisher waits until both publishers have emitted an event, then delivers the oldest unconsumed event from each publisher together as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits event `c`, the zip publisher emits the tuple `(a, c)`. It won’t emit a tuple with event `b` until `P2` emits another event.
    /// If either upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameter other: Another publisher.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that emits pairs of elements from the upstream publishers as tuples.
    func zip<P: NKPublisher, T>(_ other: P, _ transform: @escaping (Output, P.Output) -> T) -> NKPublishers.Map<NKPublishers.Zip<Self, P>, T> where Failure == P.Failure {
        
        let publisher = NKPublishers.Zip(self, other)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
    
    // MARK: ZIP 3

    /// Combine elements from two other publishers and deliver groups of elements as tuples.
    ///
    /// The returned publisher waits until all three publishers have emitted an event, then delivers the oldest unconsumed event from each publisher as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits elements `c` and `d`, and publisher `P3` emits the event `e`, the zip publisher emits the tuple `(a, c, e)`. It won’t emit a tuple with elements `b` or `d` until `P3` emits another event.
    /// If any upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher.
    ///   - publisher2: A third publisher.
    /// - Returns: A publisher that emits groups of elements from the upstream publishers as tuples.
    func zip<P: NKPublisher, Q: NKPublisher>(_ publisher1: P, _ publisher2: Q) -> NKPublishers.Zip3<Self, P, Q> where Failure == P.Failure, P.Failure == Q.Failure {
        NKPublishers.Zip3(self, publisher1, publisher2)
    }

    /// Combine elements from two other publishers and deliver a transformed output.
    ///
    /// The returned publisher waits until all three publishers have emitted an event, then delivers the oldest unconsumed event from each publisher as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits elements `c` and `d`, and publisher `P3` emits the event `e`, the zip publisher emits the tuple `(a, c, e)`. It won’t emit a tuple with elements `b` or `d` until `P3` emits another event.
    /// If any upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher.
    ///   - publisher2: A third publisher.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that emits groups of elements from the upstream publishers as tuples.
    func zip<P: NKPublisher, Q: NKPublisher, T>(_ publisher1: P, _ publisher2: Q, _ transform: @escaping (Output, P.Output, Q.Output) -> T) -> NKPublishers.Map<NKPublishers.Zip3<Self, P, Q>, T> where Failure == P.Failure, P.Failure == Q.Failure {
        
        let publisher = NKPublishers.Zip3(self, publisher1, publisher2)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
    
    // MARK: ZIP 4

    /// Combine elements from three other publishers and deliver groups of elements as tuples.
    ///
    /// The returned publisher waits until all four publishers have emitted an event, then delivers the oldest unconsumed event from each publisher as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits elements `c` and `d`, and publisher `P3` emits the elements `e` and `f`, and publisher `P4` emits the event `g`, the zip publisher emits the tuple `(a, c, e, g)`. It won’t emit a tuple with elements `b`, `d`, or `f` until `P4` emits another event.
    /// If any upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher.
    ///   - publisher2: A third publisher.
    ///   - publisher3: A fourth publisher.
    /// - Returns: A publisher that emits groups of elements from the upstream publishers as tuples.
    func zip<P: NKPublisher, Q: NKPublisher, R: NKPublisher>(_ publisher1: P, _ publisher2: Q, _ publisher3: R) -> NKPublishers.Zip4<Self, P, Q, R> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure {
        NKPublishers.Zip4(self, publisher1, publisher2, publisher3)
    }

    /// Combine elements from three other publishers and deliver a transformed output.
    ///
    /// The returned publisher waits until all four publishers have emitted an event, then delivers the oldest unconsumed event from each publisher as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits elements `c` and `d`, and publisher `P3` emits the elements `e` and `f`, and publisher `P4` emits the event `g`, the zip publisher emits the tuple `(a, c, e, g)`. It won’t emit a tuple with elements `b`, `d`, or `f` until `P4` emits another event.
    /// If any upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher.
    ///   - publisher2: A third publisher.
    ///   - publisher3: A fourth publisher.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that emits groups of elements from the upstream publishers as tuples.
    func zip<P, Q, R, T>(_ publisher1: P, _ publisher2: Q, _ publisher3: R, _ transform: @escaping (Output, P.Output, Q.Output, R.Output) -> T) -> NKPublishers.Map<NKPublishers.Zip4<Self, P, Q, R>, T> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure {
        
        let publisher = NKPublishers.Zip4(self, publisher1, publisher2, publisher3)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
    
    // MARK: ZIP 5
    
    /// Combine elements from four other publishers and deliver groups of elements as tuples.
    ///
    /// The returned publisher waits until all four publishers have emitted an event, then delivers the oldest unconsumed event from each publisher as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits elements `c` and `d`, and publisher `P3` emits the elements `e` and `f`, and publisher `P4` emits elements `g` and `h` and publisher `P5` emaits the event `i`, the zip publisher emits the tuple `(a, c, e, g, h)`. It won’t emit a tuple with elements `b`, `d`, `f`, or `h` until `P5` emits another event.
    /// If any upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher.
    ///   - publisher2: A third publisher.
    ///   - publisher3: A fourth publisher.
    ///   - publisher4: A fifth publisher.
    /// - Returns: A publisher that emits groups of elements from the upstream publishers as tuples.
    func zip<P: NKPublisher, Q: NKPublisher, R: NKPublisher, S: NKPublisher>(_ publisher1: P, _ publisher2: Q, _ publisher3: R, _ publisher4: S) -> NKPublishers.Zip5<Self, P, Q, R, S> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure, R.Failure == S.Failure {
        
        NKPublishers.Zip5(self, publisher1, publisher2, publisher3, publisher4)
    }

    /// Combine elements from four other publishers and deliver a transformed output.
    ///
    /// The returned publisher waits until all four publishers have emitted an event, then delivers the oldest unconsumed event from each publisher as a tuple to the subscriber.
    /// For example, if publisher `P1` emits elements `a` and `b`, and publisher `P2` emits elements `c` and `d`, and publisher `P3` emits the elements `e` and `f`, and publisher `P4` emits elements `g` and `h` and publisher `P5` emits the event `i`, the zip publisher emits the tuple `(a, c, e, g, i)`. It won’t emit a tuple with elements `b`, `d`, `f` or `h` until `P5` emits another event.
    /// If any upstream publisher finishes successfuly or fails with an error, the zipped publisher does the same.
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher.
    ///   - publisher2: A third publisher.
    ///   - publisher3: A fourth publisher.
    ///   - publisher4: A fifth publisher.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that emits groups of elements from the upstream publishers as tuples.
    func zip<P: NKPublisher, Q: NKPublisher, R: NKPublisher, S: NKPublisher, T>(_ publisher1: P, _ publisher2: Q, _ publisher3: R, _ publisher4: S, _ transform: @escaping (Output, P.Output, Q.Output, R.Output, S.Output) -> T) -> NKPublishers.Map<NKPublishers.Zip5<Self, P, Q, R, S>, T> where Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure, R.Failure == S.Failure {
        
        let publisher = NKPublishers.Zip5(self, publisher1, publisher2, publisher3, publisher4)
        let map = NKPublishers.Map(upstream: publisher, transform: transform)
        return map
    }
}