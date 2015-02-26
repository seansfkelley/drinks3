# @cjsx React.DOM

_     = require 'lodash'
React = require 'react'

FluxMixin           = require './FluxMixin'
AppDispatcher       = require './AppDispatcher'
{ IngredientStore } = require './stores'

TabbedView        = require './TabbedView'
StickyHeaderMixin = require './StickyHeaderMixin'

IngredientListItem = React.createClass {
  mixins : [
    FluxMixin IngredientStore, 'selectedIngredientTags'
  ]

  render : ->
    className = 'ingredient-list-item list-item'
    iconClassName = 'ingredient-icon fa'

    if @state.selectedIngredientTags[@props.ingredient.tag]
      className += ' is-selected'
      # This icon is pretty shit, but at least it has an accompanying empty form.
      iconClassName += ' fa-check-circle-o'
    else
      iconClassName += ' fa-circle-o'

    <div className={className} onTouchTap={@_toggleIngredient}>
      <i className={iconClassName}/>
      <div className='name'>{@props.ingredient.display}</div>
    </div>

  _toggleIngredient : ->
    AppDispatcher.dispatch {
      type : 'toggle-ingredient'
      tag  : @props.ingredient.tag
    }
}

AlphabeticalIngredientList = React.createClass {
  mixins : [
    FluxMixin IngredientStore, 'alphabeticalIngredients'
    StickyHeaderMixin
  ]

  render : ->
    return @generateList {
      data        : @state.alphabeticalIngredients
      getTitle    : (ingredient) -> ingredient.display[0].toUpperCase()
      createChild : (ingredient) -> <IngredientListItem ingredient={ingredient} key={ingredient.tag}/>
      classNames  : 'ingredient-list alphabetical'
    }
}

GroupedIngredientList = React.createClass {
  mixins : [
    FluxMixin IngredientStore, 'groupedIngredients'
    StickyHeaderMixin
  ]

  render : ->
    data = _.chain @state.groupedIngredients
      .map ({ name, ingredients }) ->
        _.map ingredients, (i) -> [ name, i ]
      .flatten()
      .value()

    return @generateList {
      data        : data
      getTitle    : ([ name, ingredient ]) -> name
      createChild : ([ name, ingredient ]) -> <IngredientListItem ingredient={ingredient} key={ingredient.tag}/>
      classNames  : 'ingredient-list grouped'
    }
}

tabs = [
  icon    : 'glass'
  title   : 'By Name'
  content : <AlphabeticalIngredientList/>
,
  icon    : 'glass'
  title   : 'By Group'
  content : <GroupedIngredientList/>
]

IngredientSelectionPage = React.createClass {
  render : ->
    <TabbedView tabs={tabs}/>
}

module.exports = IngredientSelectionPage
