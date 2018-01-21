{syntax-flat} = require 'grasp-syntax-javascript'
!function Cache ast
  @ast = ast
  nodes = []
  types = []
  visit-pre ast, ({type}:node) !->
    if type is 'ObjectExpression'
      for property in node.properties
        if property.key
          property <<<
            type: 'Property'
            start: property.key.start
            end: property.value.end
          if property.key.loc
            property.loc =
              start: property.key.loc.start
              end: property.value.loc.end
    nodes.push node
    types[type] ?= []
    types[type].push node
  @nodes = nodes
  @types = types

!function visit-pre ast, fn, path
  fn ast, path

  if not syntax-flat[ast.type]?
    return

  {nodes, node-arrays} = syntax-flat[ast.type]

  if nodes
    for node-name in nodes
      node = ast[node-name]
      continue unless node
      new-path = if path then "#path.#node-name" else node-name
      visit-pre node, fn, new-path

  if node-arrays
    for node-array-name in node-arrays
      node-array = ast[node-array-name]
      new-path = if path then "#path.#node-array-name" else node-array-name
      for node in node-array
        visit-pre node, fn, new-path

!function visit-children ast, fn
  if not syntax-flat[ast.type]?
    return

  {nodes, node-arrays} = syntax-flat[ast.type]

  if nodes
    for node-name in nodes
      fn ast[node-name]

  if node-arrays
    for node-array-name in node-arrays
      for node in ast[node-array-name]
        fn node

function get-path obj, key
  value = obj
  for k in key.split '.'
    new-value = value[k]
    if typeof! new-value isnt 'Undefined'
      value = new-value
    else
      return
  value

module.exports = {Cache, visit-pre, visit-children, get-path}
