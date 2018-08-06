//
//  Util.swift
//  RxTest
//
//  Created by Patrick Niemeyer on 8/5/18.
//  Copyright © 2018 co.present. All rights reserved.
//

import Foundation

public func log(_ string: String) { print(string) }
public func logx(_ string: String) { print(string) }

/// Execute the block asynchronously on the main queue
public func main(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.main.async(execute: work)
}
/// Execute the block asynchronously on the main queue after the specified time.
public func mainAfter(_ seconds: Float, execute work: @escaping @convention(block) () -> Swift.Void) {
    mainAfter(milliseconds: Int(seconds*1000), execute: work)
}
/// Execute the block asynchronously on the main queue after the specified time.
public func mainAfter(seconds: Int, execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.main.asyncAfter(seconds: seconds, execute: work)
}
/// Execute the block asynchronously on the main queue after the specified time.
public func mainAfter(milliseconds: Int, execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.main.asyncAfter(milliseconds: milliseconds, execute: work)
}

extension DispatchQueue {
    
    public func asyncAfter(seconds: Int, execute work: @escaping @convention(block) () -> Swift.Void) {
        self.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(seconds), execute: work)
    }
    
    public func asyncAfter(milliseconds: Int, execute work: @escaping @convention(block) () -> Swift.Void) {
        self.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(milliseconds), execute: work)
    }
    
}
