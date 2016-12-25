import * as React from 'react';
import * as PureRenderMixin from 'react-addons-pure-render-mixin';

import EditableRecipePage from './EditableRecipePage';

import RecipeView from '../recipes/RecipeView';

export default React.createClass({
  displayName: 'PreviewPage',

  propTypes: {
    onClose: React.PropTypes.func.isRequired,
    onNext: React.PropTypes.func,
    onPrevious: React.PropTypes.func,
    previousTitle: React.PropTypes.string,
    recipe: React.PropTypes.object,
    isSaving: React.PropTypes.bool
  },

  mixins: [PureRenderMixin],

  render() {
    let nextButton;
    if (this.props.isSaving) {
      nextButton = <div className='next-button fixed-footer'><span className='next-text'>Saving</span><i className='fa fa-refresh fa-spin' /></div>;
    } else {
      nextButton = <div className='next-button fixed-footer' onClick={this.props.onNext}><span className='next-text'>Done</span><i className='fa fa-check' /></div>;
    }

    return <EditableRecipePage className='preview-page' onClose={this.props.onClose} onPrevious={this.props.onPrevious} previousTitle={this.props.previousTitle}><div className='fixed-content-pane'><RecipeView recipe={this.props.recipe} /></div>{nextButton}</EditableRecipePage>;
  }
});


