ScopeSelector = require '../lib/scope-selector'

describe "ScopeSelector", ->
  describe ".matches(scopes)", ->
    it "passes textmate tests", ->
      #void test_child_selector ()
      expect(new ScopeSelector('foo fud').matches(['foo', 'bar', 'fud'])).toBeTruthy()
      expect(new ScopeSelector('foo > fud').matches(['foo', 'bar', 'fud'])).toBeFalsy()
      expect(new ScopeSelector('foo > foo > fud').matches(['foo', 'foo', 'fud'])).toBeTruthy()
      expect(new ScopeSelector('foo > foo > fud').matches(['foo', 'foo', 'fud', 'fud'])).toBeTruthy()
      expect(new ScopeSelector('foo > foo > fud').matches(['foo', 'foo', 'fud', 'baz'])).toBeTruthy()
      expect(new ScopeSelector('foo > foo fud > fud').matches(['foo', 'foo', 'bar', 'fud', 'fud'])).toBeTruthy()
      #void test_mixed ()
      expect(new ScopeSelector('^ foo > bar').matches(["foo", "bar", "foo"])).toBeTruthy()
      expect(new ScopeSelector('foo > bar $').matches(["foo", "bar", "foo"])).toBeFalsy()
      expect(new ScopeSelector('bar > foo $').matches(["foo", "bar", "foo"])).toBeTruthy()
      expect(new ScopeSelector('foo > bar > foo $').matches(["foo", "bar", "foo"])).toBeTruthy()
      expect(new ScopeSelector('^ foo > bar > foo $').matches(["foo", "bar", "foo"])).toBeTruthy()
      expect(new ScopeSelector('bar > foo $').matches(["foo", "bar", "foo"])).toBeTruthy()
      expect(new ScopeSelector('^ foo > bar > baz').matches(["foo", "bar", "baz", "foo", "bar", "baz"])).toBeTruthy()
      expect(new ScopeSelector('^ foo > bar > baz').matches(["foo", "foo", "bar", "baz", "foo", "bar", "baz"])).toBeFalsy()
      #void test_dollar ()
      dyn = ["foo", "bar", "dyn.selection"]
      expect(new ScopeSelector("foo bar$").matches(dyn)).toBeTruthy()
      expect(new ScopeSelector("foo bar dyn$").matches(dyn)).toBeFalsy()
      expect(new ScopeSelector("foo bar dyn").matches(dyn)).toBeTruthy()
      #void test_anchor ()
      expect(new ScopeSelector("^ foo").matches(["foo", "bar"])).toBeTruthy()
      expect(new ScopeSelector("^ bar").matches(["foo", "bar"])).toBeFalsy()
      expect(new ScopeSelector("^ foo").matches(["foo", "bar", "foo"])).toBeTruthy()
      expect(new ScopeSelector("foo $").matches(["foo", "bar"])).toBeFalsy()
      expect(new ScopeSelector("bar $").matches(["foo", "bar"])).toBeTruthy()
      #void test_scope_selector ()
      textScope = ['text.html.markdown', 'meta.paragraph.markdown', 'markup.bold.markdown']
      matchingSelectors = [
        "text.* markup.bold",
        "text markup.bold",
        "markup.bold",
        "text.html meta.*.markdown markup",
        "text.html meta.* markup",
        "text.html * markup",
        "text.html markup",
        "text markup",
        "markup",
        "text.html",
        "text"
      ]
      for selector in matchingSelectors
        expect(new ScopeSelector(selector).matches(textScope)).toBeTruthy()
      #void test_rank ()
      leftScope  = ["text.html.php", "meta.embedded.block.php", "source.php", "comment.block.php"]
      rightScope = ["text.html.php", "meta.embedded.block.php", "source.php"]
      globalSelector = "comment.block | L:comment.block"
      phpSelector    = "L:source.php - string"
      expect(new ScopeSelector(globalSelector).matchesBetween(leftScope, rightScope)).toBeTruthy()
      expect(new ScopeSelector(phpSelector).matchesBetween(leftScope, rightScope)).toBeTruthy()
      #void test_match ()
      match = (sel, scope) -> new ScopeSelector(sel).matches(scope.split(' '))
      expect( match("foo",                  "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("foo bar",              "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("foo bar baz",          "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("foo baz",              "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("foo.*",                "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("foo.qux",              "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("foo.qux baz.*.garply", "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("bar",                  "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect(!match("foo qux",              "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect(!match("foo.bar",              "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect(!match("foo.qux baz.garply",   "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect(!match("bar.*.baz",            "foo.qux bar.quux.grault baz.corge.garply")).toBeTruthy()
      expect( match("foo > bar",             "foo bar baz bar baz")).toBeTruthy()
      expect( match("bar > baz",             "foo bar baz bar baz")).toBeTruthy()
      expect( match("foo > bar baz",         "foo bar baz bar baz")).toBeTruthy()
      expect( match("foo bar > baz",         "foo bar baz bar baz")).toBeTruthy()
      expect( match("foo > bar > baz",       "foo bar baz bar baz")).toBeTruthy()
      expect( match("foo > bar bar > baz",   "foo bar baz bar baz")).toBeTruthy()
      expect(!match("foo > bar > bar > baz", "foo bar baz bar baz")).toBeTruthy()
      expect( match("baz $",                 "foo bar baz bar baz")).toBeTruthy()
      expect( match("bar > baz $",           "foo bar baz bar baz")).toBeTruthy()
      expect( match("bar > baz $",           "foo bar baz bar baz")).toBeTruthy()
      expect( match("foo bar > baz $",       "foo bar baz bar baz")).toBeTruthy()
      expect( match("foo > bar > baz",       "foo bar baz bar baz")).toBeTruthy()
      expect(!match("foo > bar > baz $",     "foo bar baz bar baz")).toBeTruthy()
      expect(!match("bar $",                 "foo bar baz bar baz")).toBeTruthy()
      expect( match("baz $",                 "foo bar baz bar baz dyn.qux")).toBeTruthy()
      expect( match("bar > baz $",           "foo bar baz bar baz dyn.qux")).toBeTruthy()
      expect( match("bar > baz $",           "foo bar baz bar baz dyn.qux")).toBeTruthy()
      expect( match("foo bar > baz $",       "foo bar baz bar baz dyn.qux")).toBeTruthy()
      expect(!match("foo > bar > baz $",     "foo bar baz bar baz dyn.qux")).toBeTruthy()
      expect(!match("bar $",                 "foo bar baz bar baz dyn.qux")).toBeTruthy()
      expect( match("^ foo",                 "foo bar foo bar baz")).toBeTruthy()
      expect( match("^ foo > bar",           "foo bar foo bar baz")).toBeTruthy()
      expect( match("^ foo bar > baz",       "foo bar foo bar baz")).toBeTruthy()
      expect( match("^ foo > bar baz",       "foo bar foo bar baz")).toBeTruthy()
      expect(!match("^ foo > bar > baz",     "foo bar foo bar baz")).toBeTruthy()
      expect(!match("^ bar",                 "foo bar foo bar baz")).toBeTruthy()
      expect( match("foo > bar > baz",       "foo bar baz foo bar baz")).toBeTruthy()
      expect( match("^ foo > bar > baz",     "foo bar baz foo bar baz")).toBeTruthy()
      expect( match("foo > bar > baz $",     "foo bar baz foo bar baz")).toBeTruthy()
      expect(!match("^ foo > bar > baz $",   "foo bar baz foo bar baz")).toBeTruthy()

    it "matches the asterisk", ->
      expect(new ScopeSelector('*').matches(['a'])).toBeTruthy()
      expect(new ScopeSelector('*').matches(['b', 'c'])).toBeTruthy()
      expect(new ScopeSelector('a.*.c').matches(['a.b.c'])).toBeTruthy()
      expect(new ScopeSelector('a.*.c').matches(['a.b.c.d'])).toBeTruthy()
      expect(new ScopeSelector('a.*.c').matches(['a.b.d.c'])).toBeFalsy()

    it "matches segments", ->
      expect(new ScopeSelector('a').matches(['a'])).toBeTruthy()
      expect(new ScopeSelector('a').matches(['a.b'])).toBeTruthy()
      expect(new ScopeSelector('a.b').matches(['a.b.c'])).toBeTruthy()
      expect(new ScopeSelector('a').matches(['abc'])).toBeFalsy()
      expect(new ScopeSelector('a.b-c').matches(['a.b-c.d'])).toBeTruthy()
      expect(new ScopeSelector('a.b').matches(['a.b-d'])).toBeFalsy()
      expect(new ScopeSelector('c++').matches(['c++'])).toBeTruthy()
      expect(new ScopeSelector('c++').matches(['c'])).toBeFalsy()
      expect(new ScopeSelector('a_b_c').matches(['a_b_c'])).toBeTruthy()
      expect(new ScopeSelector('a_b_c').matches(['a_b'])).toBeFalsy()

    it "matches prefixes", ->
      expect(new ScopeSelector('R:g').matches(['g'])).toBeTruthy()
      expect(new ScopeSelector('R:g').matches(['R:g'])).toBeFalsy()

    it "matches disjunction", ->
      expect(new ScopeSelector('a | b').matches(['b'])).toBeTruthy()
      expect(new ScopeSelector('a|b|c').matches(['c'])).toBeTruthy()
      expect(new ScopeSelector('a|b|c').matches(['d'])).toBeFalsy()

    it "matches negation", ->
      expect(new ScopeSelector('a - c').matches(['a', 'b'])).toBeTruthy()
      expect(new ScopeSelector('a - c').matches(['a'])).toBeTruthy()
      expect(new ScopeSelector('-c').matches(['b'])).toBeTruthy()
      expect(new ScopeSelector('-c').matches(['c', 'b'])).toBeFalsy()
      expect(new ScopeSelector('a-b').matches(['a', 'b'])).toBeFalsy()
      expect(new ScopeSelector('a -b').matches(['a', 'b'])).toBeFalsy()
      expect(new ScopeSelector('a -c').matches(['a', 'b'])).toBeTruthy()
      expect(new ScopeSelector('a-c').matches(['a', 'b'])).toBeFalsy()

    it "matches conjunction", ->
      expect(new ScopeSelector('a & b').matches(['b', 'a'])).toBeTruthy()
      expect(new ScopeSelector('a&b&c').matches(['c'])).toBeFalsy()
      expect(new ScopeSelector('a&b&c').matches(['a', 'b', 'd'])).toBeFalsy()
      expect(new ScopeSelector('a & -b').matches(['a', 'b', 'd'])).toBeFalsy()
      expect(new ScopeSelector('a & -b').matches(['a', 'd'])).toBeTruthy()

    it "matches composites", ->
      expect(new ScopeSelector('a,b,c').matches(['b', 'c'])).toBeTruthy()
      expect(new ScopeSelector('a, b, c').matches(['d', 'e'])).toBeFalsy()
      expect(new ScopeSelector('a, b, c').matches(['d', 'c.e'])).toBeTruthy()
#      expect(new ScopeSelector('a,').matches(['a', 'c'])).toBeTruthy()
#      expect(new ScopeSelector('a,').matches(['b', 'c'])).toBeFalsy()

    it "matches groups", ->
      expect(new ScopeSelector('(a,b) | (c, d)').matches(['a'])).toBeTruthy()
      expect(new ScopeSelector('(a,b) | (c, d)').matches(['b'])).toBeTruthy()
      expect(new ScopeSelector('(a,b) | (c, d)').matches(['c'])).toBeTruthy()
      expect(new ScopeSelector('(a,b) | (c, d)').matches(['d'])).toBeTruthy()
      expect(new ScopeSelector('(a,b) | (c, d)').matches(['e'])).toBeFalsy()

    it "matches paths", ->
      expect(new ScopeSelector('a b').matches(['a', 'b'])).toBeTruthy()
      expect(new ScopeSelector('a b').matches(['b', 'a'])).toBeFalsy()
      expect(new ScopeSelector('a c').matches(['a', 'b', 'c', 'd', 'e'])).toBeTruthy()
      expect(new ScopeSelector('a b e').matches(['a', 'b', 'c', 'd', 'e'])).toBeTruthy()

    it "accepts a string scope parameter", ->
      expect(new ScopeSelector('a|b').matches('a')).toBeTruthy()
      expect(new ScopeSelector('a|b').matches('b')).toBeTruthy()
      expect(new ScopeSelector('a|b').matches('c')).toBeFalsy()
      expect(new ScopeSelector('test').matches('test')).toBeTruthy()

  describe ".toCssSelector()", ->
    it "converts the TextMate scope selector to a CSS selector", ->
      expect(new ScopeSelector('a b c').toCssSelector()).toBe '.a .b .c'
      expect(new ScopeSelector('a.b.c').toCssSelector()).toBe '.a.b.c'
      expect(new ScopeSelector('*').toCssSelector()).toBe '*'
      expect(new ScopeSelector('a - b').toCssSelector()).toBe '.a:not(.b)'
      expect(new ScopeSelector('a & b').toCssSelector()).toBe '.a .b'
      expect(new ScopeSelector('a & -b').toCssSelector()).toBe '.a:not(.b)'
      expect(new ScopeSelector('a | b').toCssSelector()).toBe '.a, .b'
      expect(new ScopeSelector('a - (b.c d)').toCssSelector()).toBe '.a:not(.b.c .d)'
      expect(new ScopeSelector('a, b').toCssSelector()).toBe '.a, .b'
      expect(new ScopeSelector('c++').toCssSelector()).toBe '.c\\+\\+'

  describe ".toCssSyntaxSelector()", ->
    it "converts the TextMate scope selector to a CSS selector prefixing it `syntax--`", ->
      expect(new ScopeSelector('a b c').toCssSyntaxSelector()).toBe '.syntax--a .syntax--b .syntax--c'
      expect(new ScopeSelector('a.b.c').toCssSyntaxSelector()).toBe '.syntax--a.syntax--b.syntax--c'
      expect(new ScopeSelector('*').toCssSyntaxSelector()).toBe '*'
      expect(new ScopeSelector('a - b').toCssSyntaxSelector()).toBe '.syntax--a:not(.syntax--b)'
      expect(new ScopeSelector('a & b').toCssSyntaxSelector()).toBe '.syntax--a .syntax--b'
      expect(new ScopeSelector('a & -b').toCssSyntaxSelector()).toBe '.syntax--a:not(.syntax--b)'
      expect(new ScopeSelector('a | b').toCssSyntaxSelector()).toBe '.syntax--a, .syntax--b'
      expect(new ScopeSelector('a - (b.c d)').toCssSyntaxSelector()).toBe '.syntax--a:not(.syntax--b.syntax--c .syntax--d)'
      expect(new ScopeSelector('a, b').toCssSyntaxSelector()).toBe '.syntax--a, .syntax--b'
      expect(new ScopeSelector('c++').toCssSyntaxSelector()).toBe '.syntax--c\\+\\+'
