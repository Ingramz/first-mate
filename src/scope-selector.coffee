ScopeSelectorParser = require '../lib/scope-selector-parser'

module.exports =
class ScopeSelector
  # Create a new scope selector.
  #
  # source - A {String} to parse as a scope selector.
  constructor: (source) -> @matcher = ScopeSelectorParser.parse(source)

  # Check if this scope selector matches the scopes.
  #
  # scopes - An {Array} of {String}s or a single {String}.
  #
  # Returns a {Boolean}.
  matches: (scopes) ->
    scopes = [scopes] if typeof scopes is 'string'
    @matcher.matches(scopes)

  matchesBetween: (lhs, rhs) ->
    lhs = [lhs] if typeof lhs is 'string'
    rhs = [rhs] if typeof rhs is 'string'
    @matcher.matchesBetween(lhs, rhs)

  # Convert this TextMate scope selector to a CSS selector.
  #
  # Returns a {String}.
  toCssSelector: -> @matcher.toCssSelector()

  # Convert this TextMate scope selector to a CSS selector, prefixing scopes with `syntax--`.
  #
  # Returns a {String}.
  toCssSyntaxSelector: -> @matcher.toCssSyntaxSelector()
