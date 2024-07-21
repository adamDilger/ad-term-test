//
//  ViewController.swift
//  ad-term-cli
//
//  Created by Adam Dilger on 16/7/2024.
//

import Cocoa

struct Cell {
    var char: Character?;
}

let WIDTH = 100;
let HEIGHT = 10;

// --------
let backspace = Character("\u{8}").asciiValue!;
let newline = Character("\n").asciiValue!;
let carriagereturn = Character("\r").asciiValue!;
let ESC = Character("\u{1b}").asciiValue!;
let L_SQUARE = Character("[").asciiValue!;
let ASC_J = Character("J").asciiValue!;
let ASC_H = Character("H").asciiValue!;
let ASC_0 = Character("0").asciiValue!;
let ASC_1 = Character("1").asciiValue!;
let ASC_2 = Character("2").asciiValue!;
let ASC_3 = Character("3").asciiValue!;
let ASC_9 = Character("9").asciiValue!;
// --------

class Terminal {
    var cells = Array<Cell>();
    var currentLineIndex = 0;
    
    init() {
        for _ in 0..<WIDTH*HEIGHT {
            self.cells.append(Cell())
        }
    }
    
    func clearRow(idx: Int) {
        for i in (WIDTH*idx)..<(WIDTH*(idx+1)) {
            self.cells[i].char = nil;
        }
    }
    
    func draw(data: Data, lineBuffer: Array<line>) {
        var x = 0;
        var y = 0;
        self.currentLineIndex = 0;
        
        for i in 0..<HEIGHT {
            self.clearRow(idx: i) // needed?
        }
        
        for line in lineBuffer {
            let s = line.start;
            let e = line.end;
            
            var idx = s;
            while idx < e {
                let b = data[idx];
                let bc = Character(UnicodeScalar(b))
                
                if b == ESC {
                    let peek = data[idx + 1];
                    if peek == L_SQUARE {
                        idx += 1;
                        self.readControlCode(data: data, idx: &idx, x: &x, y: &y);
                        self.currentLineIndex = 0;
                    }
                } else if b == newline {
                    x = 0;
                    if y + 1 == HEIGHT {
                        y = 0;
                    } else {
                        y += 1;
                    }
                    self.currentLineIndex += 1;
                    self.clearRow(idx: y);
                } else if b == carriagereturn {
                    x = 0;
                } else if b == backspace {
                    x -= 1;
                } else {
                    self.cells[x + (y * WIDTH)].char = bc
                    
                    if x + 1 == WIDTH {
                        x = 0;
                        
                        if y + 1 == HEIGHT {
                            y = 0;
                        } else {
                            y += 1;
                        }
                        
                        self.clearRow(idx: y);
                        self.currentLineIndex += 1;
                    } else {
                        x += 1;
                    }
                }
                
                idx += 1;
            }
        }
    }
    
    func readControlCode(data: Data, idx: inout Int, x: inout Int, y: inout Int) {
        let first = data[idx];
        idx += 1;
        
        if first >= ASC_0 && first <= ASC_9 {
            let letter = data[idx];
            idx += 1;
            
            if letter == ASC_H {
                x = 0;
                y = 0;
            } else if letter == ASC_J {
                if first == ASC_2 || first == ASC_3 {
                    // clear screen!
                    x = 0;
                    y = 0;
                    
                    for i in 0..<WIDTH*HEIGHT {
                        self.cells[i].char = nil;
                    }
                }
            }
        }
    }
}

class ViewController: NSViewController {
    var terminal: Terminal;
    var tty: TTY;
    
    @IBOutlet var text: NSTextField?;
    
    required init?(coder: NSCoder) {
        self.tty = TTY()
        self.terminal = Terminal();
        super.init(coder: coder)
        
        self.tty.run(nc: NotificationCenter.default)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
            self.flagsChanged(with: $0)
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(userLoggedIn(_:)), name: Notification.Name("TerminalDataUpdate"), object: nil)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @objc func userLoggedIn(_ notification: Notification) {
        let d = notification.object! as! (Data, Array<line>);
        
        self.terminal.draw(data: d.0, lineBuffer:  d.1)
        
        var out = Array<Character>();
        var offset = 0; //startingRowIdx * WIDTH;
        if (self.terminal.currentLineIndex > HEIGHT) {
            offset = (self.terminal.currentLineIndex - HEIGHT + 1) * WIDTH;
        }
        
        for i in 0..<HEIGHT {
            for j in 0..<WIDTH {
                let idx = (j + offset + (i*WIDTH)) % (WIDTH*HEIGHT);
                guard let char = self.terminal.cells[idx].char else { break; }
                out.append(char);
            }
            
            out.append(Character("\n"));
        }
        
        
        //        print("------------------------------------------------------------------" + String(currentLineIndex));
        //        for i in 0..<HEIGHT {
        //            var o = "";
        //            for j in 0..<WIDTH {
        //                guard let char = self.cells[j + (i * WIDTH)].char else { continue; }
        //                o.append(char);
        //            }
        //
        //            print(String(i) + "["+o+"]");
        //        }
        //        print("------------------------------------------------------------------");
        
        
        DispatchQueue.main.async { self.text?.cell?.stringValue = String(out); }
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        tty.keyDown(event: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

