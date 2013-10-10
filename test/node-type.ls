{eq, p} = require './_utils'

suite 'node type' ->
  code = '''
    function f(x, y) {
      ;
      if (true) {
        var z = 9, y = 10;
        la: 999;
        with (Math) {
          pow(z, y);
        }
      } else {
        while (+2, 6 === 4) {
          switch (moo()) {
            case x && y ? this : new String():
              continue;
            case x++:
              break;
            default:
              debugger;
          }
        }
      }
      return 23;
    }
  '''

  test 'alternate syntax' ->
    eq 'la: 999', <[ ::label ::LabeledStatement ]>, code
    eq 'la: 999', '[body.exp=999]::label', code

  test 'iife' ->
    code = '(function(x){ return x; })()'
    code2 = '(function(x){ return x; }).call(this, 2)'
    code3 = '(function(x){ return x; }).apply(null, [23])'
    eq [code, code2, code3], 'iife', "var x = #code;\nvar y = #code2;\nvar z = #code3;"

  suite 'misc' ->
    test 'program' ->
      eq code, <[ Program program ]>, code, false, false

    test 'prop' ->
      prop1 =
        type: 'Property'
        key: p 'a'
        value: p '1'
        kind: 'init'
      prop2 =
        type: 'Property'
        key: p 'b'
        value: p '2'
        kind: 'init'
      eq [prop1, prop2], <[ Property prop ]>, '({a: 1, b: 2})'

  suite 'statements' ->
    test 'empty-statement' ->
      eq ';', <[ EmptyStatement empty ]>, code

    test 'block' ->
      eq '{ hi(); }', <[ BlockStatement block]>, 'function f() { hi(); }'

    test 'exp-statement' ->
      eq '1', <[ ExpressionStatement exp-statement ]>, 'function f() { 1; };', false

    test 'if' ->
      eq 'if (true) { 1; }', <[ IfStatement if ]>, 'if (true) { 1; }'

    test 'label' ->
      eq 'la: 999;', <[ LabeledStatement label ]>, code

    test 'break' ->
      eq {type: 'BreakStatement', label: null}, <[ BreakStatement break ]>, code

    test 'continue' ->
      eq {type: 'ContinueStatement', label: null}, <[ ContinueStatement continue ]>, code

    test 'with' ->
      eq 'with (Math) { pow(z,y); }', <[ WithStatement with ]>, code

    test 'switch' ->
      eq 'switch (x) { case 1: foo(); }', <[ SwitchStatement ]>, 'switch (x) { case 1: foo(); }'

    test 'return' ->
      eq {type: 'ReturnStatement', argument: p '23'}, <[ ReturnStatement return ]>, code

    test 'throw' ->
      eq 'throw e', <[ ThrowStatement throw ]>, 'if (e) { throw e; }'

    test 'try' ->
      code = 'try { foo(); } catch (e) { moo(); }'
      eq code, <[ TryStatement try ]>, code

    test 'while' ->
      code = 'while (true) { foo(); }'
      eq code, <[ WhileStatement while ]>, code

    test 'do-while' ->
      code = 'do { foo(); } while (true)'
      eq code, <[ DoWhileStatement do-while ]>, code

    test 'for' ->
      code = 'for (var x = 0; x < 2; ++x) { foo(); }'
      eq code, <[ ForStatement for ]>, code

    test 'for-in' ->
      code = 'for (key in obj) { foo(); }'
      eq code, <[ ForInStatement for-in ]>, code

    test 'debugger' ->
      eq 'debugger', <[ DebuggerStatement debugger ]>, code

    test 'statements' ->
      code = '
        if (true) {
          debugger;
        }
        with (obj) {
          throw e
        }
      '
      cases = ['{debugger;}', '{throw e;}', 'if(true){ debugger; }', 'with(obj){throw e;}', 'throw e', 'debugger']
      eq cases, 'statement', code

  suite 'declarations' ->
    v1 =
      type: 'VariableDeclarator'
      id: p 'z'
      init: p '9'

    test 'func-dec' ->
      code = 'function f(x) { return x * x; }'
      eq code, <[ FunctionDeclaration func-dec ]>, code

    test 'var-decs' ->
      eq 'var z = 9, y = 10', <[ VariableDeclaration var-decs ]>, code

    test 'var-dec' ->
      v2 =
        type: 'VariableDeclarator'
        id: p 'y'
        init: p '10'
      eq [v1, v2], <[ VariableDeclarator var-dec ]>, code

    test 'dec' ->
      code = 'function f(){ var z = 9; }'
      eq [code, 'var z = 9', v1], 'dec', code

  suite 'expressions' ->
    test 'this' ->
      eq 'this', 'this', code

    test 'arr' ->
      eq '[1,2,3]', 'arr', 'z = [1,2,3]'

    test 'obj' ->
      eq '({a: 1, b: 2})', 'obj', 'var z = {a:1, b:2}'

    test 'func-exp' ->
      eq '(function(x) {return x * x;})', 'func-exp', 'z = function(x){return x * x;}'

    test 'seq' ->
      eq '+2, 6 === 4', 'seq', code

    test 'unary' ->
      eq '+2', 'unary', code

    test 'bi' ->
      eq ['6 === 4'], 'bi', code

    test 'assign' ->
      eq 'f = 23', 'assign', 'moo(f = 23)'

    test 'update' ->
      eq 'x++', 'update', code

    test 'logic' ->
      eq 'x && y', 'logic', code

    test 'cond' ->
      eq 'x && y ? this : new String()', 'cond', code

    test 'new' ->
      eq 'new String()', 'new', code

    test 'call' ->
      eq ['pow(z, y)', 'moo()'], 'call', code

    test 'member' ->
      eq 'x.y', 'member', 'z = x.y'

    test 'ident' ->
      eq <[ f z y la Math pow z y moo x y String x x y ]>, <[ Identifier ident ]>, code

    test 'literal' ->
      eq <[ true 9 10 999 2 6 4 23 ]>, <[ Literal literal ]>, code

    test 'exp' ->
      code = '[1] + z.f(+2)'
      eq ['[1]', '+2', code, 'z.f(+2)', 'z.f'], 'exp', code

  suite 'clauses' ->
    sw =
      type: 'SwitchCase'
      test: p '1'
      consequent: [{type: 'BreakStatement', label: null}]
    c =
      type: 'CatchClause'
      param: p 'e'
      body: p '{ debugger; }'
      guard: null

    test 'switch-case' ->
      eq sw, 'switch-case', 'switch(x){case 1: break;}'

    test 'catch' ->
      eq c, 'catch', 'try { foo() } catch (e) { debugger; }'

    test 'clause' ->
      eq [sw, c], 'clause', 'try { switch (x) {case 1: break;}} catch (e) { debugger; }'
