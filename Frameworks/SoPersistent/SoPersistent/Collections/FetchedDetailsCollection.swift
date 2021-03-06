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
import CoreData
import ReactiveSwift
import Result

open class FetchedDetailsCollection<M, DVM>: Collection where M: NSManagedObject, DVM: Equatable {
    public typealias Object = DVM

    var disposable: Disposable?
    let observer: ManagedObjectObserver<M>
    let detailsFactory: (M)->[DVM]
    var details: [DVM] = []
    open let collectionUpdates: Signal<[CollectionUpdate<DVM>], NoError>
    fileprivate let updatesObserver: Observer<[CollectionUpdate<DVM>], NoError>
    
    public init(observer: ManagedObjectObserver<M>, detailsFactory: @escaping (M)->[DVM]) {
        self.observer = observer
        self.detailsFactory = detailsFactory
        
        (collectionUpdates, updatesObserver) = Signal.pipe()
        
        details = self.observer.object.map(detailsFactory) ?? []
        disposable = observer.signal
            .map { $0.1 }
            .observe(on: UIScheduler())
            .map { $0.map(detailsFactory) ?? [] }
            .observeValues { [weak self] deets in
                if let me = self {
                    let edits = me.details.distanceTo(deets)
                    me.details = deets
                    let updates: [CollectionUpdate<DVM>] = edits.map { edit in
                        switch edit {
                        case .insert(let item, let index):
                            return .inserted(IndexPath(row: index, section: 0), item, animated: true)
                        case .replace(let item, let index):
                            return .updated(IndexPath(row: index, section: 0), item, animated: true)
                        case .delete(let item, let index):
                            return .deleted(IndexPath(row: index, section: 0), item, animated: true)
                        case .move(let item, let fromIndex, let toIndex):
                            return .moved(IndexPath(row: fromIndex, section: 0), IndexPath(row: toIndex, section: 0), item, animated: true)
                        }
                    }
                    me.updatesObserver.send(value: updates)
                }
            }
    }
    
    // keeping it simple... 1 section
    open func numberOfSections() -> Int {
        return 1
    }
    
    open func titleForSection(_ section: Int) -> String? {
        return nil
    }
    
    open func numberOfItemsInSection(_ section: Int) -> Int {
        return details.count
    }
    
    open subscript(indexPath: IndexPath) -> DVM {
        return details[indexPath.row]
    }
}

