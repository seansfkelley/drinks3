_          = require 'lodash'
$          = require 'jquery'
MicroEvent = require 'microevent'
Promise    = require 'bluebird'

AppDispatcher = require './AppDispatcher'
RecipeSearch   = require './RecipeSearch'

class FluxStore
  MicroEvent.mixin this

  constructor : ->
    _.extend @, _.result(@, 'fields')

    @dispatchToken = AppDispatcher.register (payload) =>
      if this[payload.type]?
        this[payload.type](payload)
        @trigger 'change'

      return true

INGREDIENTS_KEY = 'drinks-app-ingredients'

IngredientStore = new class extends FluxStore
  fields : ->
    alphabeticalIngredients : []
    groupedIngredients      : []
    selectedIngredientTags  : JSON.parse(localStorage[INGREDIENTS_KEY] ? 'null') ? {}

  'set-ingredients' : ({ alphabetical, grouped }) ->
    @alphabeticalIngredients = alphabetical
    @groupedIngredients      = grouped

  'toggle-ingredient' : ({ tag }) ->
    if @selectedIngredientTags[tag]?
      delete @selectedIngredientTags[tag]
    else
      @selectedIngredientTags[tag] = true
    localStorage[INGREDIENTS_KEY] = JSON.stringify @selectedIngredientTags

FUZZY_MATCH = 2

RecipeStore = new class extends FluxStore
  fields : ->
    alphabeticalRecipes   : []
    groupedMixableRecipes : []

  'set-ingredients' : ({ alphabetical, grouped }) ->
    AppDispatcher.waitFor [ IngredientStore.dispatchToken ]
    @_createRecipeSearch()
    @_updateMixableRecipes()

  'set-recipes' : ({ recipes }) ->
    @alphabeticalRecipes = recipes
    @_createRecipeSearch()
    @_updateMixableRecipes()

  'toggle-ingredient' : ->
    AppDispatcher.waitFor [ IngredientStore.dispatchToken ]
    @_updateMixableRecipes()

  _createRecipeSearch : ->
    @_recipeSearch = new RecipeSearch IngredientStore.alphabeticalIngredients, @alphabeticalRecipes

  _updateMixableRecipes : ->
    selectedTags = _.keys IngredientStore.selectedIngredientTags
    @groupedMixableRecipes = _.map @_recipeSearch.computeMixableRecipes(selectedTags, FUZZY_MATCH), (recipes, missingCount) ->
      name = switch +missingCount
        when 0 then 'Mixable Drinks'
        when 1 then 'With 1 More Ingredient'
        else "With #{missingCount} More Ingredients"
      recipes = _.sortBy recipes, 'name'
      return { name, recipes }

Promise.resolve $.get('/ingredients')
.then ({ alphabetical, grouped }) =>
  AppDispatcher.dispatch {
    type : 'set-ingredients'
    alphabetical
    grouped
  }

Promise.resolve $.get('/recipes')
.then (recipes) =>
  AppDispatcher.dispatch {
    type : 'set-recipes'
    recipes
  }

module.exports = {
  IngredientStore
  RecipeStore
}

_.extend (window.debug ?= {}), module.exports
