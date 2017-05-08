(function() {
  var ScopeSelector, ScopeSelectorParser;

  ScopeSelectorParser = require('../lib/scope-selector-parser');

  module.exports = ScopeSelector = (function() {
    function ScopeSelector(source) {
      this.matcher = ScopeSelectorParser.parse(source);
    }

    ScopeSelector.prototype.matches = function(scopes) {
      if (typeof scopes === 'string') {
        scopes = [scopes];
      }
      return this.matcher.matches(scopes);
    };

    ScopeSelector.prototype.matchesBetween = function(lhs, rhs) {
      if (typeof lhs === 'string') {
        lhs = [lhs];
      }
      if (typeof rhs === 'string') {
        rhs = [rhs];
      }
      return this.matcher.matchesBetween(lhs, rhs);
    };

    ScopeSelector.prototype.toCssSelector = function() {
      return this.matcher.toCssSelector();
    };

    ScopeSelector.prototype.toCssSyntaxSelector = function() {
      return this.matcher.toCssSyntaxSelector();
    };

    return ScopeSelector;

  })();

}).call(this);
