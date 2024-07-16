//
//  ViewController.swift
//  okgo
//
//  Created by Adam Dilger on 16/7/2024.
//

import Cocoa

class ViewController: NSViewController {
    var tty: TTY;
    
    required init?(coder: NSCoder) {
        self.tty = TTY()
        super.init(coder: coder)
        self.tty.run()
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
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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

