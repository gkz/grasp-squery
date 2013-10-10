{eq, p} = require './_utils'

suite 'pseudo' ->
  code = '
    function f(x) {
      debugger;
      with (obj) {
        try {
          x = 10;
          x, y, z;
        } catch (e) {
          foo(z);
        }
        throw x;
      }
      l: [1,2,3,4,5];
      return x;
    }
  '
  ret = type: 'ReturnStatement', argument: p 'x'

  test 'first-child' ->
    eq 'debugger', 'debugger:first-child', code
    eq '1', 'literal:first-child', code

  test 'nth-child' ->
    eq '3', 'literal:nth-child(2)', code
    eq ret, 'return:nth-child(3)', code
    eq [ret, '4'], ':nth-child(3)', code
    eq [], ':nth-child(9)', code

  test 'last-child' ->
    eq ret, 'return:last-child', code
    eq '5', 'literal:last-child', code
    eq <[ z z x ]>, 'ident:last-child', code

  test 'last-nth-child' ->
    eq '4', 'literal:nth-last-child(1)', code
    eq 'x', 'ident:nth-last-child(2)', code
    eq [], ':nth-last-child(9)', code

  test 'root' ->
    eq code, ':root', code, false, false
