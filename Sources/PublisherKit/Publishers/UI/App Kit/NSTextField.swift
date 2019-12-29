//
//  NSTextField.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

#if canImport(AppKit)

import AppKit

extension NSTextField {

    public var nkTextPublisher: NKAnyPublisher<String, Never> {
        NotificationCenter.default.nkPublisher(for: NSTextField.textDidChangeNotification as Notification.Name, object: self)
            .map { ($0.object as? Self)?.stringValue ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif