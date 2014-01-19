{eq, q, p} = require './_utils'
{deep-equal} = require 'assert'

suite '.prop' ->
  code = '''
         if (x && 2) {
           z = function (y) {
             l: 123;
             throw Error;
             return x + y;
           };
         }
         '''
  ret =
    type: 'ReturnStatement'
    argument: p 'x + y'

  test 'if' ->
    eq 'x && 2', 'if.test', code
    eq '{ z = function (y) { l: 123; throw Error; return x + y; }; }' 'if.consequent', code

  test 'if deep' ->
    eq 'x', 'if.test.left', code

  test 'access on compound' ->
    eq 'x', 'prop[key=#x].key', 'var obj = {a: 3, x: 2};'

  test 'attr on prop' ->
    eq 'g(2)', 'var-dec.init[callee=#g]', 'var x = f(1), y = g(2);'

  test 'bi' ->
    eq 'y', 'bi.right', code

  test 'logic' ->
    eq '2', 'logic.right', code

  test 'shorthand' ->
    eq 'y', 'bi.r', code

  test 'with space' ->
    eq 'y', 'bi .right', code

  test 'root default' ->
    eq 'x', '.body:nth(0).test.left', code

  test 'wildcard default' ->
    exp-state =
      type: 'ExpressionStatement'
      expression: p '123'
    eq ['l', exp-state], 'label.', code
    eq ['l', exp-state], 'label.*', code

  test 'wildcard default with array' ->
    eq ['a', 'b', 'c', 'd'], 'arr.elements.', '[a && b, c || d]'

  suite 'wildcard subject' ->
    code = '
      if (x && 2) {
        z = function (y) { return x + y; };
      }
    '
    test 'left' ->
      eq <[ x z x ]>, '*.left', code

    test 'right' ->
      eq ['2', '(function (y){ return x + y; })', 'y'], '*.right', code

    test 'test' ->
      eq 'x && 2', '*.test', code

    test 'deep' ->
      eq '2', '*.test.right', code

  test 'access operator' ->
    op =
      type: 'Operator'
      value: '+'
      raw: '+'
      loc:
        start:
          line: 5
          column: 12
        end:
          line: 5
          column: 15
    eq op, 'bi.op', code
    deep-equal [op], q 'bi.op', code, true

  test 'of array' ->
    eq '123', 'func-exp.body.body.body.exp', code

  test 'of array func' ->
    eq [], 'func-exp.body.body:tail.body.exp', code
    eq '123', 'func-exp.body.body:initial.body.exp', code

  suite 'array functions' ->
    test 'first, head' ->
      eq 'l: 123', ['func-exp.body.body:first', 'func-exp.body.body:head'], code

    test 'tail' ->
      eq ['throw Error', ret], 'func-exp.body.body:tail', code

    test 'last' ->
      eq ret, 'func-exp.body.body:last', code

    test 'initial' ->
      eq ['l: 123', 'throw Error'], 'func-exp.body.body:initial', code

    test 'nth' ->
      eq 'l: 123', 'func-exp.body.body:nth(0)', code
      eq 'throw Error', 'func-exp.body.body:nth(1)', code
      eq ret, 'func-exp.body.body:nth(2)', code

    test 'nth-last' ->
      eq  ret, 'func-exp.body.body:nth-last(0)', code
      eq 'throw Error', 'func-exp.body.body:nth-last(1)', code
      eq 'l: 123', 'func-exp.body.body:nth-last(2)', code

    test 'slice' ->
      eq ['l: 123', 'throw Error'], 'func-exp.body.body:slice(0,2)', code
      eq ['throw Error', ret], 'func-exp.body.body:slice(1,3)', code
      eq ['throw Error', ret], 'func-exp.body.body:slice(1)', code
      eq 'throw Error', 'func-exp.body.body:slice(1,2)', code
      eq [], 'func-exp:slice(1,2)', code

    test 'multiple' ->
      eq ['throw Error'], 'func-exp.body.body:tail:first', code
