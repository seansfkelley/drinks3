React      = require 'react/addons'
classnames = require 'classnames'

{ PureRenderMixin } = React.addons

SearchBar = React.createClass {
  displayName : 'SearchBar'

  propTypes :
    onChange    : React.PropTypes.func.isRequired
    placeholder : React.PropTypes.string

  mixins : [ PureRenderMixin ]

  getInitialState : -> {
    value : ''
  }

  render : ->
    <div className={classnames 'search-bar', @props.className}  onTouchStart={@_stopTouchStart}>
      <i className='fa fa-search'/>
      <input
        type='text'
        className='search-input'
        placeholder={@props.placeholder}
        value={@state.value}
        onChange={@_onChange}
        onTouchTap={@focus}
        ref='input'
        tabIndex=-1
        autoCorrect='off'
        autoCapitalize='off'
        autoComplete='off'
        spellCheck='false'
      />
      {if @state.value.length
        <i className='fa fa-times-circle' onTouchTap={@clearAndFocus} onTouchStart={@_stopTouchStart}/>}
    </div>

  clearAndFocus : ->
    @clear()
    @focus()

  clear : ->
    @setState { value : '' }
    @props.onChange ''

  focus : ->
    @refs.input.getDOMNode().focus()

  isFocused : ->
    return document.activeElement == @refs.input.getDOMNode()

  _onChange : (e) ->
    @setState { value : e.target.value }
    @props.onChange e.target.value

  _stopTouchStart : (e) ->
    # This is hacky, but both of these are independently necessary.
    # 1. Stop propagation so that the App-level handler doesn't deselect the input on clear.
    e.stopPropagation()
    # 2. Prevent default so that iOS doesn't reassign the active element and deselect the input.
    e.preventDefault()
}

module.exports = SearchBar
