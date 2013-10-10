{eq} = require './_utils'

suite 'misc' ->
  test 'no selector' ->
    eq [], '', 'x'
