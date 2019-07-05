//
//  SQS.swift
//  SwiftAWS
//
//  Created by Kelton Person on 6/29/19.
//

import Foundation
import AWSLambdaAdapter
import NIO
import VaporLambdaAdapter


public typealias SQSHandler = (SQSPayload) -> EventLoopFuture<Void>


public struct SQSMessageAttributeValue {
    let binaryListValues: [Data]
    let binaryValue: Data?
    
    let stringValue: String?
    let stringListValues: [String]
    
    let dataType: String
    
    public init?(dict: [String : Any]) {
        if let dataType = dict["dataType"] as? String {
            self.dataType = dataType
            
            self.binaryValue = (dict["binaryValue"] as? String)
                .flatMap { Data(base64URLEncoded: $0, options: []) }
            self.binaryListValues = (dict["binaryListValues"] as? [String] ?? [])
                .compactMap { Data(base64URLEncoded: $0, options: []) }

            self.stringValue = dict["stringValue"] as? String
            self.stringListValues = dict["stringListValues"] as? [String] ?? []
        }
        else {
            return nil
        }
    }
}

public extension SQSMessageAttributeValue {
    
    var numberValue: Decimal? {
        if let str = stringValue, dataType.starts(with: "Number.") || dataType == "Number" {
            return Decimal(string: str)
        }
        else {
            return nil
        }
    }
    
    var numberListValues: [Decimal] {
        if dataType.starts(with: "Number.") || dataType == "Number" {
            return stringListValues.compactMap { Decimal(string: $0) }
        }
        else {
            return []
        }
    }
    
}


public protocol SQSRecordMeta {
    
    var awsRegion: String { get }
    var eventSource: String { get }
    var receiptHandle: String { get }
    var messageId: String { get }
    var eventSourceARN: String { get }
    var senderId: String { get }
    var sentTimestamp: Date { get }
    var approximateFirstReceiveTimestamp: Date { get }
    var approximateReceiveCount: Int {get }
    
}

public protocol SQSBodyAttributes {

    var messageAttributes: [String : SQSMessageAttributeValue] { get }
    var body: String { get }

}

public struct SQSRecord: SQSRecordMeta, SQSBodyAttributes {

    public let body: String
    public let awsRegion: String
    public let eventSource: String
    public let receiptHandle: String
    public let messageId: String
    public let eventSourceARN: String
    public let senderId: String
    public let sentTimestamp: Date
    public let approximateFirstReceiveTimestamp: Date
    public let approximateReceiveCount: Int
    public let messageAttributes: [String : SQSMessageAttributeValue]

    
    public init?(dict: [String : Any]) {
        if
            let body = SQSRecord.extractRootKey(dict: dict, key: "body"),
            let awsRegion = SQSRecord.extractRootKey(dict: dict, key: "awsRegion"),
            let eventSource = SQSRecord.extractRootKey(dict: dict, key: "eventSource"),
            let receiptHandle = SQSRecord.extractRootKey(dict: dict, key: "receiptHandle"),
            let messageId = SQSRecord.extractRootKey(dict: dict, key: "messageId"),
            let eventSourceARN = SQSRecord.extractRootKey(dict: dict, key: "eventSourceARN"),
            let attributes = dict["attributes"] as? [String : Any],
            let senderId = SQSRecord.extractRootKey(dict: attributes, key: "SenderId"),
            let sentTimestamp = SQSRecord.extactUnixTime(dict: attributes, key: "SentTimestamp"),
            let approximateFirstReceiveTimestamp = SQSRecord.extactUnixTime(dict: attributes, key: "ApproximateFirstReceiveTimestamp"),
            let approximateReceiveCountStr = SQSRecord.extractRootKey(dict: attributes, key: "ApproximateReceiveCount"),
            let approximateReceiveCount = Int(approximateReceiveCountStr)
        {
            self.body = body
            self.awsRegion = awsRegion
            self.eventSource = eventSource
            self.receiptHandle = receiptHandle
            self.messageId = messageId
            self.eventSourceARN = eventSourceARN
            self.senderId = senderId
            self.sentTimestamp = sentTimestamp
            self.approximateFirstReceiveTimestamp = approximateFirstReceiveTimestamp
            self.approximateReceiveCount = approximateReceiveCount
            
            let messageAttributesDict = dict["messageAttributes"] as? [String : [String: Any]] ?? [:]
            let messageAttributePairs = messageAttributesDict.compactMap { arg -> (String, SQSMessageAttributeValue)? in
                let (k, v) = arg
                if let ma = SQSMessageAttributeValue(dict: v) {
                    return (k, ma)
                }
                else {
                    return nil
                }
            }
            self.messageAttributes = Dictionary(uniqueKeysWithValues: messageAttributePairs)

        }
        else {
            return nil
        }
    }
    
    static func extractRootKey(dict: [String : Any], key: String) -> String? {
        return dict[key] as? String
    }
    
    static func extactUnixTime(dict: [String : Any], key: String) -> Date? {
        if  let timestampStr = SQSRecord.extractRootKey(dict: dict, key: key),
            let timestampMilli = TimeInterval(timestampStr) {
            return Date(timeIntervalSince1970: timestampMilli / TimeInterval(1000))
        }
        else {
            return nil
        }
    }
    
}




public typealias SQSPayload = GroupedRecords<EventLoopGroup, SQSRecordMeta, SQSBodyAttributes>


class SQS {
    
    class func run(handler: @escaping SQSHandler) {
        Custom.run(handler: SQSLambdaEventHandler(handler: handler))
    }
    
}


class SQSLambdaEventHandler: LambdaEventHandler {
    
    let handler: SQSHandler
    
    init(handler: @escaping SQSHandler) {
        self.handler = handler
    }
    
    func handle(
        data: [String: Any],
        eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<[String: Any]> {
        if let records = data["Records"] as? [[String: Any]] {
            let sqsRecords = records
                .compactMap { SQSRecord(dict: $0) }
                .map { r in Record<SQSRecordMeta, SQSBodyAttributes>(meta: r, body: r) }
            
            let grouped: SQSPayload = GroupedRecords(context: eventLoopGroup, records: sqsRecords)
            return handler(grouped).map { _ in [:] }
        }
        else {
            return eventLoopGroup.eventLoop.newSucceededFuture(result: [:])
        }
    }
}