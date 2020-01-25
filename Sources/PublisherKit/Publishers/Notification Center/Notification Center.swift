//
//  Notification Center.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NotificationCenter {
    
    public func pkPublisher(for name: Notification.Name, object: AnyObject? = nil) -> NotificationCenter.PKPublisher {
        PKPublisher(center: self, name: name, object: object)
    }
    
    @available(*, deprecated, renamed: "pkPublisher")
    public func nkPublisher(for name: Notification.Name, object: AnyObject? = nil) -> NotificationCenter.PKPublisher {
        pkPublisher(for: name, object: object)
    }
}

extension NotificationCenter {
    
    public struct PKPublisher: PublisherKit.PKPublisher {
        
        public typealias Output = Notification
        
        public typealias Failure = Never
        
        /// The notification center this publisher uses as a source.
        public let center: NotificationCenter
        
        /// The name of notifications published by this publisher.
        public let name: Notification.Name
        
        /// The object posting the named notfication.
        public let object: AnyObject?
        
        /// Creates a publisher that emits events when broadcasting notifications.
        ///
        /// - Parameters:
        ///   - center: The notification center to publish notifications for.
        ///   - name: The name of the notification to publish.
        ///   - object: The object posting the named notfication. If `nil`, the publisher emits elements for any object producing a notification with the given name.
        public init(center: NotificationCenter, name: Notification.Name, object: AnyObject? = nil) {
            self.center = center
            self.name = name
            self.object = object
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let notificationSubscriber = Inner(downstream: subscriber, center: center, name: name, object: object)

            notificationSubscriber.observer = center.addObserver(forName: name, object: object, queue: nil) { (notification) in
                notificationSubscriber.receive(input: notification)
            }
            
            notificationSubscriber.request(.unlimited)
            subscriber.receive(subscription: notificationSubscriber)
        }
    }
    
    final class Inner<Downstream: PKSubscriber>: SameUpstreamOperatorSink<Downstream, PKPublisher> where Downstream.Failure == PKPublisher.Failure, Downstream.Input == PKPublisher.Output {
        
        let center: NotificationCenter
        let name: Notification.Name
        let object: AnyObject?
        
        var observer: NSObjectProtocol?
        
        init(downstream: Downstream, center: NotificationCenter, name: Notification.Name, object: AnyObject?) {
             self.center = center
                       self.name = name
                       self.object = object
            super.init(downstream: downstream)
        }
        
        override func cancel() {
            if let observer = observer {
                center.removeObserver(observer, name: name, object: object)
            }
            super.cancel()
        }
    }
}
