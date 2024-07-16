//
//  TTY.swift
//  okgo
//
//  Created by Adam Dilger on 16/7/2024.
//

import Foundation
import Darwin
import AppKit

class TTY: NSObject {
    var task: Process?
    var slaveFile: FileHandle?
    var masterFile: FileHandle?
    
    var buffer: Data
    var command: String

    override init() {
        self.buffer = Data()
        self.command = "";
        self.task = Process()
        var masterFD: Int32 = 0
        masterFD = posix_openpt(O_RDWR)
        grantpt(masterFD)
        unlockpt(masterFD)
        self.masterFile = FileHandle.init(fileDescriptor: masterFD)
        let slavePath = String.init(cString: ptsname(masterFD))
        self.slaveFile = FileHandle.init(forUpdatingAtPath: slavePath)
        self.task!.executableURL = URL(fileURLWithPath: "/bin/sh")
        self.task!.arguments = ["-i"]
        self.task!.standardOutput = slaveFile
        self.task!.standardInput = slaveFile
        self.task!.standardError = slaveFile
    }

    func run() {
        self.masterFile!.readabilityHandler = { handler in
            let cur = self.buffer.count
            self.buffer.append(handler.availableData)
            let a = String(decoding: self.buffer.subdata(in: cur..<self.buffer.count), as: UTF8.self)
            print(a, terminator: "")
        }

        do {
            try self.task!.run()
        } catch {
            print("Something went wrong.\n")
        }
    }
    
    func keyDown(event: NSEvent) {
        let c = event.characters!;
        self.masterFile!.write(c.data(using: String.Encoding.utf8)!)
    }
}
