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

let WIDTH = 80;
let HEIGHT = 24;

// --------
let backspace = Character("\u{8}").asciiValue!;
let newline = Character("\n").asciiValue!;
let carriagereturn = Character("\r").asciiValue!;

let ASC_J = Character("J").asciiValue!;
let ASC_h = Character("h").asciiValue!;
let ASC_H = Character("H").asciiValue!;
let ASC_m = Character("m").asciiValue!;
let ASC_l = Character("l").asciiValue!;
let ASC_P = Character("P").asciiValue!;

let ASC_BELL = Character("\u{7}").asciiValue!;
let ASC_ESC = Character("\u{1b}").asciiValue!;
let ASC_L_SQUARE = Character("[").asciiValue!;
let ASC_R_SQUARE = Character("]").asciiValue!;
let ASC_BACKSLASH = Character("\\").asciiValue!;
let ASC_SEMI_COLON = Character(";").asciiValue!;
let ASC_LESS_THAN = Character("<").asciiValue!;
let ASC_EQUALS = Character("=").asciiValue!;
let ASC_GREATER_THAN =  Character(">").asciiValue!;
let ASC_QUESTION_MARK =  Character("?").asciiValue!;

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
            
            print(String(decoding: data[s..<e], as: UTF8.self))
            
            var idx = s;
            while idx < e {
                let b = data[idx];
                let bc = Character(UnicodeScalar(b))
                
                if b == ASC_ESC {
                    let peek = data[idx + 1];
                    if peek == ASC_L_SQUARE {
                        idx += 1;
                        self.readControlCode(data: data, idx: &idx, x: &x, y: &y);
                    } else if peek == ASC_P {
                        // xterm doesn't do anything with these... so ignore?
                        idx += 1
                        var p1 = idx + 1 < data.count ? data[idx + 1] : nil;
                        var p2 = idx + 2 < data.count ? data[idx + 2] : nil;
                        
                        while !(p1 == ASC_ESC && p2 == ASC_BACKSLASH) {
                            idx += 1
                            p1 = idx + 1 < data.count ? data[idx + 1] : nil;
                            p2 = idx + 2 < data.count ? data[idx + 2] : nil;
                        }
                        
                        idx += 2 // skip over peeks
                    } else if peek == ASC_R_SQUARE {
                        idx += 1
                        var p1 = idx + 1 < data.count ? data[idx + 1] : nil;
                        
                        while p1 != ASC_BELL {
                            idx += 1
                            p1 = idx + 1 < data.count ? data[idx + 1] : nil;
                        }
                        
                        idx += 1 // skip over peeks
                        print("TODO: [");
                    } else {
                        idx += 1;
                        print("UNKNOWN ESCAPE CHAR: \(Character(UnicodeScalar(data[idx])))")
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
        
        print("Curr: \(self.currentLineIndex)");
    }
    
    func isNumber(_ i: UInt8?) -> Bool {
        guard let i = i else { return false; }
        return i >= ASC_0 && i <= ASC_9
    }
    
    func consumeNumber(data: Data, idx: inout Int) -> Int {
        let s = idx + 1;
        while self.isNumber(data[idx + 1]) {
            idx += 1;
        }
        
        let num = data[s...idx];
        
        // print("Parsed: " + String(decoding: num, as: Unicode.UTF8.self));
        return Int(String(decoding: num, as: Unicode.UTF8.self))!
    }
    
    func readControlCode(data: Data, idx: inout Int, x: inout Int, y: inout Int) {
        var peek: UInt8? = data[idx + 1];
        
        var questionMark = false;
        var greaterThan = false;
        var lessThan = false;
        var equals = false;
        
        while peek! >= ASC_LESS_THAN && peek! <= ASC_QUESTION_MARK {
            switch peek {
            case ASC_QUESTION_MARK: questionMark = true;
            case ASC_GREATER_THAN: greaterThan = true;
            case ASC_LESS_THAN: lessThan = true;
            case ASC_EQUALS: equals = true;
            default: print("UNKNOWN: \(peek!)");
            }
            
            idx += 1;
            peek = idx + 1 < data.count ? data[idx + 1] : nil;
        }
        
        // we've parsed some rando characters, now parse out the number array
        var numbers = Array<UInt16>();
        
        while peek == ASC_SEMI_COLON || (ASC_0 <= peek! && peek! <= ASC_9) {
            while ASC_0 <= peek! && peek! <= ASC_9 {
                if numbers.isEmpty { numbers.append(0); }
                
                numbers[numbers.count - 1] *= 10
                numbers[numbers.count - 1] += UInt16(peek! - ASC_0)
                
                idx += 1;
                peek = idx + 1 < data.count ? data[idx + 1] : nil;
            }
            
            if peek == ASC_SEMI_COLON {
                numbers.append(0);
                idx += 1;
                peek = idx + 1 < data.count ? data[idx + 1] : nil;
            }
        }
        
        if peek == ASC_h {
            var n: UInt16 = 1;
            if numbers.count > 0 && numbers[0] != 0 { n = numbers[0] }
            
            print("\(questionMark ? "?" : "")\(n)h")
            idx += 1;
        } else if peek == ASC_H {
            var n: UInt16 = 1;
            if numbers.count > 0 && numbers[0] != 0 { n = numbers[0] }
            
            var m: UInt16 = 1;
            if numbers.count > 1 && numbers[1] != 0 { m = numbers[1] }
            
            print("\(n);\(m)H")
            idx += 1;
            x = Int(m) - 1;
            y = Int(n) - 1;
            
            // self.currentLineIndex = y;
        } else if peek == ASC_J {
            var n: UInt16 = 0;
            if numbers.count > 0 { n = numbers[0] }
            
            print("\(n)J")
            idx += 1;
            
            if n == 0 {
                // If n is 0 (or missing), clear from cursor to end of screen
                print("TODO: // [0J")
            } else if n == 1 {
                // clear from cursor to beginning of the screen
                print("TODO: // [1J")
            } else if n == 2 {
                //If n is 2, clear entire screen (and moves cursor to upper left on DOS ANSI.SYS)
                print("TODO: // [2J")
                
                for i in 0..<WIDTH*HEIGHT {
                    self.cells[i].char = nil;
                }
            } else /* 3 */ {
                for i in 0..<WIDTH*HEIGHT {
                    self.cells[i].char = nil;
                }
            }
        } else if peek == ASC_m && numbers.count > 1 {
            idx += 1;
            
            let n = numbers[0]
            let m = numbers[1]
            
            print("TODO: [\(n);\(m)m")
        } else if peek == ASC_m {
            idx += 1;
            
            var n: UInt16 = 0;
            if numbers.count > 0 { n = numbers[0] }
            
            switch (n) {
            case 0: print("[\(n)m setting Normal (default)");
            case 1: print("[\(n)m setting Bold");
            case 4: print("[\(n)m setting Underlined");
            case 30: print("[\(n)m Setting colour to Black")
            case 31: print("[\(n)m Setting colour to Red")
            case 32: print("[\(n)m Setting colour to Green")
            case 33: print("[\(n)m Setting colour to Yellow")
            case 34: print("[\(n)m Setting colour to Blue")
            case 35: print("[\(n)m Setting colour to Magenta")
            case 36: print("[\(n)m Setting colour to Cyan")
            case 37: print("[\(n)m Setting colour to White")
            case 39: print("[\(n)m Setting colour to default (original)")
            case 40: print("[\(n)m Setting colour to Black")
            case 41: print("[\(n)m Setting colour to Red")
            case 42: print("[\(n)m Setting colour to Green")
            case 43: print("[\(n)m Setting colour to Yellow")
            case 44: print("[\(n)m Setting colour to Blue")
            case 45: print("[\(n)m Setting colour to Magenta")
            case 46: print("[\(n)m Setting colour to Cyan")
            case 47: print("[\(n)m Setting colour to White")
            default: print("TODO: color [\(n)m")
            }
        } else {
            idx += 1;
            print("----- UNKNOWN CSI: [\(Character(UnicodeScalar(data[idx])))")
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
                let char = self.terminal.cells[idx].char ?? " ";
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

