//
//  URLSessionTaskPublisherDelegate.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

import Foundation

protocol URLSessionTaskPublisherDelegate {
}

extension URLSessionTaskPublisherDelegate {
    
    func handleCompletion<Downstream: Subscriber>(queue: DispatchQueue, subscriber: Subscribers.InternalSink<Downstream, (data: Data, response: HTTPURLResponse), Error>) -> (Data?, URLResponse?, Error?) -> Void {
        
        let completion: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
            
            guard !subscriber.isCancelled else { return }
            
            if let error = error {
                queue.async {
                    subscriber.receive(completion: .failure(error))
                }
                
            } else if let response = response as? HTTPURLResponse, let data = data {
                queue.async {
                    _ = subscriber.receive((data, response))
                    subscriber.receive(completion: .finished)
                }
            }
        }
        
        return completion
    }
}
