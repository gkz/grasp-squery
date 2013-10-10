{eq, q} = require './_utils'
require! assert

suite 'not' ->
  code = 'function f(x) { return x - moo.asdf(x); }'
  test 'nothing' ->
    eq [], ':not(*)', code

  test 'simple' ->
    assert.equal 4, (q ':not(literal)', '2 + x').length

  test 'code' ->
    assert.equal 6, (q ':not(ident, call)', code).length
