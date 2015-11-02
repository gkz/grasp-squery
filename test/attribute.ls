{eq, p, make-prop} = require './_utils'

suite 'attribute simple' ->
  code = 'if (1 == xoom) { 1 + 2; }'

  test 'existance' ->
    eq code, '[test]', code
    eq [], '[nonexistant]', code
    eq [], '[left.nonexistant]', code

  test 'equals' ->
    eq '2', '[&value=2]', code

  test 'equals regex' ->
    code = '/hi/i || /hi/g'
    eq '/hi/g', 'regex[&value=/hi/g]', code
    eq '/hi/i', 'regex[&value!=/hi/g]', code
    eq [], '[&left.value=/hi/g]', code
    eq code, '[&left.value!=/hi/g]', code

  test 'op' ->
    eq '1 + 2', '[&operator=+]', code
    eq '2 * 3', '[&op=*]', '2 * 3'
    eq '2 * 3', '[&op="*"]', '2 * 3'
    eq '2 * 3', "[&op='*']", '2 * 3'
    eq 'z++', "[&op='++']", 'z++'
    eq 'z++', "[&op=++]", 'z++'
    eq 'z--', "[&op=--]", 'z--'

  test 'deep' ->
    eq ['1 == xoom', '1 + 2'], '[&left.value=1]', code
    eq ['1 == xoom'], 'if.test[left.value=1]', code

  test 'regexp' ->
    eq '1 == xoom', ['[&right.name=~/^x/]', '[&right.name~=/^x/]'], code
    #eq '1 + 2', 'op[right.name!=/^x/]', code

  test 'type' ->
    eq <[ 1 1 2 ]>, ['[&value=type(Number)]', '[&value=type(number)]', '[&value=type(num)]'], code
    eq 'false', 'literal[&value!=type(Number)]', 'false && 0'
    eq <[ true false ]>, ['[&value=type(Boolean)]', '[&value=type(boolean)]', '[&value=type(bool)]'], 'true || false'

  test 'not' ->
    eq 'xoom', 'ident[&name!=x]', code
    eq [], 'ident[&name!=xoom]', code

  test 'less than' ->
    eq ['1', '1'] '[&value<2]', code
    eq [], '[&value<1]', code

  test 'greater than' ->
    eq '2', '[&value>1]', code
    eq ['1', '1', '2'], '[&value>0]', code
    eq [], '[&value>2]', code

  test 'less that or equal' ->
    eq ['1', '1', '2'], '[&value<=2]', code
    eq ['1', '1'], '[&value<=1]', code
    eq [], '[&value<=0]', code

  test 'greater than or equal' ->
    eq ['1', '1', '2'], '[&value>=1]', code
    eq '2', '[&value>=2]', code
    eq [], '[&value>=3]', code

  suite 'shorthand' ->
    ops = ['1 == xoom', '1 + 2']

    test 'exp' ->
      eq '1 + 2', '[exp]', code, false

    test 'exps' ->
      code = '1,2;'
      eq code, '[exps]', code

    test 'then' ->
      eq code, '[then]', code

    test 'alt, else' ->
      code2 = 'if(x) { y;} else { z;}'
      eq code2, ['[alt]', '[else]'], code2
      eq [], ['[alt]', '[else]'], code

    test 'op' ->
      eq ops, '[op]', code

    test 'l' ->
      eq ops, '[l]', code

    test 'r' ->
      eq ops, '[r]', code

    test 'arg' ->
      code = 'throw e'
      eq code, '[arg]', code

    test 'args' ->
      code = 'f(1,2)'
      eq code, '[args]', code

    test 'els' ->
      code = '[1,2,3]'
      eq code, '[els]', code

    test 'val' ->
      eq <[ 1 1 2 ]>, '[val]', code

    test 'obj' ->
      code = 'Math.pow'
      eq code, '[obj]', code

    test 'prop' ->
      code = 'Math.pow'
      eq code, '[prop]', code

    test 'props' ->
      code = '({a: 1, b: 2})'
      eq code, '[props]', code

    test 'decs' ->
      code = 'var z = 1, a = 9'
      eq code, '[decs]', code

suite 'attribute complicated' ->
  code = '
    function square(x) {
      return x * x;
    }
    if (1 == xoom) {
      moo.foo(1 + 2);
    } else {
      debugger;
    }
    var obj = {
      a: 1,
      b: 2,
      c: false
    };
    var obj2 = {
      z: 7,
      x: 8
    };
  '

  prop = make-prop 'c', 'false'
  ret = type: 'ReturnStatement', argument: p 'x * x'

  test 'primitive' ->
    eq 'foo', '[name=foo]', code

  test 'either - value' ->
    eq [prop, 'false'], '[value=false]', code
    eq '/hi/g', 'literal[val=/hi/g]', 'var x = /hi/g;'
    eq 'null', 'literal[val=null]', 'var x = null;'

  test 'complex' ->
    eq prop, 'prop[key=#c]', code
    eq ret, '[arg=bi]', code
    eq ['1 == xoom', '1 + 2'], '[left=1]', code

  test 'complex - init' ->
    var-dec =
      type: 'VariableDeclarator'
      id: p 'obj'
      init: p '({a: 1, b: 2, c: false})'

    eq var-dec, 'dec[init=obj 2]', code
    eq [], 'dec[init!=obj prop]', code

  test 'anon function expression' ->
    code = '''
      function f(xx) {
        xs.map(function (y) { return y + 1; });
      }
      '''
    eq code, 'func[id=#f]', code
    eq '(function (y) { return y + 1; })', 'func[id=type(null)]', code

  test 'null check' ->
    no-else = 'if (test) { 1; }'
    with-else = 'if (test2) { 2; } else { 3; }'
    code = "#no-else\n#with-else"

    eq [no-else, with-else], 'if', code
    eq with-else, 'if[else]', code
    eq no-else, 'if[else=type(null)]', code
