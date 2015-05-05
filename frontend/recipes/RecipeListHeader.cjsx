_          = require 'lodash'
React      = require 'react/addons'
classnames = require 'classnames'

{ PureRenderMixin } = React.addons

FluxMixin = require '../mixins/FluxMixin'

TitleBar = require '../components/TitleBar'
Swipable = require '../components/Swipable'

AppDispatcher = require '../AppDispatcher'

{ UiStore, IngredientStore } = require '../stores'

EditableRecipeView = require './EditableRecipeView'
FavoritesList      = require '../favorites/FavoritesList'

MIXABILITY_FILTER_NAMES = {
  mixable          : 'Mixable'
  nearMixable      : 'Nearly'
  notReallyMixable : '3+ Missing'
}

RecipeListHeader = React.createClass {
  displayName : 'RecipeListHeader'

  mixins : [
    FluxMixin UiStore, 'mixabilityFilters', 'baseLiquorFilter'
    FluxMixin IngredientStore, 'baseLiquors'
    PureRenderMixin
  ]

  render : ->
    initialBaseLiquorIndex = _.indexOf @state.baseLiquors, @state.baseLiquorFilter
    if initialBaseLiquorIndex == -1
      initialBaseLiquorIndex = 0

    <div>
      <TitleBar
        leftIcon='fa-star'
        leftIconOnTouchTap={@_openFavoritesList}
        rightIcon='fa-plus'
        rightIconOnTouchTap={@_newRecipe}
        className='recipe-list-header'
      >
        <div className='mixability-selector'>
          {for key, setting of @state.mixabilityFilters
            <div
              className={classnames 'option', { 'selected' : setting }}
              onTouchTap={_.partial @_onMixabilityFilterChange, key}
              key={key}
            >
              {MIXABILITY_FILTER_NAMES[key]}
            </div>}
        </div>
      </TitleBar>
      <Swipable
        className='base-liquor-container'
        initialIndex={initialBaseLiquorIndex}
        onSlideChange={@_onBaseLiquorChange}
      >
        {for base in @state.baseLiquors
          <div
            className={classnames 'base-liquor-option', { 'selected' : base == @state.baseLiquorFilter }}
            key={base}
          >
            {base}
          </div>}
      </Swipable>
    </div>

  _onMixabilityFilterChange : (filter) ->
    AppDispatcher.dispatch {
      type   : 'toggle-mixability-filter'
      filter
    }

  _onBaseLiquorChange : (index) ->
    AppDispatcher.dispatch {
      type   : 'set-base-liquor-filter'
      filter : @state.baseLiquors[index]
    }

  _newRecipe : ->
    AppDispatcher.dispatch {
      type      : 'show-modal'
      component : <EditableRecipeView/>
    }

  _openFavoritesList : ->
    AppDispatcher.dispatch {
      type      : 'show-pushover'
      component : <FavoritesList/>
    }
}

module.exports = RecipeListHeader
