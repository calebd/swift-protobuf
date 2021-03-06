// Sources/protoc-gen-swift/FileIo.swift - File I/O utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Some basic utilities to handle writing to Stderr, Stdout, and reading/writing
/// blocks of data from/to a file on disk.
///
// -----------------------------------------------------------------------------
import Foundation

#if os(Linux)
  import Glibc
#else
  import Darwin.C
#endif

// Alias clib's write() so Stdout.write(bytes:) can call it.
private let _write = write

private func printToFd(_ s: String, fd: Int32, appendNewLine: Bool = true) {
  // Write UTF-8 bytes
  let bytes: [UInt8] = [UInt8](s.utf8)
  bytes.withUnsafeBufferPointer { (bp: UnsafeBufferPointer<UInt8>) -> () in
    write(fd, bp.baseAddress, bp.count)
  }
  if appendNewLine {
    // Write trailing newline
    [UInt8(10)].withUnsafeBufferPointer { (bp: UnsafeBufferPointer<UInt8>) -> () in
      write(fd, bp.baseAddress, bp.count)
    }
  }
}

class Stderr {
  static func print(_ s: String) {
    let out = "protoc-gen-swift: " + s
    printToFd(out, fd: 2)
  }
}

class Stdout {
  static func print(_ s: String) { printToFd(s, fd: 1) }
  static func write(bytes: Data) {
    bytes.withUnsafeBytes { (p: UnsafePointer<UInt8>) -> () in
      _ = _write(1, p, bytes.count)
    }
  }
}

class Stdin {
  static func readall() throws -> Data {
    let fd: Int32 = 0
    let buffSize = 32
    var buff = [UInt8]()
    while true {
      var fragment = [UInt8](repeating: 0, count: buffSize)
      let count = read(fd, &fragment, buffSize)
      if count < 0 {
        throw GenerationError.readFailure
      }
      if count < buffSize {
        buff += fragment[0..<count]
        return Data(bytes: buff)
      }
      buff += fragment
    }
  }
}


func writeFileData(filename: String, data: [UInt8]) throws {
  #if os(Linux)
    _ = try NSData(bytes: data, length: data.count).write(to: URL(fileURLWithPath: filename))
  #else
    _ = try Data(bytes: data).write(to: URL(fileURLWithPath: filename))
  #endif
}

func readFileData(filename: String) throws -> Data {
    return try Data(contentsOf:URL(fileURLWithPath: filename))
}
