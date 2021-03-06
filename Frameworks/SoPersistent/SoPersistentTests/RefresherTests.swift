//
// Copyright (C) 2016-present Instructure, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
    
    

import Foundation
import SoAutomated
import SoPersistent
import ReactiveSwift

class SignalProducerRefresherTests: XCTestCase {

    typealias SignalProducerProtocol = SignalProducer<Void, NSError>

    func testDescribeSignalProducerRefresher() {

        describe("making a refreshable on a view controller") {
            let (refresher, _) = self.refresherWithObserverBlock { $0.sendCompleted() }

            context("when the view controller is a UITableViewController") {
                let vc = UITableViewController(style: .plain)
                let _ = vc.view // trigger viewDidLoad
                refresher.makeRefreshable(vc)

                it("sets the refreshControl") {
                    XCTAssertNotNil(vc.refreshControl)
                }

                it("adds a refresh action") {
                    let actions = vc.refreshControl!.actions(forTarget: refresher, forControlEvent: .valueChanged)!
                    XCTAssertEqual("beginRefresh:", actions.first!)
                }
            }

            context("when the view controller is a UICollectionViewController") {
                let vc = UICollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
                let _ = vc.view // trigger viewDidLoad
                refresher.makeRefreshable(vc)

                it("will always bound vertical") {
                    XCTAssert(vc.collectionView!.alwaysBounceVertical)
                }

                it("adds the refreshControl as a subview") {
                    XCTAssert(refresher.refreshControl.isDescendant(of: vc.collectionView!))
                }

                it("adds a refresh action") {
                    let actions = refresher.refreshControl.actions(forTarget: refresher, forControlEvent: .valueChanged)!
                    XCTAssertEqual("beginRefresh:", actions.first!)
                }
            }
        }

        describe("refreshing") {
            context("when it starts") {
                it("begins the refresh control") {
                    let (refresher, _) = self.refresherWithObserverBlock { $0.send(value: ()) }
                    refresher.refresh(true)
                    XCTAssert(refresher.refreshControl.isRefreshing)
                }

                it("starts the signal producer") {
                    let started = self.expectation(description: "producer started")
                    let sendNext = self.expectation(description: "producer sent next")
                    let (refresher, sp) = self.refresherWithObserverBlock { $0.send(value: ()) }
                    sp.on(started: { started.fulfill() }).startWithResult { _ in sendNext.fulfill() }

                    refresher.refresh(true)

                    self.waitForExpectations(timeout: 1, handler: nil)
                }
            }

            context("when it completes") {
                let (refresher, _) = self.refresherWithObserverBlock { $0.sendCompleted() }

                it("ends the refresh control") {
                    refresher.refresh(true)
                    XCTAssertFalse(refresher.refreshControl.isRefreshing)
                }

                it("refreshCompleted event is sent") {
                    let expectation = self.expectation(description: "refreshCompleted")
                    var error: NSError?
                    refresher.refreshingCompleted.observeValues { e in
                        error = e
                        expectation.fulfill()
                    }
                    refresher.refresh(true)
                    self.waitForExpectations(timeout: 1, handler: nil)
                    XCTAssertNil(error)
                }
            }

            context("when it fails") {
                let (refresher, _) = self.refresherWithObserverBlock { $0.send(error: NSError(subdomain: "hi", description: "ho")) }

                it("ends the refresh control") {
                    refresher.refresh(true)
                    XCTAssertFalse(refresher.refreshControl.isRefreshing)
                }

                it("refreshCompleted event sent with the error") {
                    let expectation = self.expectation(description: "refreshCompleted")
                    var error: NSError?
                    refresher.refreshingCompleted.observeValues { e in
                        error = e
                        expectation.fulfill()
                    }
                    refresher.refresh(true)
                    self.waitForExpectations(timeout: 1, handler: nil)
                    XCTAssertNotNil(error)
                }
            }

            context("when it gets interrupted") {
                let (refresher, _) = self.refresherWithObserverBlock { $0.sendInterrupted() }

                it("ends the refresh control") {
                    refresher.refresh(true)
                    XCTAssertFalse(refresher.refreshControl.isRefreshing)
                }

                it("refreshCompleted event is sent") {
                    let expectation = self.expectation(description: "refreshCompleted")
                    var error: NSError?
                    refresher.refreshingCompleted.observeValues { e in
                        error = e
                        expectation.fulfill()
                    }
                    refresher.refresh(true)
                    self.waitForExpectations(timeout: 1, handler: nil)
                    XCTAssertNil(error)
                }
            }

            context("when it gets canceled") {
                let (refresher, _) = self.refresherWithObserverBlock { $0.send(value: ()) }

                it("ends refreshing") {
                    refresher.refresh(true)
                    refresher.cancel()
                    XCTAssertFalse(refresher.refreshControl.isRefreshing)
                }

                it("refreshCompleted event is sent") {
                    let expectation = self.expectation(description: "refreshCompleted")
                    var error: NSError?
                    refresher.refreshingCompleted.observeValues { e in
                        error = e
                        expectation.fulfill()
                    }
                    refresher.refresh(true)

                    refresher.cancel()

                    self.waitForExpectations(timeout: 1, handler: nil)
                    XCTAssertNil(error)
                }
            }
        }
    }

    // MARK: Helpers

    func refresherWithObserverBlock(_ block: @escaping (Observer<Void, NSError>)->Void) -> (SignalProducerRefresher<SignalProducerProtocol>, SignalProducerProtocol) {
        let sp = SignalProducerProtocol { observer, disposable in
            block(observer)
        }
        let refresher = SignalProducerRefresher<SignalProducerProtocol>(refreshSignalProducer: sp, scope: RefreshScope.global, cacheKey: "testing_cache_key")
        return (refresher, sp)
    }

}
