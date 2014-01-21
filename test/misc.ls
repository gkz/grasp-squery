{eq} = require './_utils'
assert = require 'assert'

suite 'misc' ->
  test 'version' ->
    fs = require 'fs'
    current-version = JSON.parse fs.read-file-sync 'package.json', 'utf8' .version
    assert.strict-equal (require '..').VERSION, current-version

  test 'no selector' ->
    eq [], '', 'x'
