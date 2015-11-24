_               = require 'lodash'
React           = require 'react'
classnames      = require 'classnames'
PureRenderMixin = require 'react-addons-pure-render-mixin'

store = require '../store'

definitions = require '../../shared/definitions'

RecipeListSelector = React.createClass {
  displayName : 'RecipeListSelector'

  propTypes :
    currentType : React.PropTypes.string
    onClose     : React.PropTypes.func

  mixins : [ PureRenderMixin ]

  render : ->
    reorderedOptions = _.flatten [
      @props.currentType
      _.without definitions.RECIPE_LIST_TYPES, @props.currentType
    ]

    options = _.map reorderedOptions, (type) =>
      <div
        key={type}
        className={classnames 'option', { 'is-selected' : type == @props.currentType }}
        onTouchTap={@_onOptionSelect.bind(null, type)}
      >
        <span className='label'>{definitions.RECIPE_LIST_NAMES[type]}</span>
      </div>

    <div className='recipe-list-selector'>
      {options}
    </div>

  _onOptionSelect : (listType) ->
    store.dispatch {
      type : 'set-selected-recipe-list'
      listType
    }
    @props.onClose()
}

module.exports = RecipeListSelector
