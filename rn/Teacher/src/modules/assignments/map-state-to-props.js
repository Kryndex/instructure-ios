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

import localeSort from '../../utils/locale-sort'
import Navigator from '../../routing/Navigator'
import AssignmentListActions from './actions'

export type AssignmentListDataProps = {
  +pending: number,
  +error?: ?string,
  +courseColor: string,
  +courseName: string,
  +assignmentGroups: AssignmentGroup[],
  +gradingPeriods: Array<GradingPeriod & { assignmentRefs: [string] }>,
  +selectedRowID: string,
}

export type AssignmentListProps = AssignmentListDataProps
  & RoutingProps
  & typeof AssignmentListActions
  & { navigator: Navigator }
  & RefreshProps

type RoutingProps = { +courseID: string }

export function mapStateToProps ({ entities }: AppState, { courseID }: RoutingProps): AssignmentListDataProps {
  const course = entities.courses[courseID]

  if (!course) {
    return {
      assignmentGroups: [],
      pending: 0,
      gradingPeriods: [],
      courseColor: '',
      courseName: '',
      selectedRowID: '',
    }
  }

  const courseColor = course.color
  const courseName = course.course.name
  const { refs, pending, error } = course.assignmentGroups
  const groupsByID: AssignmentGroupsState = entities.assignmentGroups
  const assignmentGroupsState = refs
    .map((ref) => groupsByID[ref])
    .sort((a, b) => a.group.position - b.group.position)

  const assignmentGroups: AssignmentGroup[] = assignmentGroupsState.map((groupState) => {
    const groupWithAssignments = Object.assign({}, groupState.group)
    groupWithAssignments.assignments = (groupState.assignmentRefs || []).map((id) => entities.assignments[id].data)
    return groupWithAssignments
  })

  let gradingPeriods = Object.keys(entities.gradingPeriods)
    .map(id => ({
      ...entities.gradingPeriods[id].gradingPeriod,
      assignmentRefs: entities.gradingPeriods[id].assignmentRefs,
    }))
    .sort((gp1, gp2) => localeSort(gp1.title, gp2.title))

  let selectedRowID = entities.courseDetailsTabSelectedRow.rowID || ''

  return {
    pending,
    error,
    assignmentGroups,
    gradingPeriods,
    courseColor,
    courseName,
    selectedRowID,
  }
}
