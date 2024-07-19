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

class ViewController: NSViewController {
    var tty: TTY;
    
    @IBOutlet var text: NSTextField?;
    
    var cells = Array<Cell>();
    
    required init?(coder: NSCoder) {
        self.tty = TTY()
        super.init(coder: coder)
        
        self.tty.run(nc: NotificationCenter.default)
                
        for _ in 0..<WIDTH*HEIGHT {
            self.cells.append(Cell())
        }
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
    
    func clearRow(idx: Int) {
        for i in (WIDTH*idx)..<(WIDTH*(idx+1)) {
            self.cells[i].char = nil;
        }
    }
    
    @objc func userLoggedIn(_ notification: Notification) {
        let d = notification.object! as! (Data, Array<line>);
    
        // --------
        let backspace = Character("\u{8}").asciiValue;
        let newline = Character("\n").asciiValue;
        let carriagereturn = Character("\r").asciiValue;
        // --------
        
        var x = 0;
        var y = 0;
        // var startingRowIdx = 0;
        var currentLineIndex = 0;
        
        for i in 0..<HEIGHT {
            self.clearRow(idx: i)
        }
        
        for line in d.1 {
            let l = d.0.subdata(in: line.start..<line.end);
            
            for b in l {
                let bc = Character(UnicodeScalar(b))
                // print(bc, bc.asciiValue)
                
                if b == newline {
                    x = 0;
                    if y + 1 == HEIGHT {
                        y = 0;
                        // startingRowIdx += 1;
                    } else {
                        y += 1;
                        // if (startingRowIdx > 0) { startingRowIdx += 1; }
                    }
                    currentLineIndex += 1;
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
                            //startingRowIdx += 1;
                        } else {
                            y += 1;
                            // if (startingRowIdx > 0) { startingRowIdx += 1; }
                        }
                        
                        self.clearRow(idx: y);
                        currentLineIndex += 1;
                    } else {
                        x += 1;
                    }
                }
            }
        }
        
        var out = Array<Character>();
        var offset = 0; //startingRowIdx * WIDTH;
        if (currentLineIndex > HEIGHT) {
            offset = (currentLineIndex - HEIGHT + 1) * WIDTH;
        }
        
        for i in 0..<HEIGHT {
            for j in 0..<WIDTH {
                let idx = (j + offset + (i*WIDTH)) % (WIDTH*HEIGHT);
                guard let char = self.cells[idx].char else { break; }
                out.append(char);
            }
            
            out.append(Character("\n"));
        }
        
        
        print("------------------------------------------------------------------" + String(currentLineIndex));
        for i in 0..<HEIGHT {
            var o = "";
            for j in 0..<WIDTH {
                guard let char = self.cells[j + (i * WIDTH)].char else { continue; }
                o.append(char);
            }
            
            print(String(i) + "["+o+"]");
        }
        print("------------------------------------------------------------------");
        
        
        DispatchQueue.main.async {
            self.text?.cell?.stringValue = String(out);
        }
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        tty.keyDown(event: event)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

