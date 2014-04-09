VERSION = '0.2.2'

{Cache} = require './common'
{parse} = require './parse'
{final-matches, match-ast} = require './match'

query-parsed = (parsed-selector, ast, cache) ->
  final-matches match-ast ast, parsed-selector, (cache or new Cache ast)

query = (selector, ast, cache) ->
  query-parsed (parse selector), ast, cache

module.exports = {parse, query-parsed, query, Cache, VERSION}
