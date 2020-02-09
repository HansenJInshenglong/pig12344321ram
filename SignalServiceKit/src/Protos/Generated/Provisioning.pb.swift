// DO NOT EDIT.
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: Provisioning.proto
//
// For information on using the generated types, please see the documenation:
//   https://github.com/apple/swift-protobuf/

//*
// Copyright (C) 2014-2016 Open Whisper Systems
//
// Licensed according to the LICENSE file in this repository.

/// iOS - since we use a modern proto-compiler, we must specify
/// the legacy proto format.

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that your are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct ProvisioningProtos_ProvisionEnvelope {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// @required
  var publicKey: Data {
    get {return _publicKey ?? SwiftProtobuf.Internal.emptyData}
    set {_publicKey = newValue}
  }
  /// Returns true if `publicKey` has been explicitly set.
  var hasPublicKey: Bool {return self._publicKey != nil}
  /// Clears the value of `publicKey`. Subsequent reads from it will return its default value.
  mutating func clearPublicKey() {self._publicKey = nil}

  /// @required
  var body: Data {
    get {return _body ?? SwiftProtobuf.Internal.emptyData}
    set {_body = newValue}
  }
  /// Returns true if `body` has been explicitly set.
  var hasBody: Bool {return self._body != nil}
  /// Clears the value of `body`. Subsequent reads from it will return its default value.
  mutating func clearBody() {self._body = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _publicKey: Data? = nil
  fileprivate var _body: Data? = nil
}

struct ProvisioningProtos_ProvisionMessage {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var userID: String {
    get {return _userID ?? String()}
    set {_userID = newValue}
  }
  /// Returns true if `userID` has been explicitly set.
  var hasUserID: Bool {return self._userID != nil}
  /// Clears the value of `userID`. Subsequent reads from it will return its default value.
  mutating func clearUserID() {self._userID = nil}

  var provisioningCode: String {
    get {return _provisioningCode ?? String()}
    set {_provisioningCode = newValue}
  }
  /// Returns true if `provisioningCode` has been explicitly set.
  var hasProvisioningCode: Bool {return self._provisioningCode != nil}
  /// Clears the value of `provisioningCode`. Subsequent reads from it will return its default value.
  mutating func clearProvisioningCode() {self._provisioningCode = nil}

  var userAgent: String {
    get {return _userAgent ?? String()}
    set {_userAgent = newValue}
  }
  /// Returns true if `userAgent` has been explicitly set.
  var hasUserAgent: Bool {return self._userAgent != nil}
  /// Clears the value of `userAgent`. Subsequent reads from it will return its default value.
  mutating func clearUserAgent() {self._userAgent = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _userID: String? = nil
  fileprivate var _provisioningCode: String? = nil
  fileprivate var _userAgent: String? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "ProvisioningProtos"

extension ProvisioningProtos_ProvisionEnvelope: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ProvisionEnvelope"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "publicKey"),
    2: .same(proto: "body"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularBytesField(value: &self._publicKey)
      case 2: try decoder.decodeSingularBytesField(value: &self._body)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._publicKey {
      try visitor.visitSingularBytesField(value: v, fieldNumber: 1)
    }
    if let v = self._body {
      try visitor.visitSingularBytesField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProvisioningProtos_ProvisionEnvelope, rhs: ProvisioningProtos_ProvisionEnvelope) -> Bool {
    if lhs._publicKey != rhs._publicKey {return false}
    if lhs._body != rhs._body {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProvisioningProtos_ProvisionMessage: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ProvisionMessage"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "userId"),
    2: .same(proto: "provisioningCode"),
    3: .same(proto: "userAgent"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularStringField(value: &self._userID)
      case 2: try decoder.decodeSingularStringField(value: &self._provisioningCode)
      case 3: try decoder.decodeSingularStringField(value: &self._userAgent)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._userID {
      try visitor.visitSingularStringField(value: v, fieldNumber: 1)
    }
    if let v = self._provisioningCode {
      try visitor.visitSingularStringField(value: v, fieldNumber: 2)
    }
    if let v = self._userAgent {
      try visitor.visitSingularStringField(value: v, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProvisioningProtos_ProvisionMessage, rhs: ProvisioningProtos_ProvisionMessage) -> Bool {
    if lhs._userID != rhs._userID {return false}
    if lhs._provisioningCode != rhs._provisioningCode {return false}
    if lhs._userAgent != rhs._userAgent {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
