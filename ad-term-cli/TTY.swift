//
//  TTY.swift
//  ad-term-cli
//
//  Created by Adam Dilger on 16/7/2024.
//

import Foundation
import Darwin
import AppKit

struct line {
    var start: Int;
    var end: Int;
}

class TTY {
    var task: Process?
    var slaveFile: FileHandle?
    var masterFile: FileHandle?
    
    var buffer: Data
    var command: String
    
    var lines: Array<line>;

    init() {
        self.buffer = Data()
        self.command = "";
        self.lines = [line(start: 0, end: 0)]
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

    func run(nc: NotificationCenter) {
        self.masterFile!.readabilityHandler = { handler in
            let cur = self.buffer.count
             
            let data = handler.availableData;
            
            self.buffer.append(data)
            let r = cur..<self.buffer.count;
            
//            let a = String(decoding: self.buffer.subdata(in: r), as: UTF8.self)
//            print(a, terminator: "")
            
            // parse output to determine lines
            let nl = Character("\n").asciiValue
            let bs: UInt8 = 8;

            for i in r {
                self.lines[self.lines.count - 1].end += 1;
                let b = self.buffer[i];
                if (self.buffer[i] == nl) {
                    self.lines.append(line(start: i + 1, end: i + 1))
                }
                else if (b == bs) {
                    self.lines.append(line(start: i + 1, end: i + 1))
                }
            }
            
            nc.post(name: Notification.Name("TerminalDataUpdate"), object: (self.buffer, self.lines))
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
