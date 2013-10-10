{eq, q} = require './_utils'
require! assert

suite 'wildcard' ->
  test 'simple' ->
    eq ['2 + 2', '2', '2'], 'exp-statement *', '2 + 2'

  test 'length' ->
    assert.equal 7, (q '*', '4 + moo.foo').length
