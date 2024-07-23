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
//    var term: termios;
//    var size: winsize;

    init() {
        self.buffer = Data()
        self.command = "";
        self.lines = [line(start: 0, end: 0)]
        self.task = Process()
//        var masterFD: Int32 = 0
//        masterFD = posix_openpt(O_RDWR)
//        grantpt(masterFD)
//        unlockpt(masterFD)
//        self.masterFile = FileHandle.init(fileDescriptor: masterFD)
//        let slavePath = String.init(cString: ptsname(masterFD))
//        self.slaveFile = FileHandle.init(forUpdatingAtPath: slavePath)
//        self.task!.executableURL = URL(fileURLWithPath: "/bin/bash")
//        self.task!.arguments = ["-i"]
//        self.task!.standardOutput = slaveFile
//        self.task!.standardInput = slaveFile
//        self.task!.standardError = slaveFile
        
        
        // Setup the PTY handles
        // var parentDescriptor: Int32 = 0
        // var childDescriptor: Int32 = 0
//        guard openpty(&parentDescriptor, &childDescriptor, nil, nil, nil) != -1 else {
//          fatalError("Failed to spawn PTY")
//        }
        
//        var parentDescriptor: UnsafeMutablePointer<Int32> = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
//        var childDescriptor: UnsafeMutablePointer<Int32> = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
//        var childName: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 100)
//        
//        self.t = UnsafeMutablePointer<termios>.allocate(capacity: 1);
//        self.ws = UnsafeMutablePointer<winsize>.allocate(capacity: 1);
////        guard forkpty(parentDescriptor, &childName, t, ws) != -1 else {
////            fatalError("Failed to spawn PTY")
////        }
//        guard openpty(parentDescriptor, childDescriptor, childName, &self.t.pointee, &self.ws.pointee) != -1 else {
//            fatalError("Failed to spawn PTY")
//        }
        
        var temp = Array<CChar>(repeating: 0, count: Int(PATH_MAX))
        var masterFD = Int32(-1)
        var slaveFD = Int32(-1)
        //self.term = termios();
        //self.term.c_lflag |= UInt(ECHO);
        //self.size = winsize();
        
        guard openpty(&masterFD, &slaveFD, &temp, nil, nil) != -1 else {
            fatalError("failed to open pty")
        }
        
        
        self.masterFile = FileHandle.init(fileDescriptor: masterFD)
        self.slaveFile = FileHandle.init(fileDescriptor: slaveFD)
//       print(login_tty(childDescriptor));
//        
//        self.task!.executableURL = URL(fileURLWithPath: "/usr/bin/login")
//        self.task!.arguments = ["-fpl", "adamdilger", "/bin/zsh", "-c", "/bin/sh"]
        
        self.task!.executableURL = URL(fileURLWithPath: "/bin/bash")
        self.task!.arguments = ["-i"]
        self.task!.standardOutput = slaveFile
        self.task!.standardInput = slaveFile
        self.task!.standardError = slaveFile
    }
    

    func newLine(at: Int) {
        self.lines.append(line(start: at + 1, end: at + 1))
    }
    
    func run(nc: NotificationCenter) {
        //let tmp = FileHandle.init(forUpdatingAtPath: "helloworld.txt");
        
        self.masterFile!.readabilityHandler = { handler in
            let cur = self.buffer.count
             
            let data = handler.availableData;
            
//            tmp!.write(data);
//            do {
//                try tmp!.synchronize()
//            } catch {
//                print(error);
//            }
            
            // print(String(decoding: data, as: UTF8.self))
            
            self.buffer.append(data)
            let r = cur..<self.buffer.count;
            
            // let a = String(decoding: self.buffer.subdata(in: r), as: UTF8.self)
            // print(a, terminator: "")
            
            // parse output to determine lines
            let nl = Character("\n").asciiValue
            let bs: UInt8 = 8;

            for i in r {
                self.lines[self.lines.count - 1].end += 1;
                let b = self.buffer[i];
                if (self.buffer[i] == nl) {
                    self.newLine(at: i);
                }
                else if (b == bs) {
                    self.newLine(at: i);
                }
            }
            
            nc.post(name: Notification.Name("TerminalDataUpdate"), object: (self.buffer, self.lines))
        }

        do {
            try self.task!.run()
        } catch {
            print("Something went wrong.\(error)\n")
        }
    }
    
    func keyDown(event: NSEvent) {
        let c = event.characters!;
        self.masterFile!.write(c.data(using: .utf8)!)
    }
}
