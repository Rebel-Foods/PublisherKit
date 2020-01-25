//
//  Scheduler.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "PKScheduler")
public typealias NKScheduler = PKScheduler

public protocol PKScheduler: class {
    
    func schedule(after time: SchedulerTime, _ block: @escaping () -> Void)
    func schedule(block: @escaping () -> Void)
}
