(function() {
  var Emitter, EmitterMixin, Grammar, Grim, Injections, OnigRegExp, OnigString, Pattern, Rule, ScopeSelector, TokenizeLineResult, fs, path, _, _ref;

  path = require('path');

  _ = require('underscore-plus');

  fs = require('fs-plus');

  _ref = require('oniguruma'), OnigRegExp = _ref.OnigRegExp, OnigString = _ref.OnigString;

  Emitter = require('event-kit').Emitter;

  Grim = require('grim');

  Injections = require('./injections');

  Pattern = require('./pattern');

  Rule = require('./rule');

  ScopeSelector = require('./scope-selector');

  module.exports = Grammar = (function() {
    Grammar.prototype.registration = null;

    function Grammar(registry, options) {
      var firstLineMatch, injectionSelector, injections, patterns, repository;
      this.registry = registry;
      if (options == null) {
        options = {};
      }
      this.name = options.name, this.fileTypes = options.fileTypes, this.scopeName = options.scopeName, this.foldingStopMarker = options.foldingStopMarker, this.maxTokensPerLine = options.maxTokensPerLine, this.maxLineLength = options.maxLineLength;
      injections = options.injections, injectionSelector = options.injectionSelector, patterns = options.patterns, repository = options.repository, firstLineMatch = options.firstLineMatch;
      this.emitter = new Emitter;
      this.repository = null;
      this.initialRule = null;
      this.rawPatterns = patterns;
      this.rawRepository = repository;
      if (injectionSelector != null) {
        this.injectionSelector = new ScopeSelector(injectionSelector);
      } else {
        this.injectionSelector = null;
      }
      if (firstLineMatch) {
        this.firstLineRegex = new OnigRegExp(firstLineMatch);
      } else {
        this.firstLineRegex = null;
      }
      if (this.fileTypes == null) {
        this.fileTypes = [];
      }
      this.includedGrammarScopes = [];
      this.injections = new Injections(this, injections);
    }


    /*
    Section: Event Subscription
     */

    Grammar.prototype.onDidUpdate = function(callback) {
      return this.emitter.on('did-update', callback);
    };


    /*
    Section: Tokenizing
     */

    Grammar.prototype.tokenizeLines = function(text, compatibilityMode) {
      var lastLine, line, lineNumber, lines, ruleStack, scopes, tags, _i, _len, _ref1, _results;
      if (compatibilityMode == null) {
        compatibilityMode = true;
      }
      lines = text.split('\n');
      lastLine = lines.length - 1;
      ruleStack = null;
      scopes = [];
      _results = [];
      for (lineNumber = _i = 0, _len = lines.length; _i < _len; lineNumber = ++_i) {
        line = lines[lineNumber];
        _ref1 = this.tokenizeLine(line, ruleStack, lineNumber === 0, compatibilityMode, lineNumber !== lastLine), tags = _ref1.tags, ruleStack = _ref1.ruleStack;
        _results.push(this.registry.decodeTokens(line, tags, scopes));
      }
      return _results;
    };

    Grammar.prototype.tokenizeLine = function(inputLine, ruleStack, firstLine, compatibilityMode, appendNewLine) {
      var contentScopeName, initialRule, initialRuleStackLength, lastElem, lastRule, line, match, nextTags, openScopeTags, penultimateRule, popStack, position, previousPosition, previousRuleStackLength, rule, scopeName, string, stringWithNewLine, tag, tags, tagsEnd, tagsStart, tokenCount, truncatedLine, _i, _j, _k, _len, _len1, _len2, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;
      if (firstLine == null) {
        firstLine = false;
      }
      if (compatibilityMode == null) {
        compatibilityMode = true;
      }
      if (appendNewLine == null) {
        appendNewLine = true;
      }
      tags = [];
      truncatedLine = false;
      if (inputLine.length > this.maxLineLength) {
        line = inputLine.slice(0, this.maxLineLength);
        truncatedLine = true;
      } else {
        line = inputLine;
      }
      string = new OnigString(line);
      stringWithNewLine = appendNewLine ? new OnigString(line + '\n') : string;
      if (ruleStack != null) {
        ruleStack = ruleStack.slice();
        if (compatibilityMode) {
          openScopeTags = [];
          for (_i = 0, _len = ruleStack.length; _i < _len; _i++) {
            _ref1 = ruleStack[_i], scopeName = _ref1.scopeName, contentScopeName = _ref1.contentScopeName;
            if (scopeName) {
              openScopeTags.push(this.registry.startIdForScope(scopeName));
            }
            if (contentScopeName) {
              openScopeTags.push(this.registry.startIdForScope(contentScopeName));
            }
          }
        }
      } else {
        if (compatibilityMode) {
          openScopeTags = [];
        }
        initialRule = this.getInitialRule();
        scopeName = initialRule.scopeName, contentScopeName = initialRule.contentScopeName;
        ruleStack = [
          {
            rule: initialRule,
            scopeName: scopeName,
            contentScopeName: contentScopeName
          }
        ];
        if (scopeName) {
          tags.push(this.startIdForScope(initialRule.scopeName));
        }
        if (contentScopeName) {
          tags.push(this.startIdForScope(initialRule.contentScopeName));
        }
      }
      initialRuleStackLength = ruleStack.length;
      position = 0;
      tokenCount = 0;
      while (true) {
        previousRuleStackLength = ruleStack.length;
        previousPosition = position;
        if (position > line.length) {
          break;
        }
        if (tokenCount >= this.getMaxTokensPerLine() - 1) {
          truncatedLine = true;
          break;
        }
        if (match = _.last(ruleStack).rule.getNextTags(ruleStack, string, stringWithNewLine, position, firstLine)) {
          nextTags = match.nextTags, tagsStart = match.tagsStart, tagsEnd = match.tagsEnd;
          if (position < tagsStart) {
            if (_.last(tags) >= 0) {
              tags[tags.length - 1] += tagsStart - position;
            } else {
              tags.push(tagsStart - position);
              tokenCount++;
            }
          }
          for (_j = 0, _len1 = nextTags.length; _j < _len1; _j++) {
            tag = nextTags[_j];
            lastElem = _.last(tags);
            if (lastElem >= 0 && tag >= 0) {
              tags[tags.length - 1] += tag;
            } else if (tag % 2 === -1 && lastElem === tag - 1) {
              tags.pop();
            } else {
              tags.push(tag);
              if (tag >= 0) {
                tokenCount++;
              }
            }
          }
          position = tagsEnd;
        } else {
          if (position < line.length || line.length === 0) {
            if (_.last(tags) >= 0) {
              tags[tags.length - 1] += line.length - position;
            } else {
              tags.push(line.length - position);
            }
          }
          break;
        }
        if (position === previousPosition) {
          if (ruleStack.length === previousRuleStackLength) {
            console.error("Popping rule because it loops at column " + position + " of line '" + line + "'", _.clone(ruleStack));
            if (ruleStack.length > 1) {
              _ref2 = ruleStack.pop(), scopeName = _ref2.scopeName, contentScopeName = _ref2.contentScopeName;
              if (contentScopeName) {
                if (_.last(tags) === this.startIdForScope(contentScopeName)) {
                  tags.pop();
                } else {
                  tags.push(this.endIdForScope(contentScopeName));
                }
              }
              if (scopeName) {
                if (_.last(tags) === this.startIdForScope(scopeName)) {
                  tags.pop();
                } else {
                  tags.push(this.endIdForScope(scopeName));
                }
              }
            } else {
              if (position < line.length || (line.length === 0 && tags.length === 0)) {
                if (_.last(tags) >= 0) {
                  tags[tags.length - 1] += line.length - position;
                } else {
                  tags.push(line.length - position);
                }
              }
              break;
            }
          } else if (ruleStack.length > previousRuleStackLength) {
            _ref3 = ruleStack.slice(-2), (_ref4 = _ref3[0], penultimateRule = _ref4.rule), (_ref5 = _ref3[1], lastRule = _ref5.rule);
            if ((lastRule != null) && lastRule === penultimateRule) {
              popStack = true;
            }
            if (((lastRule != null ? lastRule.scopeName : void 0) != null) && penultimateRule.scopeName === lastRule.scopeName) {
              popStack = true;
            }
            if (popStack) {
              ruleStack.pop();
              if (_.last(tags) === this.startIdForScope(lastRule.scopeName)) {
                tags.pop();
              }
              if (_.last(tags) >= 0) {
                tags[tags.length - 1] += line.length - position;
              } else {
                tags.push(line.length - position);
              }
              break;
            }
          }
        }
      }
      if (truncatedLine) {
        if (_.last(tags) >= 0) {
          tags[tags.length - 1] += inputLine.length - position;
        } else {
          tags.push(inputLine.length - position);
        }
        while (ruleStack.length > initialRuleStackLength) {
          _ref6 = ruleStack.pop(), scopeName = _ref6.scopeName, contentScopeName = _ref6.contentScopeName;
          if (contentScopeName) {
            if (_.last(tags) === this.startIdForScope(contentScopeName)) {
              tags.pop();
            } else {
              tags.push(this.endIdForScope(contentScopeName));
            }
          }
          if (scopeName) {
            if (_.last(tags) === this.startIdForScope(scopeName)) {
              tags.pop();
            } else {
              tags.push(this.endIdForScope(scopeName));
            }
          }
        }
      }
      for (_k = 0, _len2 = ruleStack.length; _k < _len2; _k++) {
        rule = ruleStack[_k].rule;
        rule.clearAnchorPosition();
      }
      if (compatibilityMode) {
        return new TokenizeLineResult(inputLine, openScopeTags, tags, ruleStack, this.registry);
      } else {
        return {
          line: inputLine,
          tags: tags,
          ruleStack: ruleStack
        };
      }
    };

    Grammar.prototype.activate = function() {
      return this.registration = this.registry.addGrammar(this);
    };

    Grammar.prototype.deactivate = function() {
      var _ref1;
      this.emitter = new Emitter;
      if ((_ref1 = this.registration) != null) {
        _ref1.dispose();
      }
      return this.registration = null;
    };

    Grammar.prototype.clearRules = function() {
      this.initialRule = null;
      return this.repository = null;
    };

    Grammar.prototype.getInitialRule = function() {
      return this.initialRule != null ? this.initialRule : this.initialRule = this.createRule({
        scopeName: this.scopeName,
        patterns: this.rawPatterns
      });
    };

    Grammar.prototype.getRepository = function() {
      return this.repository != null ? this.repository : this.repository = (function(_this) {
        return function() {
          var data, name, repository, _ref1;
          repository = {};
          _ref1 = _this.rawRepository;
          for (name in _ref1) {
            data = _ref1[name];
            if ((data.begin != null) || (data.match != null)) {
              data = {
                patterns: [data],
                tempName: name
              };
            }
            repository[name] = _this.createRule(data);
          }
          return repository;
        };
      })(this)();
    };

    Grammar.prototype.addIncludedGrammarScope = function(scope) {
      if (!_.include(this.includedGrammarScopes, scope)) {
        return this.includedGrammarScopes.push(scope);
      }
    };

    Grammar.prototype.grammarUpdated = function(scopeName) {
      if (!_.include(this.includedGrammarScopes, scopeName)) {
        return false;
      }
      this.clearRules();
      this.registry.grammarUpdated(this.scopeName);
      if (Grim.includeDeprecatedAPIs) {
        this.emit('grammar-updated');
      }
      this.emitter.emit('did-update');
      return true;
    };

    Grammar.prototype.startIdForScope = function(scope) {
      return this.registry.startIdForScope(scope);
    };

    Grammar.prototype.endIdForScope = function(scope) {
      return this.registry.endIdForScope(scope);
    };

    Grammar.prototype.scopeForId = function(id) {
      return this.registry.scopeForId(id);
    };

    Grammar.prototype.createRule = function(options) {
      return new Rule(this, this.registry, options);
    };

    Grammar.prototype.createPattern = function(options) {
      return new Pattern(this, this.registry, options);
    };

    Grammar.prototype.getMaxTokensPerLine = function() {
      return this.maxTokensPerLine;
    };

    Grammar.prototype.scopesFromStack = function(stack, rule, endPatternMatch) {
      var contentScopeName, scopeName, scopes, _i, _len, _ref1;
      scopes = [];
      for (_i = 0, _len = stack.length; _i < _len; _i++) {
        _ref1 = stack[_i], scopeName = _ref1.scopeName, contentScopeName = _ref1.contentScopeName;
        if (scopeName) {
          scopes.push(scopeName);
        }
        if (contentScopeName) {
          scopes.push(contentScopeName);
        }
      }
      if (endPatternMatch && (rule != null ? rule.contentScopeName : void 0) && rule === stack[stack.length - 1]) {
        scopes.pop();
      }
      return scopes;
    };

    return Grammar;

  })();

  if (Grim.includeDeprecatedAPIs) {
    EmitterMixin = require('emissary').Emitter;
    EmitterMixin.includeInto(Grammar);
    Grammar.prototype.on = function(eventName) {
      if (eventName === 'did-update') {
        Grim.deprecate("Call Grammar::onDidUpdate instead");
      } else {
        Grim.deprecate("Call explicit event subscription methods instead");
      }
      return EmitterMixin.prototype.on.apply(this, arguments);
    };
  }

  TokenizeLineResult = (function() {
    function TokenizeLineResult(line, openScopeTags, tags, ruleStack, registry) {
      this.line = line;
      this.openScopeTags = openScopeTags;
      this.tags = tags;
      this.ruleStack = ruleStack;
      this.registry = registry;
    }

    Object.defineProperty(TokenizeLineResult.prototype, 'tokens', {
      get: function() {
        return this.registry.decodeTokens(this.line, this.tags, this.openScopeTags);
      }
    });

    return TokenizeLineResult;

  })();

}).call(this);
