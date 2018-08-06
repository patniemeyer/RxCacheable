//
//  CachedSingle.swift
//  Present
//
//  Created by Patrick Niemeyer on 8/2/18.
//  Copyright © 2018 Present Company. All rights reserved.
//

import Foundation
import RxSwift
//import Then

/**
 CachedSingle provides as a read-through cache backed by a Single data source.
 New subscriptions prompt an expiration check and new subscribers can be configured to either block
 waiting for non-expired data or receive the current replay value followed by the update.
 This provides a single source of truth that is refreshed lazily based on demand.

 This class holds a shared observable that is populated from the supplied Single. The single
 is executed on the first subscription and then again for any new subscriptions after the specified
 expiration period.
 */
public class CachedSingle<T>: Refreshable
{
    public func observable() -> Observable<T> {
        return subject
            .flatMap {
                Observable.from(optional: $0)
            }
            .onSubscribe {
                self.checkExpired()
        }
    }
    
    /// If true subscribers will block waiting for new data after expiration, otherwise they
    /// may receive a replayed value followed by an updated value when it arrives.
    public var isBlocking = true
    
    let subject = ReplaySubject<T?>.create(bufferSize: 1)
    private let singleProducer: ()->Single<T>
    private var lastFetch: Date? = nil
    private let expiration: TimeInterval
    let name: String // for logging
    
    public init(name: String = "CachedSingle", expiration time: TimeInterval, from singleProducer: @escaping ()->Single<T>)
    {
        self.name = name
        self.expiration = time
        self.singleProducer = singleProducer
    }
    
    public convenience init(name: String = "CachedSingle", expiration time: TimeInterval, from single: Single<T>) {
        self.init(expiration: time, from: { return single })
    }
    
    /// Expire the cache.  The value will be fetched again on the next subscribe.
    public func invalidate()  {
        lastFetch = nil
    }
    
    /// Trigger a refresh if data is older than the specified time interval
    public func refresh(ifOlderThan expiration: TimeInterval) {
        checkExpired(expirationValue: expiration)
    }
    
    /// Trigger a refresh if data is older than a default expiration value of 1 second
    public func refresh() {
        refresh(ifOlderThan: TimeInterval(1))
    }
    
    /// Trigger a refresh if the data has expired per the configured expiration value
    public func refreshIfExpired() {
        checkExpired()
    }
    
    func checkExpired(expirationValue: TimeInterval? = nil)
    {
        let expiration = expirationValue ?? self.expiration
        if lastFetch == nil || Date().timeIntervalSince(lastFetch!) > expiration
        {
            print("single expired, producing")
            //log("Fetching \(name)")
            lastFetch = Date()
            
            // Setting the subject to nil here (and the corresponding flatMap
            // that removes this optional-ness from the stream) allows the new
            // subscription to wait for thew new data rather than receiving the
            /// expired value immediately followed by the fresh data.
            if isBlocking {
                subject.onNext(nil)
            }
            
            produce()
        }
    }
    
    func produce() {
        singleProducer()
            .onSuccess { [weak self] value in
                self?.publish(value)
            }.neverDisposed()
    }
    
    func publish(_ value: T) {
        subject.onNext(value)
    }
}

/**
 A CachedSingle that provides a way to transform the cached data for a time and then allow those
 transformations to be removed when new data subsequently arrives from the Single producer.  This can
 be used to make “optimistic” changes to local data that are then committed or rolled back when
 an operation completes.
 
 A transform that has not expired is applied to all values in the sequence, whether they result from
 newly produced data from the single producer or replayed data.  A transform that has expired will
 continue to apply only so long as cached data remains and will be removed upon the next production
 of new data by the single producer.  In this way transformations allow the locally cached data to
 effectively be modified with the option to allow those modifications to be overwritten when fresh
 data arrives from the single producer.
 */
public class TransformableCachedSingle<T>: CachedSingle<T>
{
    public typealias TransformType<T> = (T)->T
    
    private var transforms = [Transform]()
    
    // Signal when changes to transforms should generate a new value.
    // Note: BehaviorSubject won't block and won't double up as with combining ReplaySubject and startsWith().
    private let transformsChangedSubject = BehaviorSubject(value: Void())

    override public func observable() -> Observable<T>
    {
        return Observable.combineLatest(
            super.observable().onNext { _ in print("observable fired")},
            transformsChangedSubject.onNext { _ in print("transforms fired")}
        ) { value, _ in
            // Apply the transforms to the data
            return self.transforms.reduce(value) { (value:T, transform:Transform) in
                transform.apply(value)
            }
        }
    }
    
    public func transform(with transformer: @escaping TransformType<T>) -> Transform {
        let transform = Transform(transformer)
        transforms.append(transform)
        transformsChangedSubject.onNext()
        return transform
    }
    
    public func clearExpiredTransforms() {
        log("\(name) clearing transforms, count=\(transforms.count)")
        transforms = self.transforms.filter { !$0.isExpired }
        log("\(name) after clearing transforms, count=\(transforms.count)")
    }
    
    override func publish(_ value: T) {
        clearExpiredTransforms()
        log("\(name) publish value")
        super.publish(value)
    }
    
    public class Transform {
        private let transform: TransformType<T>
        private var expire: Date? = nil
        
        public init(_ transform: @escaping TransformType<T>) {
            self.transform = transform
        }
        
        public func apply(_ value: T)->T {
            return transform(value)
        }
        
        public func expire(at date: Date = Date()) {
            self.expire = date
        }
        
        public var isExpired: Bool {
            if let date = expire {
                return date < Date()
            } else {
                return false
            }
        }
    }
    
}

public extension RxSwift.PrimitiveSequenceType where Self.TraitType == RxSwift.SingleTrait
{
    public func cached(name: String = "cached",
        for expiration: TimeInterval) -> TransformableCachedSingle<ElementType>
    {
        // ?
        let single: Single<ElementType> = self as! PrimitiveSequence<SingleTrait, Self.ElementType>
        return TransformableCachedSingle(name: name, expiration: expiration, from: single)
    }
}

public protocol Refreshable {
    func refresh()
    func refresh(ifOlderThan: TimeInterval)
    func refreshIfExpired()
}

