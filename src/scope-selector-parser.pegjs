{ var matchers = require('./scope-selector-matchers'); }

start = _ selector:(selector) _ {
  return selector;
}

selector
 = _ left:(composite) _ right:(',' _ right_comp:(composite) _)+ {
   for (var r of right) {
     left = new matchers.OrMatcher(left, r[2])
   }
   return left;
 }
 / _ composite:(composite) _ {
   return composite;
 }

composite
 = left:(expression) _ right:(operator:('|' / '&' / '-') _ right_expr:(expression) _)+ {
   return new matchers.CompositeMatcher(left, right);
 }
 / expression:(expression) _ {
   return expression;
 }

expression
 = '-' _ exp:(filter / group / path) {
   return new matchers.NegateMatcher(exp);
 }
 / exp:(filter / group / path) {
   return exp;
 }

filter
 = filter:('L'/'R'/'B') ':' _ exp:(group / path) {
   return new matchers.FilterMatcher(filter, exp);
 }

group
 = '(' selector:(selector) _ ')' {
   return selector;
 }

path
 = beginanc:(('^' _)?) first:(scope) _ others:((prevanc:('>') _)? scope _)* endanc:('$'?) {
   return new matchers.PathMatcher(first, others, beginanc, endanc);
 }

scope
 = first:(atom) others:('.' atom)* {
   return new matchers.ScopeMatcher(first, others);
 }

atom
 = segment:(STRING) {
   return new matchers.SegmentMatcher(segment);
 }
 / '*' {
   return new matchers.TrueMatcher();
 }

_
 = [ \t]*

STRING
 = $([A-Za-z0-9\u0080-\u00FF][A-Za-z0-9\u0080-\u00FF_+\-]*)
/*
start = _ selector:(selector) _ {
  return selector;
}

segment
  = _ segment:([a-zA-Z0-9+_]+[a-zA-Z0-9-+_]*) _ {
    return new matchers.SegmentMatcher(segment);
  }

  / _ scopeName:[\*] _ {
    return new matchers.TrueMatcher();
  }

scope
  = first:segment others:("." segment)* {
    return new matchers.ScopeMatcher(first, others);
  }

path
  = prefix:([LRB]":")? first:scope others:(_ scope)* {
    return new matchers.PathMatcher(prefix, first, others);
  }

group
  = prefix:([LRB]":")? "(" _ selector:selector _ ")" {
    return new matchers.GroupMatcher(prefix, selector);
  }

expression
  = "-" _ group:group _ {
    return new matchers.NegateMatcher(group);
  }

  / "-" _ path:path _ {
    return new matchers.NegateMatcher(path);
  }

  / group

  / path

composite
  = left:expression _ operator:[|&-] _ right:composite {
    return new matchers.CompositeMatcher(left, operator, right);
  }

  / expression

selector
  = left:composite _ "," _ right:selector? {
    if (right)
      return new matchers.OrMatcher(left, right);
    else
      return left;
  }

  / composite

_
  = [ \t]*
*/
