import UIKit
import RxSwift
import RxCocoa
import Foundation
import os
import Dispatch

/// [ReactiveX/RxSwift](https://github.com/ReactiveX/RxSwift/blob/main/Documentation/GettingStarted.md)
/// [RxSwift Reference](https://docs.rxswift.org/)

/**
 イベントと値を保持する`Observable`インスタンスの作成
 */

// Observable.just(_:)は単一の要素で構成
let singleElementObservable: Observable<Int> = Observable.just(1)
// Observable.of(_:)は複数の要素で構成
let multipleElementsObservable1: Observable<Int> = Observable.of(1, 2, 3)
let multipleElementsObservable2: Observable<[Int]> = Observable.of([1, 2, 3])
// Observable.from(_:)は配列の要素で構成
let arrayElementObservable: Observable<Int> = Observable.from([1, 2, 3])
// ユーザ定義
let manuallyCreatedObservable: Observable<Int> = Observable<Int>.create { (observer: AnyObserver<Int>) -> Disposable in
  observer.onNext(1)
  observer.onCompleted()
  
  return Disposables.create()
}

/**
 `Observable`インスタンスの購読
 */

// next(1) -> completed
// Element: 1
singleElementObservable.subscribe { (event: Event) in
  print(event)
  if let element = event.element {
    print("Element: \(element)")
  }
}

// next(1) -> next(2) -> next(3) -> completed
// Element: 1 -> 2 -> 3
multipleElementsObservable1.subscribe { (event: Event) in
  print(event)
  if let element = event.element {
    print("Element: \(element)")
  }
}

// next([1, 2, 3]) -> completed
// Element: [1, 2, 3]
multipleElementsObservable2.subscribe { (event: Event) in
  print(event)
  if let element = event.element {
    print("Element: \(element)")
  }
}

// next(1) -> next(2) -> next(3) -> completed
// Element: 1 -> 2 -> 3
arrayElementObservable.subscribe { (event: Event) in
  print(event)
  if let element = event.element {
    print("Element: \(element)")
  }
}

// next(1) -> completed
// Element: 1
manuallyCreatedObservable.subscribe { (event: Event) in
  print(event)
  if let element = event.element {
    print("Element: \(element)")
  }
}

/**
 `Observable`インスタンスの購読解除
 */

// 明示的な購読解除(非推奨)
let disposableSubscription: Disposable = arrayElementObservable.subscribe(onNext: { (element: Int) in
  // Element: 1 -> 2 -> 3
  print("Element: \(element)")
})
disposableSubscription.dispose()

// 終了イベント(Completed or Error)の発生 または ARC参照カウントが0 の場合に自動で購読解除
let disposeBag: DisposeBag = DisposeBag()
arrayElementObservable.subscribe {
  // next(1) -> next(2) -> next(3) -> completed
  print($0)
}.disposed(by: disposeBag)

/**
 `Subject`インスタンスの生成
 */

// PublishSubjectは購読後に発行されたイベントのみ購読可能であり、初期値は与えられない
// next(2) -> completed
let publishSubject: PublishSubject<Int> = PublishSubject<Int>()
publishSubject.onNext(1)
publishSubject.subscribe { (event: Event) in
  print(event)
}
publishSubject.onNext(2)
publishSubject.onCompleted()
publishSubject.dispose()

// BehaviorSubjectは購読直前に発行された最新のイベントから購読可能であり、初期値が与えられる
// next(2) -> next(3) -> completed
let behaviorSubject: BehaviorSubject<Int> = BehaviorSubject<Int>(value: 1)
behaviorSubject.onNext(2)
behaviorSubject.subscribe { (event: Event) in
  print(event)
}
behaviorSubject.onNext(3)
behaviorSubject.onCompleted()
behaviorSubject.dispose()

// ReplaySubjectは購読直前に発行されたn個のNextイベントから購読可能であり、初期値は与えられない
// next(2) -> next(3) -> completed
let replaySubject: ReplaySubject<Int> = ReplaySubject<Int>.create(bufferSize: 2)
replaySubject.onNext(1)
replaySubject.onNext(2)
replaySubject.onNext(3)
replaySubject.onCompleted()
replaySubject.subscribe { (event: Event) in
  print(event)
}

// BehaviorRelayは購読直前に発行された最新のイベントのみ購読可能で、CompleteとErrorイベントを発行しない
// next([1, 2, 3])
let behaviorRelay: BehaviorRelay<[Int]> = BehaviorRelay(value: [1])
let behaviorRelayObservable: Observable<[Int]> = behaviorRelay.asObservable()
// ①+演算子を用いた値の追加
behaviorRelay.accept(behaviorRelay.value + [2])
// ②append(_:)を用いた値の追加
var behaviorRelayValue: [Int] = behaviorRelay.value
behaviorRelayValue.append(3)
behaviorRelay.accept(behaviorRelayValue)
behaviorRelayObservable.subscribe { (event: Event) in
  print(event)
}

/**
 `Operator`を用いた`Observable`の要素(=Nextイベント)のフィルタリング(Filter)
 ※ 以降、「要素」は`Next`イベントのみを指す
 */

// ObservableType#ignoreElements()は全ての要素が排除されたCompleteイベントのみを発行するObservable<Never>を返却する
// completed
let ignoredObservable: Observable<Never> = Observable<Int>.of(1, 2, 3).ignoreElements()
ignoredObservable.subscribe { (event: Event) in
  print(event)
}.disposed(by: disposeBag)

// ObservableType#element(at:)は指定したindexの要素のみをもつObservable<Element>を返却する
// next(1) -> completed
let specificElementObservable: Observable<Int> = Observable<Int>.of(1, 2, 3).element(at: 0)
specificElementObservable.subscribe { (event: Event) in
  print(event)
}.disposed(by: disposeBag)

// ObservableType#filter(_:)は指定した条件を満たす要素群を発行するObservable<Element>を返却する
// next(2) -> completed
let filteredElementsObservable: Observable<Int> = Observable<Int>.of(1, 2, 3)
  .filter { (i: Int) -> Bool in
    return i > 1
  }
  .filter { $0 < 3 }
filteredElementsObservable.subscribe { (event: Event) in
  print(event)
}.disposed(by: disposeBag)

// ObservableType#skip(_:)は先頭要素から指定した要素数を排除した要素群を発行するObservable<Element>を返却する
// next(3) -> completed
let skippedElementsObservable: Observable<Int> = Observable<Int>.of(1, 2, 3).skip(2)
skippedElementsObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#skip(while:)は先頭要素から指定した条件を満たす間の要素を排除した要素群を発行するObservable<Element>を返却する
// next(3) -> next(1) -> next(2) -> completed
let skippedWhileConditionIsMetObservable: Observable<Int> = Observable<Int>.of(1, 2, 3, 1, 2).skip(while: { $0 < 3 })
skippedWhileConditionIsMetObservable.subscribe{ print($0) }.disposed(by: disposeBag)

// ObservableType#skip(until:)は引数のObservableがNextイベントを発行するまでの要素を排除したObservable<Element>を返却する
// -> 引数のObservableがNextイベントを発行しない場合は、全ての要素が排除され、Completeイベントを発行するObservable<Element>が返却される
// Trigger: next(1) -> Trigger: completed -> Triggered: next(3) -> Triggered: completed
let triggerPublishSubject: PublishSubject<Int> = PublishSubject<Int>()
triggerPublishSubject.subscribe { print("Trigger: \($0)") }.disposed(by: disposeBag)
let skippedUntilTriggeredPublishSubject: PublishSubject<Int> = PublishSubject<Int>()
skippedUntilTriggeredPublishSubject.skip(until: triggerPublishSubject).subscribe { print("Triggered: \($0)") }.disposed(by: disposeBag)
skippedUntilTriggeredPublishSubject.onNext(1)
skippedUntilTriggeredPublishSubject.onNext(2)
triggerPublishSubject.onNext(1)
triggerPublishSubject.onCompleted()
skippedUntilTriggeredPublishSubject.onNext(3)
skippedUntilTriggeredPublishSubject.onCompleted()

// ObservableType#take(_:)は先頭要素から指定した要素数の要素群を発行するObservable<Element>を返却する
// next(1) -> next(2) -> completed
let takenObservable: Observable<Int> = Observable<Int>.of(1, 2, 3).take(2)
takenObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#take(while:)は先頭要素から指定した条件を満たす間の要素群を発行するObservable<Element>を返却する
// -> 先頭要素がすでに条件を満たさない場合は、全ての要素が排除され、Completeイベントを発行するObservable<Element>が返却される
// next(1) -> completed
let takenWhileConditionIsMetObservable: Observable<Int> = Observable<Int>.of(1, 2, 3, 4, 5).take(while: { $0 < 2 })
takenWhileConditionIsMetObservable.subscribe{ print($0) }.disposed(by: disposeBag)

// ObservableType#take(until:)は先頭要素から指定した条件を初めて満たすまでの要素群を発行するObservable<Element>を返却する
// -> 先頭要素がすでに条件を満たす場合は、全ての要素が排除され、Completeイベントを発行するObservable<Element>を返却する
// next(1) -> next(2) -> completed
let takenUntilConditionIsMetObservable: Observable<Int> = Observable<Int>.of(1, 2, 3, 4, 5).take(until: { $0 > 2 })
takenUntilConditionIsMetObservable.subscribe{ print($0) }.disposed(by: disposeBag)

/**
 `Operator`を用いた要素の変換(Transform)
 */

// ObservableType#toArray()は各要素を1つの配列に格納した要素を発行するSingle<Element>を返却する
// next([1, 2, 3]) -> completed
let arrayedObservable: Observable<[Int]> = Observable<Int>.of(1, 2, 3).toArray().asObservable()
arrayedObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#map(_:)は各要素に対して演算が行われた要素群を発行するObservable<Element>(厳密にはObservable<Result>)を返却する
// next(6) -> next(12) -> next(18) -> completed
let mappedObservable: Observable<Int> = Observable<Int>.of(1, 2, 3)
  .map { (i: Int) -> Int in
    return i * 2
  }
  .map { $0 * 3 }
mappedObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#flatMap(_:)は各要素に対して演算が行われた要素群を発行するObservable<Observable<Element>>を非同期的に生成し、
// 購読可能な全てのObservable<Element>がマージされた要素群を発行するObservable<Element>を返却する
// next(10) -> next(100) -> next(20) -> next(1000) -> next(200) -> next(30)
// -> next(2000) -> next(300) -> next(3000) -> completed
let flatMappedObservable: Observable<Int> = Observable<Int>.of(1, 2, 3)
  .flatMap { (i: Int) -> Observable<Int> in
    return Observable.just(i * 2)
  }
  .flatMap { Observable.of($0 * 5, $0 * 50, $0 * 500) }
flatMappedObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#flatMapLatest(_:)は各要素に対して演算が行われた要素群を発行するObservable<Observable<Element>>を非同期的に生成し、
// 任意の時点ごとに購読可能な最新のObservable<Element>のみがマージされた要素群を発行するObservable<Element>を返却する
// next(10) -> next(20) -> next(30) -> next(300) -> next(3000) -> completed
let flatMappedLatestObservable: Observable<Int> = Observable<Int>.of(1, 2, 3)
  .flatMapLatest { (i: Int) -> Observable<Int> in
    return Observable.just(i * 2)
  }
  .flatMapLatest { Observable.of($0 * 5, $0 * 50, $0 * 500)}
flatMappedLatestObservable.subscribe { print($0) }.disposed(by: disposeBag)

/**
 `Oparator`を用いた要素の結合(Combine)
 */

// ObservableType#startWith(_:)は先頭要素の前に引数の要素群を追加して発行するObservable<Element>を返却する
// next(0) -> next(1) -> next(2) -> next(3) -> completed
let startedWithAddedElementObservable: Observable<Int> = Observable<Int>.of(1, 2, 3).startWith(0)
startedWithAddedElementObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#concat(_:), ObservableType#concat(), ObservableType.concate(_:)はあるObservable<Element>の要素に
// 他のObservable<Element>の要素を同期的(=直列的)に連結(concatenate)した要素群を発行するObservable<Element>を返却する
// next(1) -> next(2) -> next(3) -> next(4) -> completed
let firstConcatenatedObservable: Observable<Int> = Observable<Int>.just(1).concat(Observable<Int>.just(2))
let secondConcatenatedObservable: Observable<Int> = Observable.of(firstConcatenatedObservable, Observable<Int>.just(3)).concat()
let lastConcatenatedObservable: Observable<Int> = Observable.concat([secondConcatenatedObservable, Observable<Int>.just(4)])
lastConcatenatedObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#merge()はあるObservable<Element>の要素に
// 他のObservable<Element>の要素を非同期的(=並列的)に統合(merge)した要素群を発行するObservable<Element>を返却する
// -> 統合が完了するまでに発生したCompleteイベントは、統合段階で除外される
// next(1) -> next(1) -> next(2) -> next(2) -> next(3) -> next(3) -> completed
let firstMergedPublishSubject: PublishSubject<Int> = PublishSubject<Int>()
let secondMergedPublishSubject: PublishSubject<Int> = PublishSubject<Int>()
let mergedObservable: Observable<Int> = Observable.of(firstMergedPublishSubject.asObservable(), secondMergedPublishSubject.asObservable()).merge()
mergedObservable.subscribe { print($0) }.disposed(by: disposeBag)
firstMergedPublishSubject.onNext(1)
secondMergedPublishSubject.onNext(1)
secondMergedPublishSubject.onNext(2)
firstMergedPublishSubject.onNext(2)
firstMergedPublishSubject.onNext(3)
firstMergedPublishSubject.onCompleted()
secondMergedPublishSubject.onNext(3)
secondMergedPublishSubject.onCompleted()

// ObservableType.combineLatest(_:_:resultSelector:)は引数の全てのObservableで要素が追加されてから、
// いずれかのObservableで要素が追加されるたびに、その時点での各Observableの最新の要素群を単一の要素として発行するObservableを返却する
// -> 返却する
// next(first: 2, second: 10) -> next(first: 2, second: 11) -> next(first: 3, second: 11)
// -> next(first: 3, second: 12) -> completed
let firstCombinedLatestPublishSubject: PublishSubject<Int> = PublishSubject<Int>()
let secondCombinedLatestPublishSubject: PublishSubject<Int> = PublishSubject<Int>()
let combinedLatestObservable: Observable<String> = Observable.combineLatest(firstCombinedLatestPublishSubject, secondCombinedLatestPublishSubject, resultSelector: { (firstElement: Int, secondElement: Int) -> String in
  return "first: \(firstElement), second: \(secondElement)"
})
combinedLatestObservable.subscribe { print($0) }.disposed(by: disposeBag)
firstCombinedLatestPublishSubject.onNext(1)
firstCombinedLatestPublishSubject.onNext(2)
secondCombinedLatestPublishSubject.onNext(10)
secondCombinedLatestPublishSubject.onNext(11)
firstCombinedLatestPublishSubject.onNext(3)
firstCombinedLatestPublishSubject.onCompleted()
secondCombinedLatestPublishSubject.onNext(12)
secondCombinedLatestPublishSubject.onCompleted()

// ObservableType#withLatestFrom(_:)は引数のSourceに要素が追加されてから、
// トリガーとなるObservable<Void>で要素が追加されるたびに、その時点でのSourceの最新の単一の要素を発行するObservable<Source.Element>を返却する
// next(2) -> next(3)
let triggerredWithLatestFromPublishSubject: PublishSubject<Int> = PublishSubject<Int>()
let triggerWithLatestFromPublishSubject: PublishSubject<Void> = PublishSubject<Void>()
let withLatestFromObservable: Observable<Int> = triggerWithLatestFromPublishSubject.withLatestFrom(triggerredWithLatestFromPublishSubject)
withLatestFromObservable.subscribe{ print($0) }.disposed(by: disposeBag)
triggerWithLatestFromPublishSubject.onNext(())
triggerredWithLatestFromPublishSubject.onNext(1)
triggerredWithLatestFromPublishSubject.onNext(2)
triggerWithLatestFromPublishSubject.onNext(())
triggerredWithLatestFromPublishSubject.onNext(3)
triggerredWithLatestFromPublishSubject.onCompleted()
triggerWithLatestFromPublishSubject.onNext(())

// ObservableType#reduce(_:accumulator:)は、第一引数の初期値と全ての要素の総和を演算した要素を発行するObservable<Element>を返却する
// next(36) -> completed
// old: 20, new: 16
let reducedObservable: Observable<Int> = Observable<Int>.of(1, 2, 3)
  .reduce(10, accumulator: +)
  .reduce(20, accumulator: { (oldValue: Int, newValue: Int) -> Int in
    print("[old: \(oldValue), new: \(newValue)]")
    return oldValue + newValue
  })
reducedObservable.subscribe { print($0) }.disposed(by: disposeBag)

// ObservableType#scan(_:accumulator:)は、第一引数の初期値に各要素の値を演算した要素群を発行するObservable<Element>を返却する
// next(31) -> next(44) -> next(60) -> completed
// [old: 20, new: 11] -> [old: 31, new: 13] -> [old: 44, new: 16]
let scannedObservable: Observable<Int> = Observable<Int>.of(1, 2, 3)
  .scan(10, accumulator: +)
  .scan(20, accumulator: { (oldValue: Int, newValue: Int) -> Int in
    print("[old: \(oldValue), new: \(newValue)]")
    return oldValue + newValue
  })
scannedObservable.subscribe { print($0) }.disposed(by: disposeBag)
