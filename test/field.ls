{eq} = require './_utils'

suite '@field' ->
  code = '
    if (x && 2) {
      z = function (y) { return x + y; };
    }
  '
  test 'left' ->
    eq <[ x z x ]>, '@left', code

  test 'right' ->
    eq ['2', '(function (y){ return x + y; })', 'y'], '@right', code

  test 'test' ->
    eq 'x && 2', '@test', code

  test 'params' ->
    eq 'y', '@params', code

  test 'argument' ->
    eq 'x + y', '@argument', code

  test 'deep' ->
    eq '2', '@test.right', code

  test 'shorthand' ->
    eq 'x + y', '@arg', code
    eq <[ x z x ]>, '@l', code
