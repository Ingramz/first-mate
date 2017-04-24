class SegmentMatcher
  constructor: (segments) ->
    @segment = segments

  matches: (scope) -> scope is @segment

  toCssSelector: ->
    @segment.split('.').map((dotFragment) ->
      '.' + dotFragment.replace(/\+/g, '\\+')
    ).join('')

  toCssSyntaxSelector: ->
    @segment.split('.').map((dotFragment) ->
      '.syntax--' + dotFragment.replace(/\+/g, '\\+')
    ).join('')

class TrueMatcher
  constructor: ->

  matches: -> true

  toCssSelector: -> '*'

  toCssSyntaxSelector: -> '*'

class ScopeMatcher
  constructor: (first, others) ->
    @segments = [first]
    @segments.push(segment[1]) for segment in others

  matches: (scope) ->
    scopeSegments = scope.split('.')
    return false if scopeSegments.length < @segments.length

    for segment, index in @segments
      return false unless segment.matches(scopeSegments[index])

    true

  toCssSelector: ->
    @segments.map((matcher) -> matcher.toCssSelector()).join('')

  toCssSyntaxSelector: ->
    @segments.map((matcher) -> matcher.toCssSyntaxSelector()).join('')

class PathMatcher
  constructor: (first, others, beginanc, endanc) ->
    @beginanc = beginanc?
    @endanc = endanc?
    @matchers = [first]
    @matchers.push(matcher[1]) for matcher in others

  matches: (scopes) ->
    index = 0
    matcher = @matchers[index]
    for scope in scopes
      matcher = @matchers[++index] if matcher.matches(scope)
      console.log "no", scopes if index is 0 and @beginanc
      console.dir @matchers, {depth: null} if index is 0 and @beginanc
      return false if index is 0 and @beginanc
      return true unless matcher?
    false

  matchesBetween: (lhs, rhs) -> @matches(rhs)

  toCssSelector: ->
    @matchers.map((matcher) -> matcher.toCssSelector()).join(' ')

  toCssSyntaxSelector: ->
    @matchers.map((matcher) -> matcher.toCssSyntaxSelector()).join(' ')

class OrMatcher
  constructor: (@left, @right) ->

  matches: (scopes) -> @left.matches(scopes) or @right.matches(scopes)
  matchesBetween: (lhs, rhs) -> @left.matchesBetween(lhs, rhs) or @right.matchesBetween(lhs, rhs)

  toCssSelector: -> "#{@left.toCssSelector()}, #{@right.toCssSelector()}"

  toCssSyntaxSelector: -> "#{@left.toCssSyntaxSelector()}, #{@right.toCssSyntaxSelector()}"

class AndMatcher
  constructor: (@left, @right) ->

  matches: (scopes) -> @left.matches(scopes) and @right.matches(scopes)
  matchesBetween: (lhs, rhs) -> @left.matchesBetween(lhs, rhs) and @right.matchesBetween(lhs, rhs)

  toCssSelector: ->
    if @right instanceof NegateMatcher
      "#{@left.toCssSelector()}#{@right.toCssSelector()}"
    else
      "#{@left.toCssSelector()} #{@right.toCssSelector()}"

  toCssSyntaxSelector: ->
    if @right instanceof NegateMatcher
      "#{@left.toCssSyntaxSelector()}#{@right.toCssSyntaxSelector()}"
    else
      "#{@left.toCssSyntaxSelector()} #{@right.toCssSyntaxSelector()}"

class FilterMatcher
  constructor: (@filter, @matcher) ->

  matches: (scopes) -> @matcher.matches(scopes)

  matchesBetween: (lhs, rhs) ->
    switch (@filter)
      when 'L' then @matcher.matchesBetween(lhs, lhs)
      when 'R' then @matcher.matchesBetween(rhs, rhs)
      when 'B' then @matcher.matchesBetween(lhs, lhs) and @matcher.matchesBetween(rhs, rhs)

  # FIXME
  toCssSelector: -> ":not(#{@matcher.toCssSelector()})"

  toCssSyntaxSelector: -> ":not(#{@matcher.toCssSyntaxSelector()})"

class NegateMatcher
  constructor: (@matcher) ->

  matches: (scopes) -> not @matcher.matches(scopes)

  matchesBetween: (lhs, rhs) -> not @matcher.matchesBetween(lhs, rhs)

  toCssSelector: -> ":not(#{@matcher.toCssSelector()})"

  toCssSyntaxSelector: -> ":not(#{@matcher.toCssSyntaxSelector()})"

class CompositeMatcher
  constructor: (left, right) ->
    for r in right
      operator = r[0]
      switch operator
        when '|' then left = new OrMatcher(left, r[2])
        when '&' then left = new AndMatcher(left, r[2])
        when '-' then left = new AndMatcher(left, new NegateMatcher(r[2]))
    @matcher = left

  matches: (scopes) -> @matcher.matches(scopes)

  matchesBetween: (lhs, rhs) -> @matcher.matchesBetween(lhs, rhs)

  toCssSelector: -> @matcher.toCssSelector()

  toCssSyntaxSelector: -> @matcher.toCssSyntaxSelector()

module.exports = {
  AndMatcher
  CompositeMatcher
  NegateMatcher
  OrMatcher
  PathMatcher
  ScopeMatcher
  SegmentMatcher
  TrueMatcher
  FilterMatcher
}
