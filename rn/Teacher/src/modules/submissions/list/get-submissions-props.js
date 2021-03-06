//
// Copyright (C) 2016-present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

// @flow

import type {
  SubmissionDataProps,
  GradeProp,
  SubmissionStatusProp,
  AsyncSubmissionsDataProps,
} from './submission-prop-types'
import localeSort from '../../../utils/locale-sort'
import find from 'lodash/find'

function getEnrollments (courseContent?: CourseContentState, enrollments: EnrollmentsState): Array<Enrollment> {
  if (!courseContent) { return [] }
  return courseContent.enrollments.refs
    .map(ref => enrollments[ref])
}

function getSubmissionsByUserID (assignmentContent?: AssignmentContentState, submissions: SubmissionsState): { [string]: SubmissionWithHistory } {
  if (!assignmentContent) { return {} }
  return assignmentContent.submissions.refs
    .reduce((byUserID, ref) => {
      const submission = submissions[ref].submission
      if (!submission) { return byUserID }
      return { ...byUserID, [submission.user_id]: submission }
    }, {})
}

export function statusProp (submission: ?Submission, dueDate: ?string): SubmissionStatusProp {
  if (!submission || submission.workflow_state === 'unsubmitted' || !submission.attempt) {
    if (dueDate && (new Date(dueDate) < new Date())) {
      return 'missing'
    } else {
      return 'none'
    }
  }

  if (submission.late) {
    return 'late'
  } else {
    return 'submitted'
  }
}

export function gradeProp (submission: ?Submission): GradeProp {
  if (!submission ||
    (submission.workflow_state === 'unsubmitted' &&
     !submission.excused)) {
    return 'not_submitted'
  }

  if (submission.excused) {
    return 'excused'
  }

  if (submission.grade && submission.grade_matches_current_submission) {
    return submission.grade
  }

  return 'ungraded'
}

function submissionProps (user: User, submission: ?SubmissionWithHistory, dueDate: ?string): SubmissionDataProps {
  const { id, name } = user
  const avatarURL = user.avatar_url
  const status = statusProp(submission, dueDate)
  const grade = gradeProp(submission)
  const score = submission ? submission.score : null
  let submissionID
  if (submission) {
    submissionID = submission.id
  }
  return { userID: id, avatarURL, name, status, grade, submissionID, submission, score }
}

export function dueDate (assignment: Assignment, user: ?User): ?string {
  if (!assignment) {
    return null
  }

  const overrides = assignment.overrides
  if (overrides) {
    const override = find(overrides, (override) => {
      if (!override.student_ids) return false
      if (!user) return false
      return override.student_ids.includes(user.id)
    })
    if (override) {
      return override.due_at
    }
  }
  return assignment.due_at
}

function uniqueEnrollments (enrollments: Array<Enrollment>): Array<Enrollment> {
  const ids: Set<string> = new Set()
  return enrollments.reduce((unique, e) => {
    if (ids.has(e.user_id)) { return unique }
    ids.add(e.user_id)
    return [...unique, e]
  }, [])
}

export function pendingProp (assignmentContent?: AssignmentContentState, courseContent?: CourseContentState): boolean {
  if (!assignmentContent || !assignmentContent.submissions || !courseContent || !courseContent.enrollments) {
    return true // should be getting these things, so we'll say pending til they show up
  }

  return assignmentContent.submissions.pending > 0 || courseContent.enrollments.pending > 0
}

export function getSubmissionsProps (entities: Entities, courseID: string, assignmentID: string): AsyncSubmissionsDataProps {
  // enrollments
  const courseContent = entities.courses[courseID]
  const enrollments = getEnrollments(courseContent, entities.enrollments)

  // submissions
  const assignmentContent = entities.assignments[assignmentID]
  const submissionsByUserID = getSubmissionsByUserID(assignmentContent, entities.submissions)

  const submissions = uniqueEnrollments(enrollments)
    .filter(enrollment =>
      enrollment.type === 'StudentEnrollment' ||
      enrollment.type === 'StudentViewEnrollment'
    )
    .sort((e1, e2) => {
      if (e1.type !== e2.type) {
        if (e1.type === 'StudentEnrollment') {
          return -1
        } else if (e2.type === 'StudentEnrollment') {
          return 1
        }
      }
      return localeSort(e1.user.sortable_name, e2.user.sortable_name)
    })
    .map(enrollment => {
      const submission: ?SubmissionWithHistory = submissionsByUserID[enrollment.user_id]
      const user = enrollment.user
      const due = dueDate(assignmentContent.data, user)
      return submissionProps(user, submission, due)
    })

  const pending = pendingProp(assignmentContent, courseContent)

  return {
    submissions,
    pending,
  }
}
