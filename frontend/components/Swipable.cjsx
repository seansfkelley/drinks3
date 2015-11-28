_               = require 'lodash'
React           = require 'react'
ReactDom        = require 'react-dom'
classnames      = require 'classnames'
PureRenderMixin = require 'react-addons-pure-render-mixin'

IntertialSwipeLogicBox = require './IntertialSwipeLogicBox'

IntertialSwipable = React.createClass {
  displayName : 'IntertialSwipable'

  propTypes :
    onSwiping       : React.PropTypes.func
    onSwiped        : React.PropTypes.func
    initialDelta    : React.PropTypes.number
    getNearestIndex : React.PropTypes.func
    itemOffsets     : React.PropTypes.array.isRequired
    friction        : React.PropTypes.number

  mixins : [ PureRenderMixin ]

  render : ->
    <div
      onTouchStart={@_onTouchStart}
      onTouchMove={@_onTouchMove}
      onTouchEnd={@_onTouchEnd}
      className={classnames 'inertial-swipable', @props.className}
    >
      {@props.children}
    </div>

  _onTouchStart : (e) ->
    @_logicBox.onTouchStart e

  _onTouchMove : (e) ->
    @_logicBox.onTouchMove e

  _onTouchEnd : (e) ->
    @_logicBox.onTouchEnd e

  componentDidMount : ->
    @_logicBox = new IntertialSwipeLogicBox {
      itemOffsets     : @props.itemOffsets
      getNearestIndex : @props.getNearestIndex
      onChangeDelta   : @props.onSwiping
      onFinish        : @props.onSwiped
      initialDelta    : @props.initialDelta
      amplitudeFactor : if @props.friction then 1 - @props.friction
    }

  componentWillReceiveProps : (nextProps) ->
    if not _.isEqual(nextProps.itemOffsets, @props.itemOffsets)
      @_logicBox?.destroy()
      @_logicBox = new IntertialSwipeLogicBox {
        itemOffsets     : nextProps.itemOffsets
        getNearestIndex : @props.getNearestIndex
        onChangeDelta   : nextProps.onSwiping
        onFinish        : nextProps.onSwiped
        initialDelta    : nextProps.initialDelta
        amplitudeFactor : if @props.friction then 1 - @props.friction
      }
    else if nextProps.initialDelta != @props.initialDelta
      @_logicBox?.setDeltaInstantly nextProps.initialDelta

  componentWillUnmount : ->
    @_logicBox?.destroy()
}


Swipable = React.createClass {
  displayName : 'Swipable'

  propTypes :
    initialIndex  : React.PropTypes.number
    onSlideChange : React.PropTypes.func
    friction      : React.PropTypes.number

  mixins : [ PureRenderMixin ]

  getInitialState : ->
    zeroes = _.map _.range(React.Children.count(@props.children)), -> 0
    return {
      wrapperWidth : 0
      itemWidths   : zeroes
      itemOffsets  : zeroes
      delta        : 0
      initialDelta : 0
    }

  _getIndexForDelta : (delta) ->
    # return _.sortedIndex(@state.itemOffsets, delta)
    shiftedOffsets = _.chain()
      .range(@state.itemOffsets.length)
      .map (i) => @state.itemOffsets[i] - @state.itemWidths[i] / 2
      .value()
    # Why is this -1 again?
    return Math.max 0, _.sortedIndex(shiftedOffsets, delta) - 1

  render : ->
    offset = -@state.delta + (@state.wrapperWidth - @state.itemWidths[0]) / 2

    <IntertialSwipable
      onSwiping={@_onSwiping}
      onSwiped={@_onSwiped}
      itemOffsets={@state.itemOffsets}
      initialDelta={@state.initialDelta}
      getNearestIndex={@_getNearestIndex}
      friction={@props.friction}
      className={classnames 'viewport-container', @props.className}
    >
      <div
        className='sliding-container'
        ref='slidingContainer'
        style={{
          WebkitTransform : "translateX(#{offset}px) translateZ(0)" # Hardware acceleration.
          transform       : "translateX(#{offset}px)"
        }}
      >
        {@props.children}
      </div>
    </IntertialSwipable>

  # componentDidUpdate : ->
  #   @_computeCachedState()

  componentDidMount: ->
    @_computeCachedState()

  _computeCachedState : ->
    wrapperWidth = ReactDom.findDOMNode(@refs.slidingContainer).offsetWidth
    itemWidths   = _.pluck ReactDom.findDOMNode(@refs.slidingContainer).children, 'offsetWidth'
    itemOffsets  = _.chain itemWidths
      .reduce ((offsets, width) ->
        offsets.push _.last(offsets) + width
        return offsets
      ), [ 0 ]
      .initial()
      .value()
    initialDelta = itemOffsets[@props.initialIndex ? 0]
    @setState { wrapperWidth, itemWidths, itemOffsets, initialDelta }

  _getNearestIndex : (e) ->
    target = e.target
    slidingContainer = ReactDom.findDOMNode @refs.slidingContainer
    while target.parentNode != slidingContainer
      target = target.parentNode
    return _.indexOf(slidingContainer.children, target)

  _onSwiping : (delta) ->
    oldIndex = @_getIndexForDelta @state.delta
    newIndex = @_getIndexForDelta delta
    @setState { delta }
    if oldIndex != newIndex
      @props.onSlideChange newIndex

  _onSwiped : ->
    index = @_getIndexForDelta @state.delta
    @setState { initialDelta : @state.itemOffsets[index] }
    # Leaving this here for posterity, but, I think it's a safe bet
    # that the index hasn't changed between the last onSwiping call
    # and this, so don't call it twice in a row.
    # @props.onSlideChange index
}

module.exports = Swipable
