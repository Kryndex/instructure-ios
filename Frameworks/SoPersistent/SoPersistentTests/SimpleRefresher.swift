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
import SoPersistent
import ReactiveSwift
import Result

class SimpleRefresher: Refresher {
    
    var cacheKey = "simple"
    var makeRefreshableWasCalled = false
    var refreshWasCalled = false
    var cancelWasCalled = false

    var refreshControl = UIRefreshControl()
    var isRefreshing: Bool = false
    var refreshingBegan: Signal<(), NoError>
    var refreshingBeganObserver: Observer<(), NoError>
    var refreshingCompleted: Signal<NSError?, NoError>
    var refreshingCompletedObserver: Observer<NSError?, NoError>

    init() {
        let (beganSignal, beganObserver) = Signal<(), NoError>.pipe()
        self.refreshingBegan = beganSignal.observe(on: UIScheduler())
        self.refreshingBeganObserver = beganObserver

        let (completedSignal, completedObserver) = Signal<NSError?, NoError>.pipe()
        self.refreshingCompleted = completedSignal.observe(on: UIScheduler())
        self.refreshingCompletedObserver = completedObserver
    }

    func makeRefreshable(_ viewController: UIViewController) {
        makeRefreshableWasCalled = true
    }

    func refresh(_ forced: Bool) {
        refreshWasCalled = true
    }

    func cancel() {
        cancelWasCalled = true
    }

    func safeCopy() -> Refresher? {
        let copy = SimpleRefresher()
        return copy
    }
}
