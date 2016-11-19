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
    
    

import UIKit
import Marshal
import AssignmentKit
import SoPersistent
import FileKit
import Nimble
import TooLegit
import ReactiveCocoa

private class Bundle {}
let currentBundle = NSBundle(forClass: Bundle.self)

let rubricJSON: JSONObject = [
    "id": 259883,
    "title": "Food Network Cooking",
    "points_possible": 1900,
    "free_form_criterion_comments": false
]

let assignmentJSON: JSONObject = [
    "id": "1",
    "course_id": "1",
    "name": "Assignment 1",
    "html_url": "http://canvas.example.com/courses/1/assignments/1",
    "submission_types": ["online_text_entry"]
]

let factoryImage: UIImage = {
    let path = currentBundle.pathForResource("hubble-large", ofType: "jpg")!
    return UIImage(contentsOfFile: path)!
}()

let factoryURL: NSURL = {
    return currentBundle.URLForResource("testfile", withExtension: "txt")!
}()

func uploadSubmission(submissionUpload: SubmissionUpload, in session: Session) {
    let predicate = NSPredicate(format: "%K == %@", "backgroundSessionID", submissionUpload.backgroundSessionID)
    let observer = try! ManagedObjectObserver<SubmissionUpload>(predicate: predicate, inContext: submissionUpload.managedObjectContext!)
    var disposable: Disposable?
    waitUntil(timeout: 2) { done in
        disposable = observer.signal.observeResult { result in
            expect(result.error).to(beNil())
            if let upload = result.value?.1 {
                expect(upload.errorMessage).to(beNil())
                if upload.hasCompleted {
                    done()
                }
            }
        }
        submissionUpload.begin(inSession: session, inContext: submissionUpload.managedObjectContext!)
    }
    disposable?.dispose()
}

extension NSItemProvider {
    convenience init(_ item: NSSecureCoding?, _ identifier: CFString) {
        self.init(item: item, typeIdentifier: identifier as String)
    }
}