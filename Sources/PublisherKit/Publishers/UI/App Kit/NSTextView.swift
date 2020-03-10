//
//  NSTextView.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

#if canImport(AppKit)

import AppKit

extension NSTextView {
    
    @available(*, deprecated, renamed: "textDidChangePublisher")
    public var nkTextPublisher: AnyPublisher<String, Never> {
        textDidChangePublisher
    }
    
    @available(*, deprecated, renamed: "textDidChangePublisher")
    public var textChangePublisher: AnyPublisher<String, Never> {
        textDidChangePublisher
    }
    
    public var textDidBeginEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextView.didBeginEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    public var textDidChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextView.didChangeNotification, object: self)
            .map { ($0.object as? NSTextView)?.string ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textDidEndEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextView.didEndEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

#endif
