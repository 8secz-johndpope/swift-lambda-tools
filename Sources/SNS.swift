//
//  SNS.swift
//  AWSLambdaAdapter
//
//  Created by Kelton Person on 7/4/19.
//

import Foundation
import NIO
import AWSLambdaAdapter
import VaporLambdaAdapter


public protocol SNSRecordMeta {
    
    var eventSource: String { get }
    var eventSubscriptionArn: String { get }
    var unsubscribeUrl: String { get }
    var timestamp: Date { get }
    var message: String { get }
    var topicArn: String { get }
    var subject: String? { get }
    
}

public protocol SNSBodyAttributes {
    
    var message: String { get }
    
}

public struct SNSRecord: SNSRecordMeta, SNSBodyAttributes {
    
    static func createDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        return dateFormatter
    }
    
    public static let formatter = createDateFormatter()
    
    public let eventSource: String
    public let eventSubscriptionArn: String
    public let unsubscribeUrl: String
    public let timestamp: Date
    public let message: String
    public let topicArn: String
    public let messageId: String
    public let subject: String?
    
    public init?(dict: [String : Any]) {
        if
            let eventSource = dict["EventSource"] as? String,
            let eventSubscriptionArn = dict["EventSubscriptionArn"] as? String,
            let snsDict = dict["Sns"] as? [String : Any],
            let unsubscribeUrl = snsDict["UnsubscribeUrl"] as? String,
            let timestampStr = snsDict["Timestamp"] as? String,
            let timestamp = SNSRecord.formatter.date(from: timestampStr),
            let message = snsDict["Message"] as? String,
            let topicArn = snsDict["TopicArn"] as? String,
            let messageId = snsDict["MessageId"] as? String

        {
            self.eventSource = eventSource
            self.eventSubscriptionArn = eventSubscriptionArn
            self.unsubscribeUrl = unsubscribeUrl
            self.timestamp = timestamp
            self.message = message
            self.topicArn = topicArn
            self.messageId = messageId
            self.subject = snsDict["Subject"] as? String
        }
        else {
            return nil
        }
        
    }
    
    
    
}



public typealias SNSPayload = GroupedRecords<EventLoopGroup, SNSRecordMeta, SNSBodyAttributes>

public typealias SNSHandler = (SNSPayload) -> EventLoopFuture<Void>

class SNSLambdaEventHandler: LambdaEventHandler {
    
    let handler: SNSHandler
    
    init(handler: @escaping SNSHandler) {
        self.handler = handler
    }
    
    func handle(
        data: [String: Any],
        eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<[String: Any]> {
        if let records = data["Records"] as? [[String: Any]] {
            let snsRecords = records
                .compactMap { SNSRecord(dict: $0) }
                .map { r in Record<SNSRecordMeta, SNSBodyAttributes>(meta: r, body: r) }
            
            let grouped: SNSPayload = GroupedRecords(context: eventLoopGroup, records: snsRecords)
            return handler(grouped).map { _ in [:] }
        }
        else {
            return eventLoopGroup.eventLoop.newSucceededFuture(result: [:])
        }
    }
}


class SNS {
    
    class func run(handler: @escaping SNSHandler) {
        Custom.run(handler: SNSLambdaEventHandler(handler: handler))
    }
    
}
