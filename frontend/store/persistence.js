const _   = require('lodash');
const log = require('loglevel');

const ONE_MINUTE_MS    = 1000 * 60;
const LOCALSTORAGE_KEY = 'drinks-app-persistence';
const PERSISTENCE_SPEC = {
  filters : {
    recipeSearchTerm       : ONE_MINUTE_MS * 5,
    baseLiquorFilter       : ONE_MINUTE_MS * 15,
    selectedIngredientTags : Infinity,
    selectedRecipeList     : ONE_MINUTE_MS * 60
  },
  recipes : {
    customRecipeIds : Infinity
  },
  ui : {
    errorMessage             : 0,
    recipeViewingIndex       : ONE_MINUTE_MS * 5,
    currentlyViewedRecipeIds : ONE_MINUTE_MS * 5,
    favoritedRecipeIds       : Infinity,
    showingRecipeViewer      : ONE_MINUTE_MS * 5,
    showingRecipeEditor      : Infinity,
    showingSidebar           : ONE_MINUTE_MS * 5,
    showingListSelector      : ONE_MINUTE_MS
  },
  editableRecipe : {
    originalRecipeId : Infinity,
    currentPage      : Infinity,
    name             : Infinity,
    ingredients      : Infinity,
    instructions     : Infinity,
    notes            : Infinity,
    base             : Infinity,
    saving           : 0
  }
};

const watch = store =>
  store.subscribe(_.debounce((function() {
    const state = store.getState();

    const data = _.mapValues(PERSISTENCE_SPEC, (spec, storeName) => _.pick(state[storeName], _.keys(spec)));

    const timestamp = Date.now();
    localStorage[LOCALSTORAGE_KEY] = JSON.stringify({ data, timestamp });

    return log.debug(`persisted data at t=${timestamp}`);
  }), 1000)
  )
;

const load = _.once(function() {
  const { data, timestamp } = JSON.parse(localStorage[LOCALSTORAGE_KEY] != null ? localStorage[LOCALSTORAGE_KEY] : '{}');

  if (data == null) {
    // Legacy version.
    const ui          = JSON.parse(localStorage['drinks-app-ui'] != null ? localStorage['drinks-app-ui'] : '{}');
    const recipes     = JSON.parse(localStorage['drinks-app-recipes'] != null ? localStorage['drinks-app-recipes'] : '{}');
    const ingredients = JSON.parse(localStorage['drinks-app-ingredients'] != null ? localStorage['drinks-app-ingredients'] : '{}');

    return _.mapValues({
      filters : {
        recipeSearchTerm       : recipes.searchTerm,
        baseLiquorFilter       : ui.baseLiquorFilter,
        selectedIngredientTags : ingredients.selectedIngredientTags
      },
      recipes : {
        customRecipes : recipes.customRecipes
      },
      ui : {
        recipeViewingIndex : ui.recipeViewingIndex
      }
    }, store => _.omit(store, _.isUndefined));
  } else {
    const elapsedTime = Date.now() - +(timestamp != null ? timestamp : 0);

    return _.mapValues(PERSISTENCE_SPEC, (spec, storeName) =>
      _.chain(data[storeName])
        .pick(_.keys(spec))
        .pick((_, key) => elapsedTime < spec[key])
        .omit(_.isUndefined)
        .value()
    );
  }
});

module.exports = { watch, load };
