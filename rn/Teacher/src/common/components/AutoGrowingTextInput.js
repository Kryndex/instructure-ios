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

import React, { PureComponent } from 'react'
import { TextInput } from 'react-native'

type State = { height: number }
type Props = {
  defaultHeight: number,
  style?: any,
  onContentSizeChange?: Function,
  extraHeight: number,
}

export default class AutoGrowingTextInput extends PureComponent {
  props: Props
  state: State

  static defaultProps = {
    extraHeight: 0,
  }

  constructor (props: Props) {
    super(props)

    this.state = { height: this.props.defaultHeight }
  }

  updateContentSize = (e: any) => {
    this.setState({ height: Math.max(e.nativeEvent.contentSize.height + this.props.extraHeight, this.props.defaultHeight) })
    this.props.onContentSizeChange && this.props.onContentSizeChange(e)
  }

  render () {
    return (
      <TextInput
        {...this.props}
        style={[this.props.style, { height: this.state.height }]}
        multiline
        onContentSizeChange={this.updateContentSize}
      />
    )
  }
}
