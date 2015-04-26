_          = require 'lodash'
React      = require 'react/addons'
Draggable  = require 'react-draggable'
classnames = require 'classnames'

Deletable = require './Deletable'

List = React.createClass {
  displayName : 'List'

  propTypes :
    emptyText : React.PropTypes.string
    emptyView : React.PropTypes.element

  getDefaultProps : -> {
    emptyText : 'Nothing to see here.'
  }

  render : ->
    if React.Children.count(@props.children) == 0
      if @props.emptyView
        children = @props.emptyView
      else
        children = <div className='empty-list-text'>{@props.emptyText}</div>
    else
      children = @props.children

    renderableProps = _.omit @props, 'emptyView', 'emptyText'
    <div {...renderableProps} className={classnames 'list', @props.className}>
      {children}
    </div>
}

List.Header = React.createClass {
  displayName : 'List.Header'

  propTypes :
    title : React.PropTypes.string

  render : ->
    if React.Children.count(@props.children) == 0
      children = <span className='text'>{@props.title}</span>
    else
      children = @props.children

    renderableProps = _.omit @props, 'title'
    <div {...renderableProps} className={classnames 'list-header', @props.className}>
      {children}
    </div>
}

List.ItemGroup = React.createClass {
  displayName : 'List.ItemGroup'

  propTypes : {}

  render : ->
    <div {...@props} className={classnames 'list-group', @props.className}>
      {@props.children}
    </div>
}

List.Item = React.createClass {
  displayName : 'List.Item'

  propTypes : {}

  render : ->
    <div {...@props} className={classnames 'list-item', @props.className}>
      {@props.children}
    </div>
}

List.DeletableItem = React.createClass {
  displayName : 'List.DeletableItem'

  propTypes :
    onDelete : React.PropTypes.func.isRequired

  render : ->
    renderableProps = _.omit @props, 'onDelete'
    <List.Item {...renderableProps} className={classnames 'deletable-list-item', @props.className}>
      <Deletable onDelete={@props.onDelete}>
        <div>
          {@props.children}
        </div>
      </Deletable>
    </List.Item>
}

List.AddableItem = React.createClass {
  displayName : 'List.AddableItem'

  propTypes :
    placeholder : React.PropTypes.string
    onAdd       : React.PropTypes.func.isRequired

  getDefaultProps : -> {
    placeholder : 'Add...'
  }

  getInitialState : -> {
    isEditing : false
    value     : ''
  }

  render : ->
    <List.Item className='addable-list-item'>
      <input
        onFocus={@_setEditing}
        onBlur={@_clearEditing}
        onChange={@_setValue}
        value={@state.value}
        placeholder={@props.placeholder}
        type='text'
        autoCorrect='off'
        autoCapitalize='off'
        autoComplete='off'
        spellCheck='false'
        ref='input'
      />
      <i className={classnames 'fa fa-plus', { 'enabled' : @state.isEditing or @state.value }} onTouchTap={@_add}/>
    </List.Item>

  _setEditing : ->
    @setState { isEditing : false }

  _clearEditing : ->
    @setState {
      value     : @state.value.trim()
      isEditing : false
    }

  _setValue : (e) ->
    @setState { value : e.target.value }

  _add : ->
    @props.onAdd @state.value
}

List.headerify = ({ nodes, computeHeaderData, Header, ItemGroup }) ->
  Header    ?= List.Header
  ItemGroup ?= List.ItemGroup

  groupedNodes = []
  for n, i in nodes
    # computeHeaderData must return an object with at least a 'key' field.
    newHeaderData = computeHeaderData n, i
    group = _.last groupedNodes
    if not group? or not _.isEqual(group.headerData, newHeaderData)
      group = {
        headerData : newHeaderData
        items      : []
      }
      groupedNodes.push group
    group.items.push n

  return _.chain groupedNodes
    .map ({ headerData, items }) ->
      return [
        <Header {...headerData}/>
        <ItemGroup {...headerData} key={'group-' + headerData.key}>{items}</ItemGroup>
      ]
    .flatten()
    .value()

List.ClassNames =
  HEADERED    : 'headered-list'
  COLLAPSIBLE : 'collapsible-list'

module.exports = List
