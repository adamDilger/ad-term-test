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
let HEIGHT = 40;

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
    
    @objc func userLoggedIn(_ notification: Notification) {
        let d = notification.object! as! (Data, Array<line>);
    
        // --------
        let backspace = Character("\u{8}").asciiValue;
        let newline = Character("\n").asciiValue;
        // --------
        
        var x = 0;
        var y = 0;
        
        for line in d.1 {
            let l = d.0.subdata(in: line.start..<line.end);
            
            for b in l {
                let bc = Character(UnicodeScalar(b))
                // print(bc, bc.asciiValue)
                
                if b == newline {
                    y += 1;
                    x = 0;
                } else if b == backspace {
                    x -= 1;
                } else {
                    self.cells[x + (y * WIDTH)].char = bc
                    
                    if x + 1 == WIDTH {
                        x = 0;
                        y += 1;
                    } else {
                        x += 1;
                    }
                }
            }
        }
        
        var out = Array<Character>();
        for cell in self.cells {
            guard let char = cell.char else { continue; }
            out.append(char);
        }
        
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

