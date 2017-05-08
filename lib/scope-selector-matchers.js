(function() {
  var AndMatcher, CompositeMatcher, FilterMatcher, NegateMatcher, OrMatcher, PathMatcher, ScopeMatcher, SegmentMatcher, TrueMatcher;

  SegmentMatcher = (function() {
    function SegmentMatcher(segments) {
      this.segment = segments;
    }

    SegmentMatcher.prototype.matches = function(scope) {
      return scope === this.segment;
    };

    SegmentMatcher.prototype.toCssSelector = function() {
      return this.segment.split('.').map(function(dotFragment) {
        return '.' + dotFragment.replace(/\+/g, '\\+');
      }).join('');
    };

    SegmentMatcher.prototype.toCssSyntaxSelector = function() {
      return this.segment.split('.').map(function(dotFragment) {
        return '.syntax--' + dotFragment.replace(/\+/g, '\\+');
      }).join('');
    };

    return SegmentMatcher;

  })();

  TrueMatcher = (function() {
    function TrueMatcher() {}

    TrueMatcher.prototype.matches = function() {
      return true;
    };

    TrueMatcher.prototype.toCssSelector = function() {
      return '*';
    };

    TrueMatcher.prototype.toCssSyntaxSelector = function() {
      return '*';
    };

    return TrueMatcher;

  })();

  ScopeMatcher = (function() {
    function ScopeMatcher(first, others) {
      var segment, _i, _len;
      this.segments = [first];
      for (_i = 0, _len = others.length; _i < _len; _i++) {
        segment = others[_i];
        this.segments.push(segment[1]);
      }
    }

    ScopeMatcher.prototype.matches = function(scope) {
      var index, scopeSegments, segment, _i, _len, _ref;
      scopeSegments = scope.split('.');
      if (scopeSegments.length < this.segments.length) {
        return false;
      }
      _ref = this.segments;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        segment = _ref[index];
        if (!segment.matches(scopeSegments[index])) {
          return false;
        }
      }
      return true;
    };

    ScopeMatcher.prototype.toCssSelector = function() {
      return this.segments.map(function(matcher) {
        return matcher.toCssSelector();
      }).join('');
    };

    ScopeMatcher.prototype.toCssSyntaxSelector = function() {
      return this.segments.map(function(matcher) {
        return matcher.toCssSyntaxSelector();
      }).join('');
    };

    return ScopeMatcher;

  })();

  PathMatcher = (function() {
    function PathMatcher(first, others, beginanc, endanc) {
      var matcher, _i, _len;
      this.beginanc = beginanc != null;
      this.endanc = endanc != null;
      this.matchers = [
        {
          matcher: first,
          anchor: false
        }
      ];
      for (_i = 0, _len = others.length; _i < _len; _i++) {
        matcher = others[_i];
        this.matchers.push({
          matcher: matcher[1],
          anchor: matcher[0] !== null
        });
      }
    }

    PathMatcher.prototype.matches = function(scopes) {
      var btNode, btSelector, isRedundantNonBOLMatch, node, sel;
      node = scopes.length - 1;
      sel = this.matchers.length - 1;
      btNode = null;
      btSelector = -1;
      if (this.endanc) {
        while (node >= 0 && (scopes[node].startsWith('attr.') || scopes[node].startsWith('dyn.'))) {
          --node;
        }
        btSelector = sel;
      }
      while (node >= 0 && sel !== -1) {
        isRedundantNonBOLMatch = this.beginanc && node > 0 && sel === 0;
        if (!isRedundantNonBOLMatch && this.matchers[sel].matcher.matches(scopes[node])) {
          if (this.matchers[sel].anchor) {
            if (btSelector === -1) {
              btNode = node;
              btSelector = sel;
            }
          } else if (btSelector !== -1) {
            btSelector = -1;
          }
          --sel;
        } else if (btSelector !== -1) {
          if (btNode === null || btNode < 0) {
            break;
          }
          node = btNode;
          sel = btSelector;
          btSelector = -1;
        }
        --node;
      }
      return sel === -1;
    };

    PathMatcher.prototype.matchesBetween = function(lhs, rhs) {
      return this.matches(rhs);
    };

    PathMatcher.prototype.toCssSelector = function() {
      return this.matchers.map(function(matcher) {
        return matcher.matcher.toCssSelector();
      }).join(' ');
    };

    PathMatcher.prototype.toCssSyntaxSelector = function() {
      return this.matchers.map(function(matcher) {
        return matcher.matcher.toCssSyntaxSelector();
      }).join(' ');
    };

    return PathMatcher;

  })();

  OrMatcher = (function() {
    function OrMatcher(left, right) {
      this.left = left;
      this.right = right;
    }

    OrMatcher.prototype.matches = function(scopes) {
      return this.left.matches(scopes) || this.right.matches(scopes);
    };

    OrMatcher.prototype.matchesBetween = function(lhs, rhs) {
      return this.left.matchesBetween(lhs, rhs) || this.right.matchesBetween(lhs, rhs);
    };

    OrMatcher.prototype.toCssSelector = function() {
      return "" + (this.left.toCssSelector()) + ", " + (this.right.toCssSelector());
    };

    OrMatcher.prototype.toCssSyntaxSelector = function() {
      return "" + (this.left.toCssSyntaxSelector()) + ", " + (this.right.toCssSyntaxSelector());
    };

    return OrMatcher;

  })();

  AndMatcher = (function() {
    function AndMatcher(left, right) {
      this.left = left;
      this.right = right;
    }

    AndMatcher.prototype.matches = function(scopes) {
      return this.left.matches(scopes) && this.right.matches(scopes);
    };

    AndMatcher.prototype.matchesBetween = function(lhs, rhs) {
      return this.left.matchesBetween(lhs, rhs) && this.right.matchesBetween(lhs, rhs);
    };

    AndMatcher.prototype.toCssSelector = function() {
      if (this.right instanceof NegateMatcher) {
        return "" + (this.left.toCssSelector()) + (this.right.toCssSelector());
      } else {
        return "" + (this.left.toCssSelector()) + " " + (this.right.toCssSelector());
      }
    };

    AndMatcher.prototype.toCssSyntaxSelector = function() {
      if (this.right instanceof NegateMatcher) {
        return "" + (this.left.toCssSyntaxSelector()) + (this.right.toCssSyntaxSelector());
      } else {
        return "" + (this.left.toCssSyntaxSelector()) + " " + (this.right.toCssSyntaxSelector());
      }
    };

    return AndMatcher;

  })();

  FilterMatcher = (function() {
    function FilterMatcher(filter, matcher) {
      this.filter = filter;
      this.matcher = matcher;
    }

    FilterMatcher.prototype.matches = function(scopes) {
      return this.matcher.matches(scopes);
    };

    FilterMatcher.prototype.matchesBetween = function(lhs, rhs) {
      switch (this.filter) {
        case 'L':
          return this.matcher.matchesBetween(lhs, lhs);
        case 'R':
          return this.matcher.matchesBetween(rhs, rhs);
        case 'B':
          return this.matcher.matchesBetween(lhs, lhs) && this.matcher.matchesBetween(rhs, rhs);
      }
    };

    FilterMatcher.prototype.toCssSelector = function() {
      return ":not(" + (this.matcher.toCssSelector()) + ")";
    };

    FilterMatcher.prototype.toCssSyntaxSelector = function() {
      return ":not(" + (this.matcher.toCssSyntaxSelector()) + ")";
    };

    return FilterMatcher;

  })();

  NegateMatcher = (function() {
    function NegateMatcher(matcher) {
      this.matcher = matcher;
    }

    NegateMatcher.prototype.matches = function(scopes) {
      return !this.matcher.matches(scopes);
    };

    NegateMatcher.prototype.matchesBetween = function(lhs, rhs) {
      return !this.matcher.matchesBetween(lhs, rhs);
    };

    NegateMatcher.prototype.toCssSelector = function() {
      return ":not(" + (this.matcher.toCssSelector()) + ")";
    };

    NegateMatcher.prototype.toCssSyntaxSelector = function() {
      return ":not(" + (this.matcher.toCssSyntaxSelector()) + ")";
    };

    return NegateMatcher;

  })();

  CompositeMatcher = (function() {
    function CompositeMatcher(left, right) {
      var operator, r, _i, _len;
      for (_i = 0, _len = right.length; _i < _len; _i++) {
        r = right[_i];
        operator = r[0];
        switch (operator) {
          case '|':
            left = new OrMatcher(left, r[2]);
            break;
          case '&':
            left = new AndMatcher(left, r[2]);
            break;
          case '-':
            left = new AndMatcher(left, new NegateMatcher(r[2]));
        }
      }
      this.matcher = left;
    }

    CompositeMatcher.prototype.matches = function(scopes) {
      return this.matcher.matches(scopes);
    };

    CompositeMatcher.prototype.matchesBetween = function(lhs, rhs) {
      return this.matcher.matchesBetween(lhs, rhs);
    };

    CompositeMatcher.prototype.toCssSelector = function() {
      return this.matcher.toCssSelector();
    };

    CompositeMatcher.prototype.toCssSyntaxSelector = function() {
      return this.matcher.toCssSyntaxSelector();
    };

    return CompositeMatcher;

  })();

  module.exports = {
    AndMatcher: AndMatcher,
    CompositeMatcher: CompositeMatcher,
    NegateMatcher: NegateMatcher,
    OrMatcher: OrMatcher,
    PathMatcher: PathMatcher,
    ScopeMatcher: ScopeMatcher,
    SegmentMatcher: SegmentMatcher,
    TrueMatcher: TrueMatcher,
    FilterMatcher: FilterMatcher
  };

}).call(this);
