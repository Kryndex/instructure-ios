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
import TooLegit
import Marshal
import ReactiveSwift
import SoLazy

extension Module {
    public static func getModules(_ session: Session, courseID: String) throws -> SignalProducer<[JSONObject], NSError> {
        let params = ["include": ["items"]]
        let request = try session.GET(api/v1/"courses"/courseID/"modules", parameters: params)
        return session.paginatedJSONSignalProducer(request).map(insert(courseID, forKey: "course_id"))
    }
}
