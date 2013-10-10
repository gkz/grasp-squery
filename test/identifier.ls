{eq} = require './_utils'

suite 'identifier' ->
  test 'basic' ->
    eq 'x' '#x' 'x + "x"'

  test 'regexp' ->
    eq ['mah', 'moo'] '#/^m/' 'x + mah + moo'
