{eq} = require './_utils'

suite 'matches' ->
  code = '
    if (x - 9 === 10) {
      moo.x(23);
    }
  '
  test 'one' ->
    eq ['x - 9 === 10', 'x - 9'], ':matches(bi)', code

  test 'two' ->
    eq <[ x moo x 9 10 23 ]>, ':matches(ident, literal)', code

  test 'complicated' ->
    eq ['moo.x(23)', 'x - 9 === 10'], ':matches(call, if.test)', code

  test 'one with children' ->
    eq <[ 9 10 9 ]>, ':matches(bi) literal', code

  test 'two with children' ->
    eq <[ 9 10 9 23 ]>, ':matches(bi, call) literal', code

  test 'implicit match' ->
    eq ['moo.x(23)', '9', '10', '23'], 'call, literal', code

  test 'implicit match complex' ->
    eq <[ 9 10 9 ]>, '(bi) literal', code
    eq <[ 9 10 9 23 ]>, '(bi, call) literal', code
    eq <[ 23 9 10 ]>, '(call, if.test) literal', code

  test 'nested' ->
    sels = ['(call, (bi[&op="-"], if.test)) literal', ':matches(call, (bi[&op="-"], if.test)) literal']
    eq <[ 23 9 9 10 ]>, sels, code

  test 'newlines are like commas' ->
    eq <[ x moo x 9 10 23 ]>, 'ident\nliteral', code

  test 'clean up when using newlines' ->
    eq <[ x moo x 9 10 23 ]>, '\nident  \n  \n\n  literal  ', code
