{eq, p, make-prop} = require './_utils'

suite 'subject' ->
  code = '
    function f(x) {
      2 + 3;
      if (2 === x) {
        x++;
        l: [5, 6, 7];
      }
      return x;
    }
  '
  fi ='if (2 === x) { x++; l: [5, 6, 7]; }'
  ret = type: 'ReturnStatement', argument: p 'x'

  test 'type subject' ->
    eq fi, 'if! 2', code

  test '* subject' ->
    eq ['2 + 3', '2 === x'], '*! > 2', code

  test 'root' ->
    eq code, ':root! if', code, false, false
    eq [], ':root! this', code

  test 'first-child' ->
    eq '2 + 3', ':first-child! > * > 3', code, false

  test 'nth-child' ->
    eq [fi, 'l: [5,6,7]'], ':nth-child(1)! 6', code

  test 'last-child' ->
    eq 'l: [5,6,7]', ':last-child! > * > * >  5', code

  test 'nth-last-child' ->
    eq fi, ':nth-last-child(1)! 2', code

  test 'attribute basic' ->
    eq fi, '[test]! label', code

  test 'attribute type' ->
    eq code, '[&id.name=type(String)]! if', code

  test 'attribute regex' ->
    eq code, '[&id.name=~/f/]! if', code

  test 'matches' ->
    eq fi, ':matches(if, program, func, bi)! >biop[&op="==="]', code

  test 'not' ->
    eq fi, ':not(exp-statement)! > biop', code

  test 'compound attr' ->
    sels =
      '[&left.value=2]![&right.name=x] 2'
      '[&left.value=2][&right.name=x]! 2'
      '[&left.value=2][&right.name=x]!* 2'
    eq '2 === x', sels, code

  test 'attr' ->
    eq '2 === x', '[right=#x]! 2', code
    eq '2 === x', '[right=ident]! 2', code

  test 'either attr' ->
    prop = make-prop 'k', '2'
    eq prop, '[value=2]! 2', '({k: 2})'

  test 'descendant' ->
    eq 'l: x', '* label!', 'l: x;'

  test 'child' ->
    eq 'x++', '* > update!', code

  test 'sibling left' ->
    eq '2 + 3', 'exp-statement! ~ return', code, false

  test 'sibling both' ->
    eq ['2 + 3', ret], 'exp-statement! ~ return!', code, false

  test 'adjacent left' ->
    eq [], 'exp-statement! + return', code
    eq '2 + 3', 'exp-statement! + if', code, false

  test 'adjacent both' ->
    eq ['2 + 3', fi], 'exp-statement! + if!', code, false

  suite 'prop' ->
    test 'start' ->
      eq ['2 + 3', '2 === x'], 'bi!.left', code

    test 'subprop' ->
      eq '{ x++; l: [5, 6, 7]}', 'if.then!.body', code

    test 'non-existantant subprop' ->
      eq [], 'return.arg!.left', code
      eq [], 'return!.arg.left', code

    test 'first/head' ->
      eq '2 + 3', ['func.body.body:first! 2','func.body.body:head! 2'], code, false

    test 'tail' ->
      eq fi, 'func.body.body:tail! 5', code
      eq [], 'func.body.body:tail! 9', code

    test 'last' ->
      eq ret, 'func.body.body:last! #x', code
      eq [], 'func.body.body:last! #y', code

    test 'initial' ->
      eq fi, 'func.body.body:initial! 5', code

    test 'nth' ->
      eq fi, 'func.body.body:nth(1)! 5', code

    test 'nth-last' ->
      eq '2 + 3', 'func.body.body:nth-last(2)', code, false

    test 'slice' ->
      eq fi, 'func.body.body:slice(1,3)! 5', code
      eq [], 'func.body.body:slice(1,3)! 9', code

    test 'no array results' ->
      eq [], 'func!.body.body:slice(5,6)', code
