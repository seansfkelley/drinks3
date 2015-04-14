# @cjsx React.DOM

_      = require 'lodash'
React  = require 'react'

FixedHeaderFooter = require '../components/FixedHeaderFooter'
TitleBar          = require '../components/TitleBar'
ButtonBar         = require '../components/ButtonBar'
normalization     = require '../../shared/normalization'

AppDispatcher       = require '../AppDispatcher'
stylingConstants    = require '../stylingConstants'
utils               = require '../utils'
{ IngredientStore } = require '../stores'

IconButton         = require './IconButton'
EditableIngredient = require './EditableIngredient'
EditableIngredient2 = require './EditableIngredient2'

EditableTitleBar = React.createClass {
  displayName : 'EditableTitleBar'

  propTypes :
    onChange : React.PropTypes.func

  render : ->
    <TitleBar>
      <input
        type='text'
        placeholder='Recipe title...'
        autoCorrect='off'
        autoCapitalize='on'
        autoComplete='off'
        spellCheck='false'
        ref='input'
        onChange={@_onChange}
        onTouchTap={@focus}
      />
    </TitleBar>

  getText : ->
    return @refs.input.getDOMNode().value

  focus : ->
    @refs.input.getDOMNode().focus()

  _onChange : ->
    @props.onChange?()
}

EditableFooter = React.createClass {
  displayName : 'EditableFooter'

  propTypes :
    canSave : React.PropTypes.bool
    save    : React.PropTypes.func.isRequired

  getInitialState : ->
    return {
      confirmingClose : false
    }

  render : ->
    if @state.confirmingClose
      closeButton = <ButtonBar.Button icon='fa-exclamation-triangle' label='You Sure?' onTouchTap={@_close}/>
    else
      closeButton = <ButtonBar.Button icon='fa-times' label='Cancel' onTouchTap={@_confirmClose}/>

    <ButtonBar>
      <ButtonBar.Button icon='fa-save' label='Save' disabled={not @props.canSave} onTouchTap={@_save}/>
      {closeButton}
    </ButtonBar>

  _save : ->
    return if not @props.canSave
    @props.save()

  _close : ->
    clearTimeout @_confirmTimeout
    AppDispatcher.dispatch {
      type : 'hide-modal'
    }

  _confirmClose : ->
    @setState { confirmingClose : true }
    @_confirmTimeout = setTimeout @_resetConfirm, 2500

  _resetConfirm : ->
    clearTimeout @_confirmTimeout
    @setState { confirmingClose : false }
}

EditableTextArea = React.createClass {
  displayName : 'EditableTextArea'

  propTypes :
    placeholder : React.PropTypes.string
    onInput     : React.PropTypes.func

  render : ->
    <textarea
      className='editable-text-area'
      placeholder={@props.placeholder}
      onInput={@_onInput}
      ref='textarea'
    />

  getText : ->
    return @refs.textarea.getDOMNode().value

  componentDidMount : ->
    @_sizeToFit()

  # This is kind of crap:
  #   1. Requires a reflow (seems to be the only way to be accurate, though:
  #      https://github.com/andreypopp/react-textarea-autosize/blob/master/index.js)
  #   2. Doesn't use state. Seems bad, but can't prove it.
  _sizeToFit : _.throttle(->
    # +2 is because of the border: avoids a scrollbar.
    node = @getDOMNode()
    node.style.height = 'auto'
    node.style.height = node.scrollHeight + 2
  ), 100

  _onInput : ->
    @_sizeToFit()
    @props.onInput?()
}

DeletableIngredient = React.createClass {
  displayName : 'DeletableIngredient'

  # This requires at least one of tag or description. Not sure how to validate that.
  propTypes :
    measure     : React.PropTypes.string
    unit        : React.PropTypes.string
    tag         : React.PropTypes.string
    description : React.PropTypes.string
    delete      : React.PropTypes.func.isRequired

  render : ->
    <div className='deletable-ingredient'>
      <IconButton iconClass='fa-times' onTouchTap={@_delete}/>
      <div className='measure'>
        {utils.fractionify @props.measure}
        {' '}
        <span className='unit'>{@props.unit}</span>
      </div>
      <span className='ingredient'>{@props.description ? IngredientStore.ingredientsByTag[@props.tag]?.display}</span>
    </div>

  _delete : ->
    @props.delete()
}

EditableRecipeView = React.createClass {
  displayName : 'EditableRecipeView'

  propTypes : {}

  getInitialState : ->
    return {
      ingredients       : []
      currentIngredient : @_newIngredientId()
      saveable          : false
    }

  render : ->
    deletableIngredients = _.map @state.ingredients, (i) =>
      return <DeletableIngredient {...i} key={i.id} delete={@_generateDeleteCallback(i.id)}/>

    editingIngredient = <EditableIngredient key={@state.currentIngredient} saveIngredient={@_saveIngredient}/>

    header = <EditableTitleBar ref='title' onChange={@_computeSaveable}/>
    footer = <EditableFooter canSave={@state.saveable} save={@_saveRecipe}/>

    <FixedHeaderFooter
      className='default-modal editable-recipe-view'
      header={header}
      footer={footer}
    >
      <div className='recipe-description'>
        <div className='recipe-ingredients'>
          {if deletableIngredients.length
            [
              <div className='recipe-section-header' key='deletable-header'>Ingredients</div>
              deletableIngredients
            ]
          }
          <div className='recipe-section-header'>New Ingredient...</div>
          {editingIngredient}
        </div>
        <div className='recipe-instructions'>
          <div className='recipe-section-header'>Instructions</div>
          <EditableTextArea placeholder='Required...' ref='instructions' onInput={@_computeSaveable}/>
        </div>
        <div className='recipe-notes'>
          <div className='recipe-section-header'>Notes</div>
          <EditableTextArea placeholder='Optional...' ref='notes'/>
        </div>
      </div>
    </FixedHeaderFooter>

  componentDidMount : ->
    _.delay (=>
      @refs.title.focus()
    ), stylingConstants.TRANSITION_DURATION + 100

  _saveIngredient : (ingredient) ->
    @setState {
      ingredients       : @state.ingredients.concat [
        _.defaults { id : @state.currentIngredient }, ingredient
      ]
      currentIngredient : @_newIngredientId()
    }

  _generateDeleteCallback : (id) ->
    return =>
      @setState {
        ingredients : _.reject @state.ingredients, { id }
      }

  _newIngredientId : ->
    return _.uniqueId 'ingredient-'

  _computeSaveable : ->
    if not @isMounted()
      saveable = false
    else
      saveable = !!(
        @refs.title.getText().length and
        @refs.instructions.getText().length and
        @state.ingredients.length
      )
    @setState { saveable }

  _saveRecipe : ->
    # Well, doing two things here certainly seems weird. Time for an Action?
    AppDispatcher.dispatch {
      type : 'save-recipe'
      recipe : @_constructRecipe()
    }
    AppDispatcher.dispatch {
      type : 'hide-modal'
    }

  _constructRecipe : ->
    ingredients = _.map @state.ingredients, ({ measure, unit, tag, description }) ->
      return _.pick {
        tag
        displayAmount     : measure
        displayUnit       : unit
        displayIngredient : description or IngredientStore.ingredientsByTag[tag]?.display
      }, _.identity
    return normalization.normalizeRecipe _.pick({
      ingredients
      name         : @refs.title.getText()
      instructions : @refs.instructions.getText()
      notes        : @refs.notes.getText()
    }, _.identity)
}

module.exports = EditableRecipeView
