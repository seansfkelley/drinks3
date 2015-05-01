_          = require 'lodash'
React      = require 'react/addons'
classnames = require 'classnames'
{ PureRenderMixin } = React.addons

FluxMixin = require '../mixins/FluxMixin'

FixedHeaderFooter  = require '../components/FixedHeaderFooter'
List               = require '../components/List'
TitleBar           = require '../components/TitleBar'

AppDispatcher = require '../AppDispatcher'
{ UiStore }   = require '../stores'

MIXABILITY_FILTERS = [
  type    : 'mixability'
  value   : [ 0 ]
  display : 'Mixable'
,
  type    : 'mixability'
  value   : [ 1, 2 ]
  display : 'Near Mixable'
]

BASE_LIQUOR_FILTERS = [
  'tequila'
  'rum'
  'vodka'
  'liqueur'
  'whiskey'
  'gin'
].map (f) -> {
  type    : 'base-liquor'
  value   : f
  display : _.capitalize f
}

FilterPanel = React.createClass {
  displayName : 'FilterPanel'

  propTypes : {}

  mixins : [
    FluxMixin UiStore, 'recipeFilters'
    PureRenderMixin
  ]

  render : ->
    headerNode = <TitleBar
      rightIcon='fa-chevron-left'
      rightIconOnTouchTap={@_closeFilterPanel}
      title='Favorites'
    />

    <FixedHeaderFooter header={headerNode} className='recipe-filter-list-view'>
      <List className='recipe-filter-list'>
        <List.Header title='Mixability'/>
        {_.map MIXABILITY_FILTERS, @_toFilterListItem}
        <List.Header title='Base Liquor'/>
        {_.map BASE_LIQUOR_FILTERS, @_toFilterListItem}
      </List>
    </FixedHeaderFooter>

  _closeFilterPanel : ->
    AppDispatcher.dispatch {
      type : 'hide-pushover'
    }

  _toggleFilter : (filter) ->
    AppDispatcher.dispatch {
      type : 'toggle-recipe-filter'
      filter
    }

  _toFilterListItem : (f) ->
    <List.Item
      className={classnames 'filter-list-item', { 'selected' : _.findWhere(@state.recipeFilters, f)? }}
      onTouchTap={_.partial @_toggleFilter, f}
      key={"#{f.type}-#{f.value}"}
    >
      {f.display}
    </List.Item>
}

module.exports = FilterPanel
