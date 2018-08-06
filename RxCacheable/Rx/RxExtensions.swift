//
//  RxExtensions.swift
//  Present
//
//  Created by Patrick Niemeyer on 4/19/18.
//  Copyright © 2018 Present Company. All rights reserved.
//

import Foundation
import RxSwift
//import Then

// Add top level "on event" and calls and a disposed:by to Observbable making it easier
// to build subscriptions by chaining.
public extension RxSwift.Observable
{
    public func onNext(onNext: @escaping (E) throws -> Swift.Void) -> RxSwift.Observable<E> {
        return self.do(onNext: onNext)
    }
    public func onError(onError: @escaping (Error) throws -> Swift.Void) -> RxSwift.Observable<E> {
        return self.do(onError: onError)
    }
    public func onCompleted(onCompleted: @escaping () throws -> Swift.Void) -> RxSwift.Observable<E> {
        return self.do(onCompleted: onCompleted)
    }
    public func onSubscribe(onSubscribe: @escaping () -> Swift.Void) -> RxSwift.Observable<E> {
        return self.do(onSubscribe: onSubscribe)
    }
    public func onSubscribed(onSubscribed: @escaping () -> Swift.Void) -> RxSwift.Observable<E> {
        return self.do(onSubscribed: onSubscribed)
    }
    public func disposed(by bag: DisposeBag) {
        self.subscribe().disposed(by: bag)
    }
    public func neverDisposed() {
        _ = self.subscribe()
    }
    
    /// Take a single value and then automatically unsubscribe.
    public func takeSingle() -> RxSwift.Single<E> {
        return self.take(1).asSingle()
    }
    public func takeOne() {
        return takeSingle().neverDisposed()
    }
}

public extension RxSwift.PrimitiveSequenceType where Self.TraitType == RxSwift.SingleTrait
{
    public func onSuccess(onSuccess: @escaping (ElementType) throws -> Swift.Void) -> Single<ElementType> {
        return self.do(onSuccess: onSuccess)
    }
    public func onError(onError: @escaping (Error) throws -> Swift.Void) -> Single<ElementType> {
        return self.do(onError: onError)
    }
    public func disposed(by bag: DisposeBag) {
        self.subscribe().disposed(by: bag)
    }
    public func neverDisposed() {
        _ = self.subscribe()
    }
}

public extension PrimitiveSequenceType where TraitType == CompletableTrait, ElementType == Swift.Never
{
    public func onCompleted(onCompleted: @escaping () throws -> Swift.Void) -> Completable {
        return self.do(onCompleted: onCompleted)
    }
    public func onError(onError: @escaping (Error) throws -> Swift.Void) -> Completable {
        return self.do(onError: onError)
    }
    public func disposed(by bag: DisposeBag) {
        self.subscribe().disposed(by: bag)
    }
    public func neverDisposed() {
        _ = self.subscribe()
    }
}

extension Disposable {
    public func disposedBy(_ disposeBag: DisposeBag) {
        disposed(by: disposeBag)
    }
}

extension ObserverType where E == Void {
    public func onNext() {
        onNext(())
    }
}

extension ReplaySubject {
    /// Create a replay subject with a buffer size of one.
    public class func create() -> ReplaySubject<Element> {
        return ReplaySubject<Element>.create(bufferSize: 1)
    }
}
//extension ReplaySubject: Then { }



