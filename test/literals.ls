{eq} = require './_utils'

suite 'literals' ->
  test 'numbers' ->
    code = '2 + 3 + 2.1'
    eq '2', '2', code
    eq '2.1', '2.1', code
    eq ['2', '3', '2.1'], <[ Number num ]>, code

  test 'string' ->
    eq '"hi"' '"hi"' '"hi" + "moo"'
    eq "'hi'" '"hi"' "'hi' + 'moo'"
    eq ['"hello"', '"moo"'], <[ String str ]>, '"hello" + "moo"'

  test 'boolean' ->
    code = 'true || false'
    eq 'true', 'true', code
    eq 'false', 'false', code
    eq ['true', 'false'], <[ Boolean bool ]>, code

  test 'regex' ->
    code = '/^hi/gi.test(x)'
    eq '/^hi/gi', '/^hi/gi', code
    eq '/^hi/gi', <[ RegExp regex ]>, code

  test 'null' ->
    eq 'null', <[ Null null ]>, 'x === null'
