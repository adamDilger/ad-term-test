//
//  main.swift
//  ad-term-cli
//
//  Created by Adam Dilger on 15/7/2024.
//

import Foundation

class Hello {
    func start() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        // task.arguments = ["-c", ."ls /Users/adamdilger"]
        task.arguments = ["-c", "/bin/sh -i"]
        
        let nl = "\n".unicodeScalars.first!.value
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            var s = 0;
            
            for i in 0..<data.count {
                if data[i] == nl {
                    print(String(decoding: data.subdata(in: s..<i), as: UTF8.self))
                    s = i + 1
                }
            }
            
            if s == 0 {
                print(String(decoding: data, as: UTF8.self))
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                let o = String(decoding: data, as: UTF8.self)
                print(o, terminator: "")
            }
        }
        
        do {
            try task.run()
        } catch {
            print(error)
        }

        task.waitUntilExit()
    }
}

func peek(d: Data, current: Int, offset: Int = 1) -> UInt8 {
    if d.count < current + offset {
        return 0
    }
    
    return d[current + offset]
}

Hello().start();
