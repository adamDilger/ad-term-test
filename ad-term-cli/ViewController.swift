//
//  ViewController.swift
//  ad-term-cli
//
//  Created by Adam Dilger on 16/7/2024.
//

import Cocoa

class ViewController: NSViewController {
    var terminal: Terminal;
    
    @IBOutlet var text: NSTextField?;
    
    required init?(coder: NSCoder) {
        self.terminal = Terminal();
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.terminal.tty!.run()
        
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
            self.flagsChanged(with: $0)
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(terminalDataUpdate(_:)), name: Notification.Name("TerminalDataUpdate"), object: nil)
    }
    
    @objc func terminalDataUpdate(_ notification: Notification) {
        var out = Array<Character>();
        
        let lineOffset = self.terminal.currentLineIndex >= HEIGHT
            ? (self.terminal.currentLineIndex % HEIGHT)
            : 0;
        
        let offset = lineOffset * WIDTH;
        
        out += "   |" + String(repeating: "-", count: WIDTH) + "|\n";
        for i in 0..<HEIGHT {
            out += String(format: "%02d |", i)
            for j in 0..<WIDTH {
                let idx = (j + offset + (i*WIDTH)) % (WIDTH*HEIGHT);
                let char = self.terminal.cells[idx].char ?? " ";
                out.append(char);
            }
            
            out += "|\n";
        }
        out += "   |" + String(repeating: "-", count: WIDTH) + "|\n";
        
        print("------------------------------------------------------------------" + String(self.terminal.currentLineIndex % HEIGHT));
        for i in 0..<HEIGHT {
            var o = "";
            for j in 0..<WIDTH {
                let char = self.terminal.cells[j + (i * WIDTH)].char ?? " "
                o.append(char);
            }

            print(String(i) + "|"+o+"|");
        }
        print("------------------------------------------------------------------");
        
        DispatchQueue.main.async { self.text?.cell?.stringValue = String(out); }
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        self.terminal.tty!.keyDown(event: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}
