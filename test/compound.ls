{eq} = require './_utils'

suite 'compound' ->
  code = '
    2 * 4;
    2 + 3;
    function f(x) {
      2 + 5;
      2 - 3;
      2 / 9;
    }
  '

  test 'two attributes' ->
    eq ['2 + 3', '2 -3'], '[&left.value=2][&right.value=3]', code

  test 'pseudo' ->
    eq ['2 * 4', '2 + 5'], '[&expression.left.value=2]:first-child', code, false
