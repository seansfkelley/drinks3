_      = require 'lodash'
React  = require 'react/addons'

{ IngredientStore, EditableRecipeStore } = require '../stores'

List              = require '../components/List'
FixedHeaderFooter = require '../components/FixedHeaderFooter'
Deletable         = require '../components/Deletable'

FluxMixin = require '../mixins/FluxMixin'

AppDispatcher = require '../AppDispatcher'

MeasuredIngredient = require './MeasuredIngredient'

NavigationHeader = React.createClass {
  displayName : 'NavigationHeader'

  propTypes :
    backTitle : React.PropTypes.string
    goBack    : React.PropTypes.func

  render : ->
    <div className='navigation-header'>
      {if @props.backTitle
        <div className='back-button float-left' onTouchTap={@props.goBack}>
          <i className='fa fa-chevron-left'/>
          <span className='back-button-label'>{@props.backTitle}</span>
        </div>}
      <i className='fa fa-times float-right' onTouchTap={@_closeFlyup}/>
    </div>

  _closeFlyup : ->
    AppDispatcher.dispatch {
      type : 'hide-flyup'
    }
}

EditableNamePage = React.createClass {
  displayName : 'EditableNamePage'

  mixins : [
    FluxMixin EditableRecipeStore, 'name'
  ]

  propTypes :
    next : React.PropTypes.func.isRequired

  render : ->
    <FixedHeaderFooter
      header={<NavigationHeader/>}
      className='editable-recipe-page'
    >
      <div className='name-page'>
        <input
          type='text'
          placeholder='Name...'
          autoCorrect='off'
          autoCapitalize='on'
          autoComplete='off'
          spellCheck='false'
          ref='input'
          defaultValue={@state.name}
          onChange={@_onChange}
          onTouchTap={@focus}
        />
        <i className='fa fa-arrow-right' onTouchTap={@props.next}/>
      </div>
    </FixedHeaderFooter>

  focus : ->
    @refs.input.getDOMNode().focus()

  componentDidMount : ->
    @focus()

  _onChange : (e) ->
    AppDispatcher.dispatch {
      type : 'set-name'
      name : e.target.value
    }
}

EditableIngredient = React.createClass {
  displayName : 'EditableIngredient'

  propTypes :
    defaultValue  : React.PropTypes.string
    addIngredient : React.PropTypes.func.isRequired

  getInitialState : -> {
    tag : null
  }

  render : ->
    if @state.tag?
      ingredientSelector = <List.Item>
        {IngredientStore.ingredientsByTag[@state.tag].display}
        <i className='fa fa-check-circle'/>
      </List.Item>
    else
      ingredientSelector = _.map IngredientStore.allAlphabeticalIngredients, ({ display, tag }) =>
        <List.Item onTouchTap={@_tagSetter tag}>{display}</List.Item>

    <div className='editable-ingredient2'>
      <div className='input-line'>
        <input
          type='text'
          placeholder='ex: 1 oz gin'
          autoCorrect='on'
          autoCapitalize='off'
          autoComplete='off'
          spellCheck='false'
          ref='input'
          defaultValue={@props.defaultValue}
          onChange={@_onChange}
          onTouchTap={@focus}
        />
        <div className='done-button' onTouchTap={@_commit}>Done</div>
      </div>
      <div className='ingredient-list-header'>A Type Of</div>
      <List className='ingredient-group-list'>
        {ingredientSelector}
      </List>
    </div>

  focus : ->
    @refs.input.getDOMNode().focus()

  _tagSetter : (tag) ->
    return =>
      @setState { tag }

  _commit : ->
    @props.addIngredient @refs.input.getDOMNode().value, @state.tag
}

EditableIngredientsPage = React.createClass {
  displayName : 'EditableIngredientsPage'

  mixins : [
    FluxMixin EditableRecipeStore, 'name', 'ingredients'
  ]

  propTypes :
    back : React.PropTypes.func.isRequired
    next : React.PropTypes.func.isRequired

  render : ->
    ingredientNodes = _.map @state.ingredients, (ingredient, index) =>
      if ingredient.isEditing
        return <EditableIngredient
          defaultValue={ingredient.raw}
          addIngredient={@_ingredientAdder index}
          key="index-#{index}"
        />
      else
        return <Deletable
          onDelete={@_ingredientDeleter index}
          key="tag-#{ingredient.tag}"
        >
          <MeasuredIngredient {...ingredient.display}/>
        </Deletable>

    <FixedHeaderFooter
      header={<NavigationHeader backTitle={'"' + @state.name + '"'} goBack={@props.back}/>}
      className='editable-recipe-page'
    >
      <div className='ingredients-page'>
        <div className='ingredients-list'>
          {ingredientNodes}
        </div>
        <div className='new-ingredient-button' onTouchTap={@_addEmptyIngredient}>
          <i className='fa fa-plus-circle'/>
        </div>
        <i className='fa fa-arrow-right' onTouchTap={@props.next}/>
      </div>
    </FixedHeaderFooter>

  _addEmptyIngredient : ->
    AppDispatcher.dispatch {
      type : 'add-ingredient'
    }

  _ingredientAdder : (index) ->
    return (rawText, tag) =>
      AppDispatcher.dispatch {
        type : 'commit-ingredient'
        index
        rawText
        tag
      }

  _ingredientDeleter : (index) ->
    return =>
      AppDispatcher.dispatch {
        type : 'delete-ingredient'
        index
      }
}


EditableTextPage = React.createClass {
  displayName : 'EditableTextPage'

  mixins : [
    FluxMixin EditableRecipeStore, 'ingredients', 'instructions', 'notes'
  ]

  propTypes :
    back : React.PropTypes.func.isRequired
    next : React.PropTypes.func.isRequired

  render : ->
    <FixedHeaderFooter
      header={<NavigationHeader backTitle="#{@state.ingredients.length} ingredients" goBack={@props.back}/>}
      className='editable-recipe-page'
    >
      <div className='text-page'>
        <textarea
          className='editable-text-area'
          placeholder='Instructions...'
          onChange={@_setInstructions}
          value={@state.instructions}
          ref='instructions'
        />
        <textarea
          className='editable-text-area'
          placeholder='Notes (optional)...'
          onChange={@_setNotes}
          value={@state.notes}
          ref='notes'
        />
        <i className='fa fa-arrow-right' onTouchTap={@props.next}/>
      </div>
    </FixedHeaderFooter>

  _setInstructions : (e) ->
    AppDispatcher.dispatch {
      type         : 'set-instructions'
      instructions : e.target.value
    }

  _setNotes : (e) ->
    AppDispatcher.dispatch {
      type  : 'set-notes'
      notes : e.target.value
    }
}

EditableRecipePage =
  NAME        : 'name'
  INGREDIENTS : 'ingredients'
  TEXT        : 'text'

EditableRecipeView = React.createClass {
  displayName : 'EditableRecipeView'

  getInitialState : -> {
    currentPage : EditableRecipePage.NAME
  }

  render : ->
    return switch @state.currentPage
      when EditableRecipePage.NAME
        <EditableNamePage
          next={@_makePageSwitcher(EditableRecipePage.INGREDIENTS)}
        />
      when EditableRecipePage.INGREDIENTS
        <EditableIngredientsPage
          back={@_makePageSwitcher(EditableRecipePage.NAME)}
          next={@_makePageSwitcher(EditableRecipePage.TEXT)}
        />
      when EditableRecipePage.TEXT
        <EditableTextPage
          back={@_makePageSwitcher(EditableRecipePage.INGREDIENTS)}
          next={-> AppDispatcher.dispatch { type : 'hide-flyup' }}
        />

  _makePageSwitcher : (targetPage) ->
    return =>
      @setState { currentPage : targetPage }

}

module.exports = EditableRecipeView

# _saveRecipe : ->
#   # Well, doing two things here certainly seems weird. Time for an Action?
#   AppDispatcher.dispatch {
#     type : 'save-recipe'
#     recipe : @_constructRecipe()
#   }
#   AppDispatcher.dispatch {
#     type : 'hide-modal'
#   }

# _constructRecipe : ->
#   ingredients = _.map @state.ingredientIds, (id) =>
#     { tag, measure, unit, description } = @refs[id].getIngredient()
#     return _.pick {
#       tag
#       displayAmount     : measure
#       displayUnit       : unit
#       displayIngredient : description
#     }, _.identity
#   return normalization.normalizeRecipe _.pick({
#     ingredients
#     name         : @refs.title.getText()
#     instructions : @refs.instructions.getText()
#     notes        : @refs.notes.getText()
#     isCustom     : true
#   }, _.identity)
# }
