{eq, p} = require './_utils'

suite 'complex' ->
  code = '
    x = function (y) {
      debugger;
      if (y > z) {
        foo(y);
        l: moo(z);
        zoo();
        debugger;
        return 72;
      }
      return 72;
    };
  '
  ret = type: 'ReturnStatement', argument: p '72'

  test 'child' ->
    eq 'y > z', 'if > bi', code
    eq ['foo(y)', 'moo(z)', 'zoo()'], 'exp-statement > call', code
    eq <[ foo y zoo ]>, 'if > block > exp-statement > call > ident', code
    eq <[ 72 72 ]>, 'return > *', code
    eq [], 'if > ident', code

  test 'descendant' ->
    eq ['foo(y)', 'moo(z)', 'zoo()'], ['func-exp call', 'if call'], code
    eq <[ y z foo y l moo z zoo ]>, 'if ident', code

  test 'sibling' ->
    eq ret, ['if ~ *', 'if ~ return'], code
    eq ['zoo()', 'debugger', ret], 'label ~ *', code, false
    eq 'zoo()', 'label ~ exp-statement', code, false
    eq [], 'label ~ if', code, false

  test 'adjacent' ->
    eq ['zoo()'], 'label + *', code, false
    eq [], 'label + debugger', code
    eq ret, ['if + *', 'if + return'], code
    eq ret, 'debugger + return', code

  suite 'root default' ->
    test 'child' ->
      eq 'y > z', '> * func bi', code

  suite 'wildcard default' ->
    test 'child' ->
      eq <[ 72 72 ]>, 'return >', code

    test 'sibling' ->
      eq ret, 'if ~', code

    test 'adjacent' ->
      eq 'zoo()', 'label +', code, false
