{eq} = require './_utils'

suite 'identifier' ->
  test 'basic' ->
    eq 'x' '#x' 'x + "x"'

  test 'with number' ->
    eq 'x1' '#x1' 'x1 + "x1"'

  test 'regexp' ->
    eq ['mah', 'moo'] '#/^m/' 'x + mah + moo'
