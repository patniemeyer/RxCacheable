//
//  CachedSingleTests.swift
//  RxTestTests
//
//  Created by Patrick Niemeyer on 8/5/18.
//  Copyright © 2018 co.present. All rights reserved.
//

import XCTest
import RxSwift

class CachedSingleTests: XCTestCase
{

    func testExample()
    {
        // produce integers with an expiration of 3 seconds
        var count = 0
        let cs = TransformableCachedSingle<Int>(expiration: 3.0) {
            return Single.create { observer in
                mainAfter(0.1) {
                    observer(.success(count))
                    count+=1
                }
                return Disposables.create()
            }
        }
        
        // Accumulate results for comparison
        var results = [String]()
        func got(_ string: String) {
            print(string)
            results.append(string)
        }
        
        print("subscribing 1")
        cs.observable().onNext { got("sub1 got: \($0)") }.neverDisposed()
        
        var transform: TransformableCachedSingle<Int>.Transform?
        mainAfter(2) {
            print("applying transform")
            transform = cs.transform { _ in return 99 }
        }
        
        mainAfter(3) {
            print("data expired")
        }
        
        mainAfter(3.5) {
            print("subscribing 2")
            cs.observable().onNext { got("sub2 got: \($0)") }.neverDisposed()
        }

        mainAfter(4) {
            print("expiring transform")
            guard let transform = transform else { fatalError() }
            transform.expire()
        }
        
        mainAfter(5) {
            print("subscribing 3")
            cs.observable().onNext { got("sub3 got: \($0)") }.neverDisposed()
        }

        mainAfter(6.5) {
            print("data expired again")
        }
        
        mainAfter(7) {
            print("subscribing 4")
            cs.observable().onNext { got("sub4 got: \($0)") }.neverDisposed()
        }

        let end = expectation(description: "end")
        mainAfter(10) {
            end.fulfill()
        }

        waitForExpectations(timeout: 30, handler: nil)
        XCTAssertEqual(results, [
            "sub1 got: 0", // initial value
            
            "sub1 got: 99", // applied transform caused sub1 to update
            
            // sub2 subscribes after data expiration, triggering new data produced for subs 1 and 2.
            // The data is still transformed so value "1" is overridden
            "sub1 got: 99",
            "sub2 got: 99",

            // sub3 subscribes after transform has expired, but the data has not expired yet so
            // the expired transform still applies
            "sub3 got: 99",
            
            // sub4 subscribes after transform has expired and the data has expired, all get new data
            "sub1 got: 2",
            "sub2 got: 2",
            "sub3 got: 2",
            "sub4 got: 2",
            ])
        
    }

}
