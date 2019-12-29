//
//  NSTextView.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

#if canImport(AppKit)

import AppKit

extension NSTextView {

    public var nkTextPublisher: NKAnyPublisher<String, Never> {
        NotificationCenter.default.nkPublisher(for: NSTextView.didChangeNotification, object: self)
            .map { ($0.object as? Self)?.string ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
