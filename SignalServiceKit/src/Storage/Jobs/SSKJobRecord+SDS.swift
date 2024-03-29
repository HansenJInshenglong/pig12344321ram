//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import GRDBCipher
import SignalCoreKit

// NOTE: This file is generated by /Scripts/sds_codegen/sds_generate.py.
// Do not manually edit it, instead run `sds_codegen.sh`.

// MARK: - Record

public struct JobRecordRecord: SDSRecord {
    public var tableMetadata: SDSTableMetadata {
        return SSKJobRecordSerializer.table
    }

    public static let databaseTableName: String = SSKJobRecordSerializer.table.tableName

    public var id: Int64?

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    public let recordType: SDSRecordType
    public let uniqueId: String

    // Base class properties
    public let failureCount: UInt
    public let label: String
    public let status: SSKJobRecordStatus

    // Subclass properties
    public let attachmentIdMap: Data?
    public let contactThreadId: String?
    public let envelopeData: Data?
    public let invisibleMessage: Data?
    public let messageId: String?
    public let removeMessageAfterSending: Bool?
    public let threadId: String?

    public enum CodingKeys: String, CodingKey, ColumnExpression, CaseIterable {
        case id
        case recordType
        case uniqueId
        case failureCount
        case label
        case status
        case attachmentIdMap
        case contactThreadId
        case envelopeData
        case invisibleMessage
        case messageId
        case removeMessageAfterSending
        case threadId
    }

    public static func columnName(_ column: JobRecordRecord.CodingKeys, fullyQualified: Bool = false) -> String {
        return fullyQualified ? "\(databaseTableName).\(column.rawValue)" : column.rawValue
    }
}

// MARK: - Row Initializer

public extension JobRecordRecord {
    static var databaseSelection: [SQLSelectable] {
        return CodingKeys.allCases
    }

    init(row: Row) {
        id = row[0]
        recordType = row[1]
        uniqueId = row[2]
        failureCount = row[3]
        label = row[4]
        status = row[5]
        attachmentIdMap = row[6]
        contactThreadId = row[7]
        envelopeData = row[8]
        invisibleMessage = row[9]
        messageId = row[10]
        removeMessageAfterSending = row[11]
        threadId = row[12]
    }
}

// MARK: - StringInterpolation

public extension String.StringInterpolation {
    mutating func appendInterpolation(jobRecordColumn column: JobRecordRecord.CodingKeys) {
        appendLiteral(JobRecordRecord.columnName(column))
    }
    mutating func appendInterpolation(jobRecordColumnFullyQualified column: JobRecordRecord.CodingKeys) {
        appendLiteral(JobRecordRecord.columnName(column, fullyQualified: true))
    }
}

// MARK: - Deserialization

// TODO: Rework metadata to not include, for example, columns, column indices.
extension SSKJobRecord {
    // This method defines how to deserialize a model, given a
    // database row.  The recordType column is used to determine
    // the corresponding model class.
    class func fromRecord(_ record: JobRecordRecord) throws -> SSKJobRecord {

        guard let recordId = record.id else {
            throw SDSError.invalidValue
        }

        switch record.recordType {
        case .broadcastMediaMessageJobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = UInt64(recordId)
            let status: SSKJobRecordStatus = record.status
            let attachmentIdMapSerialized: Data? = record.attachmentIdMap
            let attachmentIdMap: [String: [String]] = try SDSDeserialization.unarchive(attachmentIdMapSerialized, name: "attachmentIdMap")

            return OWSBroadcastMediaMessageJobRecord(uniqueId: uniqueId,
                                                     failureCount: failureCount,
                                                     label: label,
                                                     sortId: sortId,
                                                     status: status,
                                                     attachmentIdMap: attachmentIdMap)

        case .sessionResetJobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = UInt64(recordId)
            let status: SSKJobRecordStatus = record.status
            let contactThreadId: String = try SDSDeserialization.required(record.contactThreadId, name: "contactThreadId")

            return OWSSessionResetJobRecord(uniqueId: uniqueId,
                                            failureCount: failureCount,
                                            label: label,
                                            sortId: sortId,
                                            status: status,
                                            contactThreadId: contactThreadId)

        case .jobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = UInt64(recordId)
            let status: SSKJobRecordStatus = record.status

            return SSKJobRecord(uniqueId: uniqueId,
                                failureCount: failureCount,
                                label: label,
                                sortId: sortId,
                                status: status)

        case .messageDecryptJobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = UInt64(recordId)
            let status: SSKJobRecordStatus = record.status
            let envelopeData: Data? = SDSDeserialization.optionalData(record.envelopeData, name: "envelopeData")

            return SSKMessageDecryptJobRecord(uniqueId: uniqueId,
                                              failureCount: failureCount,
                                              label: label,
                                              sortId: sortId,
                                              status: status,
                                              envelopeData: envelopeData)

        case .messageSenderJobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = UInt64(recordId)
            let status: SSKJobRecordStatus = record.status
            let invisibleMessageSerialized: Data? = record.invisibleMessage
            let invisibleMessage: TSOutgoingMessage? = try SDSDeserialization.optionalUnarchive(invisibleMessageSerialized, name: "invisibleMessage")
            let messageId: String? = record.messageId
            let removeMessageAfterSending: Bool = try SDSDeserialization.required(record.removeMessageAfterSending, name: "removeMessageAfterSending")
            let threadId: String? = record.threadId

            return SSKMessageSenderJobRecord(uniqueId: uniqueId,
                                             failureCount: failureCount,
                                             label: label,
                                             sortId: sortId,
                                             status: status,
                                             invisibleMessage: invisibleMessage,
                                             messageId: messageId,
                                             removeMessageAfterSending: removeMessageAfterSending,
                                             threadId: threadId)

        default:
            owsFailDebug("Unexpected record type: \(record.recordType)")
            throw SDSError.invalidValue
        }
    }
}

// MARK: - SDSModel

extension SSKJobRecord: SDSModel {
    public var serializer: SDSSerializer {
        // Any subclass can be cast to it's superclass,
        // so the order of this switch statement matters.
        // We need to do a "depth first" search by type.
        switch self {
        case let model as SSKMessageSenderJobRecord:
            assert(type(of: model) == SSKMessageSenderJobRecord.self)
            return SSKMessageSenderJobRecordSerializer(model: model)
        case let model as SSKMessageDecryptJobRecord:
            assert(type(of: model) == SSKMessageDecryptJobRecord.self)
            return SSKMessageDecryptJobRecordSerializer(model: model)
        case let model as OWSSessionResetJobRecord:
            assert(type(of: model) == OWSSessionResetJobRecord.self)
            return OWSSessionResetJobRecordSerializer(model: model)
        case let model as OWSBroadcastMediaMessageJobRecord:
            assert(type(of: model) == OWSBroadcastMediaMessageJobRecord.self)
            return OWSBroadcastMediaMessageJobRecordSerializer(model: model)
        default:
            return SSKJobRecordSerializer(model: self)
        }
    }

    public func asRecord() throws -> SDSRecord {
        return try serializer.asRecord()
    }

    public var sdsTableName: String {
        return JobRecordRecord.databaseTableName
    }

    public static var table: SDSTableMetadata {
        return SSKJobRecordSerializer.table
    }
}

// MARK: - Table Metadata

extension SSKJobRecordSerializer {

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    static let idColumn = SDSColumnMetadata(columnName: "id", columnType: .primaryKey, columnIndex: 0)
    static let recordTypeColumn = SDSColumnMetadata(columnName: "recordType", columnType: .int64, columnIndex: 1)
    static let uniqueIdColumn = SDSColumnMetadata(columnName: "uniqueId", columnType: .unicodeString, columnIndex: 2)
    // Base class properties
    static let failureCountColumn = SDSColumnMetadata(columnName: "failureCount", columnType: .int64, columnIndex: 3)
    static let labelColumn = SDSColumnMetadata(columnName: "label", columnType: .unicodeString, columnIndex: 4)
    static let statusColumn = SDSColumnMetadata(columnName: "status", columnType: .int, columnIndex: 5)
    // Subclass properties
    static let attachmentIdMapColumn = SDSColumnMetadata(columnName: "attachmentIdMap", columnType: .blob, isOptional: true, columnIndex: 6)
    static let contactThreadIdColumn = SDSColumnMetadata(columnName: "contactThreadId", columnType: .unicodeString, isOptional: true, columnIndex: 7)
    static let envelopeDataColumn = SDSColumnMetadata(columnName: "envelopeData", columnType: .blob, isOptional: true, columnIndex: 8)
    static let invisibleMessageColumn = SDSColumnMetadata(columnName: "invisibleMessage", columnType: .blob, isOptional: true, columnIndex: 9)
    static let messageIdColumn = SDSColumnMetadata(columnName: "messageId", columnType: .unicodeString, isOptional: true, columnIndex: 10)
    static let removeMessageAfterSendingColumn = SDSColumnMetadata(columnName: "removeMessageAfterSending", columnType: .int, isOptional: true, columnIndex: 11)
    static let threadIdColumn = SDSColumnMetadata(columnName: "threadId", columnType: .unicodeString, isOptional: true, columnIndex: 12)

    // TODO: We should decide on a naming convention for
    //       tables that store models.
    public static let table = SDSTableMetadata(collection: SSKJobRecord.collection(),
                                               tableName: "model_SSKJobRecord",
                                               columns: [
        idColumn,
        recordTypeColumn,
        uniqueIdColumn,
        failureCountColumn,
        labelColumn,
        statusColumn,
        attachmentIdMapColumn,
        contactThreadIdColumn,
        envelopeDataColumn,
        invisibleMessageColumn,
        messageIdColumn,
        removeMessageAfterSendingColumn,
        threadIdColumn,
        ])
}

// MARK: - Save/Remove/Update

@objc
public extension SSKJobRecord {
    func anyInsert(transaction: SDSAnyWriteTransaction) {
        sdsSave(saveMode: .insert, transaction: transaction)
    }

    // This method is private; we should never use it directly.
    // Instead, use anyUpdate(transaction:block:), so that we
    // use the "update with" pattern.
    private func anyUpdate(transaction: SDSAnyWriteTransaction) {
        sdsSave(saveMode: .update, transaction: transaction)
    }

    @available(*, deprecated, message: "Use anyInsert() or anyUpdate() instead.")
    func anyUpsert(transaction: SDSAnyWriteTransaction) {
        let isInserting: Bool
        if SSKJobRecord.anyFetch(uniqueId: uniqueId, transaction: transaction) != nil {
            isInserting = false
        } else {
            isInserting = true
        }
        sdsSave(saveMode: isInserting ? .insert : .update, transaction: transaction)
    }

    // This method is used by "updateWith..." methods.
    //
    // This model may be updated from many threads. We don't want to save
    // our local copy (this instance) since it may be out of date.  We also
    // want to avoid re-saving a model that has been deleted.  Therefore, we
    // use "updateWith..." methods to:
    //
    // a) Update a property of this instance.
    // b) If a copy of this model exists in the database, load an up-to-date copy,
    //    and update and save that copy.
    // b) If a copy of this model _DOES NOT_ exist in the database, do _NOT_ save
    //    this local instance.
    //
    // After "updateWith...":
    //
    // a) Any copy of this model in the database will have been updated.
    // b) The local property on this instance will always have been updated.
    // c) Other properties on this instance may be out of date.
    //
    // All mutable properties of this class have been made read-only to
    // prevent accidentally modifying them directly.
    //
    // This isn't a perfect arrangement, but in practice this will prevent
    // data loss and will resolve all known issues.
    func anyUpdate(transaction: SDSAnyWriteTransaction, block: (SSKJobRecord) -> Void) {

        block(self)

        guard let dbCopy = type(of: self).anyFetch(uniqueId: uniqueId,
                                                   transaction: transaction) else {
            return
        }

        // Don't apply the block twice to the same instance.
        // It's at least unnecessary and actually wrong for some blocks.
        // e.g. `block: { $0 in $0.someField++ }`
        if dbCopy !== self {
            block(dbCopy)
        }

        dbCopy.anyUpdate(transaction: transaction)
    }

    func anyRemove(transaction: SDSAnyWriteTransaction) {
        sdsRemove(transaction: transaction)
    }

    func anyReload(transaction: SDSAnyReadTransaction) {
        anyReload(transaction: transaction, ignoreMissing: false)
    }

    func anyReload(transaction: SDSAnyReadTransaction, ignoreMissing: Bool) {
        guard let latestVersion = type(of: self).anyFetch(uniqueId: uniqueId, transaction: transaction) else {
            if !ignoreMissing {
                owsFailDebug("`latest` was unexpectedly nil")
            }
            return
        }

        setValuesForKeys(latestVersion.dictionaryValue)
    }
}

// MARK: - SSKJobRecordCursor

@objc
public class SSKJobRecordCursor: NSObject {
    private let cursor: RecordCursor<JobRecordRecord>?

    init(cursor: RecordCursor<JobRecordRecord>?) {
        self.cursor = cursor
    }

    public func next() throws -> SSKJobRecord? {
        guard let cursor = cursor else {
            return nil
        }
        guard let record = try cursor.next() else {
            return nil
        }
        return try SSKJobRecord.fromRecord(record)
    }

    public func all() throws -> [SSKJobRecord] {
        var result = [SSKJobRecord]()
        while true {
            guard let model = try next() else {
                break
            }
            result.append(model)
        }
        return result
    }
}

// MARK: - Obj-C Fetch

// TODO: We may eventually want to define some combination of:
//
// * fetchCursor, fetchOne, fetchAll, etc. (ala GRDB)
// * Optional "where clause" parameters for filtering.
// * Async flavors with completions.
//
// TODO: I've defined flavors that take a read transaction.
//       Or we might take a "connection" if we end up having that class.
@objc
public extension SSKJobRecord {
    class func grdbFetchCursor(transaction: GRDBReadTransaction) -> SSKJobRecordCursor {
        let database = transaction.database
        do {
            let cursor = try JobRecordRecord.fetchCursor(database)
            return SSKJobRecordCursor(cursor: cursor)
        } catch {
            owsFailDebug("Read failed: \(error)")
            return SSKJobRecordCursor(cursor: nil)
        }
    }

    // Fetches a single model by "unique id".
    class func anyFetch(uniqueId: String,
                        transaction: SDSAnyReadTransaction) -> SSKJobRecord? {
        assert(uniqueId.count > 0)

        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            return SSKJobRecord.ydb_fetch(uniqueId: uniqueId, transaction: ydbTransaction)
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT * FROM \(JobRecordRecord.databaseTableName) WHERE \(jobRecordColumn: .uniqueId) = ?"
            return grdbFetchOne(sql: sql, arguments: [uniqueId], transaction: grdbTransaction)
        }
    }

    // Traverses all records.
    // Records are not visited in any particular order.
    // Traversal aborts if the visitor returns false.
    class func anyEnumerate(transaction: SDSAnyReadTransaction, block: @escaping (SSKJobRecord, UnsafeMutablePointer<ObjCBool>) -> Void) {
        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            SSKJobRecord.ydb_enumerateCollectionObjects(with: ydbTransaction) { (object, stop) in
                guard let value = object as? SSKJobRecord else {
                    owsFailDebug("unexpected object: \(type(of: object))")
                    return
                }
                block(value, stop)
            }
        case .grdbRead(let grdbTransaction):
            do {
                let cursor = SSKJobRecord.grdbFetchCursor(transaction: grdbTransaction)
                var stop: ObjCBool = false
                while let value = try cursor.next() {
                    block(value, &stop)
                    guard !stop.boolValue else {
                        break
                    }
                }
            } catch let error {
                owsFailDebug("Couldn't fetch models: \(error)")
            }
        }
    }

    // Traverses all records' unique ids.
    // Records are not visited in any particular order.
    // Traversal aborts if the visitor returns false.
    class func anyEnumerateUniqueIds(transaction: SDSAnyReadTransaction, block: @escaping (String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            ydbTransaction.enumerateKeys(inCollection: SSKJobRecord.collection()) { (uniqueId, stop) in
                block(uniqueId, stop)
            }
        case .grdbRead(let grdbTransaction):
            grdbEnumerateUniqueIds(transaction: grdbTransaction,
                                   sql: """
                    SELECT \(jobRecordColumn: .uniqueId)
                    FROM \(JobRecordRecord.databaseTableName)
                """,
                block: block)
        }
    }

    // Does not order the results.
    class func anyFetchAll(transaction: SDSAnyReadTransaction) -> [SSKJobRecord] {
        var result = [SSKJobRecord]()
        anyEnumerate(transaction: transaction) { (model, _) in
            result.append(model)
        }
        return result
    }

    // Does not order the results.
    class func anyAllUniqueIds(transaction: SDSAnyReadTransaction) -> [String] {
        var result = [String]()
        anyEnumerateUniqueIds(transaction: transaction) { (uniqueId, _) in
            result.append(uniqueId)
        }
        return result
    }

    class func anyCount(transaction: SDSAnyReadTransaction) -> UInt {
        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            return ydbTransaction.numberOfKeys(inCollection: SSKJobRecord.collection())
        case .grdbRead(let grdbTransaction):
            return JobRecordRecord.ows_fetchCount(grdbTransaction.database)
        }
    }

    // WARNING: Do not use this method for any models which do cleanup
    //          in their anyWillRemove(), anyDidRemove() methods.
    class func anyRemoveAllWithoutInstantation(transaction: SDSAnyWriteTransaction) {
        switch transaction.writeTransaction {
        case .yapWrite(let ydbTransaction):
            ydbTransaction.removeAllObjects(inCollection: SSKJobRecord.collection())
        case .grdbWrite(let grdbTransaction):
            do {
                try JobRecordRecord.deleteAll(grdbTransaction.database)
            } catch {
                owsFailDebug("deleteAll() failed: \(error)")
            }
        }

        if shouldBeIndexedForFTS {
            FullTextSearchFinder.allModelsWereRemoved(collection: collection(), transaction: transaction)
        }
    }

    class func anyRemoveAllWithInstantation(transaction: SDSAnyWriteTransaction) {
        // To avoid mutationDuringEnumerationException, we need
        // to remove the instances outside the enumeration.
        let uniqueIds = anyAllUniqueIds(transaction: transaction)
        for uniqueId in uniqueIds {
            guard let instance = anyFetch(uniqueId: uniqueId, transaction: transaction) else {
                owsFailDebug("Missing instance.")
                continue
            }
            instance.anyRemove(transaction: transaction)
        }

        if shouldBeIndexedForFTS {
            FullTextSearchFinder.allModelsWereRemoved(collection: collection(), transaction: transaction)
        }
    }

    class func anyExists(uniqueId: String,
                        transaction: SDSAnyReadTransaction) -> Bool {
        assert(uniqueId.count > 0)

        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            return ydbTransaction.hasObject(forKey: uniqueId, inCollection: SSKJobRecord.collection())
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT EXISTS ( SELECT 1 FROM \(JobRecordRecord.databaseTableName) WHERE \(jobRecordColumn: .uniqueId) = ? )"
            let arguments: StatementArguments = [uniqueId]
            return try! Bool.fetchOne(grdbTransaction.database, sql: sql, arguments: arguments) ?? false
        }
    }
}

// MARK: - Swift Fetch

public extension SSKJobRecord {
    class func grdbFetchCursor(sql: String,
                               arguments: StatementArguments = StatementArguments(),
                               transaction: GRDBReadTransaction) -> SSKJobRecordCursor {
        do {
            let sqlRequest = SQLRequest<Void>(sql: sql, arguments: arguments, cached: true)
            let cursor = try JobRecordRecord.fetchCursor(transaction.database, sqlRequest)
            return SSKJobRecordCursor(cursor: cursor)
        } catch {
            Logger.error("sql: \(sql)")
            owsFailDebug("Read failed: \(error)")
            return SSKJobRecordCursor(cursor: nil)
        }
    }

    class func grdbFetchOne(sql: String,
                            arguments: StatementArguments = StatementArguments(),
                            transaction: GRDBReadTransaction) -> SSKJobRecord? {
        assert(sql.count > 0)

        do {
            let sqlRequest = SQLRequest<Void>(sql: sql, arguments: arguments, cached: true)
            guard let record = try JobRecordRecord.fetchOne(transaction.database, sqlRequest) else {
                return nil
            }

            return try SSKJobRecord.fromRecord(record)
        } catch {
            owsFailDebug("error: \(error)")
            return nil
        }
    }
}

// MARK: - SDSSerializer

// The SDSSerializer protocol specifies how to insert and update the
// row that corresponds to this model.
class SSKJobRecordSerializer: SDSSerializer {

    private let model: SSKJobRecord
    public required init(model: SSKJobRecord) {
        self.model = model
    }

    // MARK: - Record

    func asRecord() throws -> SDSRecord {
        let id: Int64? = nil

        let recordType: SDSRecordType = .jobRecord
        let uniqueId: String = model.uniqueId

        // Base class properties
        let failureCount: UInt = model.failureCount
        let label: String = model.label
        let status: SSKJobRecordStatus = model.status

        // Subclass properties
        let attachmentIdMap: Data? = nil
        let contactThreadId: String? = nil
        let envelopeData: Data? = nil
        let invisibleMessage: Data? = nil
        let messageId: String? = nil
        let removeMessageAfterSending: Bool? = nil
        let threadId: String? = nil

        return JobRecordRecord(id: id, recordType: recordType, uniqueId: uniqueId, failureCount: failureCount, label: label, status: status, attachmentIdMap: attachmentIdMap, contactThreadId: contactThreadId, envelopeData: envelopeData, invisibleMessage: invisibleMessage, messageId: messageId, removeMessageAfterSending: removeMessageAfterSending, threadId: threadId)
    }
}
                                               