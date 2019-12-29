//
//  Zip Sink3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

class ZipSink3<Downstream: NKSubscriber, AInput, BInput, CInput, Failure>: InternalSink<Downstream, (AInput, BInput, CInput), Failure> where Downstream.Input == (AInput, BInput, CInput), Downstream.Failure == Failure {
    
    var aOutput: AInput?
    var bOutput: BInput?
    var cOutput: CInput?
    
    var subscriptions: [NKSubscription] = []
    
    override func receive(subscription: NKSubscription) {
        guard !isCancelled else { return }
        subscriptions.append(subscription)
    }
    
    override func receive(_ input: (AInput, BInput, CInput)) -> NKSubscribers.Demand {
        guard !isCancelled else { return .none }
        _ = downstream?.receive(input)
        return demand
    }
    
    func receive(a input: AInput) {
        aOutput = input
        checkAndSend()
    }
    
    func receive(b input: BInput) {
        bOutput = input
        checkAndSend()
    }
    
    func receive(c input: CInput) {
        cOutput = input
        checkAndSend()
    }
    
    func checkAndSend() {
        if let aValue = aOutput, let bValue = bOutput, let cValue = cOutput {
            aOutput = nil
            bOutput = nil
            cOutput = nil
            
            _ = receive((aValue, bValue, cValue))
        }
    }
    
    override func receive(completion: NKSubscribers.Completion<Failure>) {
        guard !isCancelled else { return }
        downstream?.receive(completion: completion)
        end()
    }
    
    override func end() {
        super.end()
        subscriptions.removeAll()
    }
}