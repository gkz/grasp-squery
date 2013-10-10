{eq, q} = require './_utils'
require! assert

suite 'errors' ->
  test 'expected type' ->
    assert.throws (-> q ':fake', 'x'), /Expected type/
    assert.throws (-> q '[=2]', 'x'), /Expected type/

  test 'expected argument for type' ->
    assert.throws (-> q '[value=type()]', 'x'), /Expected argument for 'type'/

  test 'expected selector argument' ->
    assert.throws (-> q '()', 'x'), /Expected selector argument/

  test 'unexpected keyword' ->
    assert.throws (-> q ':type', 'x'), /Unexpected keyword/

  test 'expected operator' ->
    assert.throws (-> q ':nth-child', 'x'), /Expected operator/

  test 'expected argument' ->
    assert.throws (-> q ':root.body:slice()', 'x;y;z;'), /Expected argument/
    assert.throws (-> q ':root.body:slice(,)', 'x;y;z;'), /Expected argument/
    assert.throws (-> q ':root.body:slice(1,)', 'x;y;z;'), /Expected argument/
    assert.throws (-> q ':root.body:slice(,1)', 'x;y;z;'), /Expected argument/
