{map, last, lines, compact, join} = require 'prelude-ls'
{alias-map, matches-map, matches-alias-map, literal-map, complex-type-map, attr-map, primitive-only-attributes, either-attributes} = require 'grasp-syntax-javascript'

function parse selector
  process-tokens tokenize "#selector"

token-split = //
    \s*(/(?:\\/|[^/])*/[gimy]*)\s*  # reg-exp
  | ([-+]?[0-9]*\.?[0-9]+)          # number
  | ("(?:\\"|[^"])*")               # string
  | ('(?:\\'|[^'])*')               # string
  | (type\([a-zA-Z]*\))             # type
  | (\*|::?|\+\+|#)                 # op
  | \s*(!=|<=|>=|=~|~=)\s*          # s_dop_s
  | \s*(\]|\)|!|\.)                 # s_op
  | (\[&|\[)\s*                     # op_s
  | \s*(\,|~|<|>|=|\+|\||\(|\s)\s*  # s_op_s
  //

function tokenize selector
  clean-selector = selector |> lines |> map (.replace /^\s*|\s*$/g, '') |> compact |> join ','
  for token in clean-selector.split token-split when token
    if token is '*'
      type: 'wildcard'
      value: '*'
    else if /^type\(([a-zA-Z]*)\)$/.exec token
      type: 'type'
      value: that.1
    else if token in <[ type root not matches first head tail last initial nth nth-last slice reverse
                        first-child nth-child nth-last-child last-child ]>
      type: 'keyword'
      value: token
    else if token in <[ true false ]>
      type: 'boolean'
      value: token is 'true'
    else if token is 'null'
      type: 'null'
      value: null
    else if /^['"](.*)['"]$/.exec token
      type: 'string'
      value: that.1.replace /\\"/, '"' .replace /\\'/ "'"
    else if /^[-+]?[0-9]*.?[0-9]+$/.test token
      type: 'number'
      value: parse-float token
    else if /^\/(.*)\/([gimy]*)$/.exec token
      type: 'regexp'
      value: new RegExp that.1, that.2
    else if token in <[ != <= >= =~ ~= > < , ~ = ! # . : :: + [& [ ] ( ) ]> or token.match /\s/
      type: 'operator'
      value: token
    else
      type: 'identifier'
      value: token

function process-tokens tokens
  return null unless tokens.length

  # surround with implicit parens, so 'a, b' works
  tokens.unshift type: 'operator', value: '('
  tokens.push    type: 'operator', value: ')'
  consume-implicit-matches tokens

function consume-implicit-matches tokens
  args = consume-complex-arg-list tokens
  if args.length > 1
    type: 'matches'
    selectors: args
  else
    args.0


function peek-op tokens, op-value
  if tokens.length > 0
  and peek-type tokens, 'operator'
  and (typeof! op-value is 'RegExp' and op-value.test tokens.0.value or tokens.0.value is op-value)
    tokens.0

function consume-op tokens, op-value
  if peek-op tokens, op-value
    tokens.shift!
  else
    throw create-error "Expected operator #op-value, but found:", tokens.0, tokens

function peek-type tokens, type
  if tokens.length > 0
  and (tokens.0.type is type or typeof! type is 'Array' and tokens.0.type in type)
    tokens.0

function consume-type tokens, type
  if peek-type tokens, type
    tokens.shift!
  else
    throw create-error "Expected type #type, but found:", tokens.0, tokens

operator-map =
  ' ': 'descendant'
  '>': 'child'
  '~': 'sibling'
  '+': 'adjacent'

function consume-complex-selector tokens
  ops = /^[\s>~+]$/
  root = type: 'root'
  wildcard = type: 'wildcard'
  result = if peek-op tokens, ops then root else consume-compound-selector tokens

  while peek-op tokens, ops
    op = tokens.shift!
    op-val = op.value
    selector = consume-compound-selector tokens

    result =
      type: operator-map[op-val]
      operator: op-val
      left: result
      right: selector or wildcard

  result

function consume-compound-selector tokens
  result = consume-selector tokens

  while tokens.length > 0
    selector = consume-selector tokens

    if selector
      if result.type isnt 'compound'
        result =
          type: 'compound'
          selectors: [result]

      result.selectors.push selector
    else
      break

  result or selector

function map-simple-selector value
  type: 'identifier'
  value: alias-map[value] or value

function consume-identifier tokens
  value = tokens.shift!.value
  if value of literal-map
    type: 'compound'
    selectors:
      * type: 'identifier'
        value: 'Literal'
      * type: 'attribute'
        name: 'value'
        operator: '='
        val-type: 'primitive'
        value:
          type: 'type'
          value: literal-map[value]
  else if value of matches-map or value of matches-alias-map
    type: 'matches'
    selectors: [{type: 'identifier', value: val} for val in matches-map[matches-alias-map[value] or value]]
  else if value of complex-type-map
    switch complex-type-map[value]
    # call[callee=(func-exp,member[obj=func-exp][prop=(#call,#apply)])]
    | 'ImmediatelyInvokedFunctionExpression' =>
        type: 'compound'
        selectors:
          * type: 'identifier'
            value: 'CallExpression'
          * type: 'attribute'
            name: 'callee'
            operator: '='
            val-type: 'complex'
            value:
              type: 'matches'
              selectors:
                * type: 'identifier'
                  value: 'FunctionExpression'
                * type: 'compound'
                  selectors:
                    * type: 'identifier'
                      value: 'MemberExpression'
                    * type: 'attribute'
                      name: 'object'
                      operator: '='
                      val-type: 'complex'
                      value:
                        type: 'identifier'
                        value: 'FunctionExpression'
                    * type: 'attribute'
                      name: 'property'
                      operator: '='
                      val-type: 'complex'
                      value:
                        type: 'matches'
                        selectors:
                          * type: 'compound'
                            selectors:
                              * type: 'identifier'
                                value: 'Identifier'
                              * type: 'attribute'
                                name: 'name'
                                operator: '='
                                val-type: 'primitive'
                                value:
                                  type: 'literal'
                                  value: 'call'
                          * type: 'compound'
                            selectors:
                              * type: 'identifier'
                                value: 'Identifier'
                              * type: 'attribute'
                                name: 'name'
                                operator: '='
                                val-type: 'primitive'
                                value:
                                  type: 'literal'
                                  value: 'apply'
  else
    map-simple-selector value

function consume-selector tokens
  selector = if peek-type tokens, 'wildcard'
    tokens.shift!
  else if peek-op tokens, '::'
    tokens.shift!
    consume-identifier tokens
  else if peek-type tokens, <[ keyword identifier ]>
    consume-identifier tokens
  else if peek-type tokens, <[ number string regexp boolean null ]>
    consume-literal tokens
  else if peek-op tokens, ':'
    consume-pseudo tokens
  else if peek-op tokens, /\[&?/
    consume-attribute tokens
  else if peek-op tokens, '#'
    consume-op tokens, '#'
    token = tokens.shift!
    value = token.value

    type: 'compound'
    selectors:
      * type: 'identifier'
        value: 'Identifier'
      * type: 'attribute'
        name: 'name'
        operator: if token.type is 'regexp' then '=~' else '='
        val-type: 'primitive'
        value:
          type: 'literal'
          value: value
  else if peek-op tokens, '('
    consume-implicit-matches tokens
  else if peek-op tokens, '.'
    type: 'root'

  if selector
    if peek-op tokens, '!'
      tokens.shift!
      selector.subject = true

    props = []
    prop-subject-indices = {}
    i = 0
    while peek-op tokens, '.' or peek-op tokens, ':' and tokens.1.value in <[ first head tail last initial nth nth-last slice reverse ]>
      props.push if peek-op tokens, '.' then consume-prop tokens else consume-pseudo tokens
      if peek-op tokens, '!'
        consume-op tokens, '!'
        prop-subject-indices[i] = true
      i++
    if props.length
      selector =
        type: 'prop'
        left: selector
        props: props
        subjects: prop-subject-indices

  selector

function consume-literal tokens
  token = tokens.shift!
  value = token.value

  type: 'compound'
  selectors:
    * type: 'identifier'
      value: 'Literal'
    * type: 'attribute'
      name: 'value'
      operator: '='
      val-type: 'primitive'
      value:
        type: 'literal'
        value: value

function consume-pseudo tokens
  op = consume-op tokens, ':'
  id = consume-type tokens, 'keyword'

  switch id.value
  | <[ root first head tail last initial reverse ]> =>
    type: that
  | <[ nth nth-last nth-child nth-last-child ]> =>
    type: that
    index: consume-arg tokens
  | 'slice' =>
    type: that
    indicies: consume-arg-list tokens
  | 'first-child' =>
    type: 'nth-child'
    index:
      type: 'literal'
      value: 0
  | 'last-child' =>
    type: 'nth-last-child'
    index:
      type: 'literal'
      value: 0
  | 'matches' => consume-implicit-matches tokens
  | 'not' =>
    type: that
    selectors: consume-complex-arg-list tokens
  | otherwise =>
    throw create-error 'Unexpected keyword:', id, tokens

function consume-name tokens
  name = ''
  while not name or peek-op tokens, '.'
    if name
      consume-op tokens, '.'
      name += '.'
    val = consume-type tokens, <[ keyword identifier ]> .value
    name += attr-map[val] or val
  name

function consume-attribute tokens
  op = consume-type tokens, 'operator' .value
  name = consume-name tokens
  last-name = last name.split '.'

  next-op = consume-type tokens, 'operator' .value

  if next-op is ']'
    type: 'attribute'
    name: name
  else
    next-token = tokens.0
    [val-type, value] = if op is '[&' or next-token.type is 'type' or last-name in primitive-only-attributes
      * 'primitive'
        consume-value tokens
    else if last-name in either-attributes
      val = consume-value [tokens.0]
      * 'either'
        * type: val.type
          value: val.value
          sel: consume-selector tokens
    else
      * 'complex'
        consume-complex-selector tokens

    selector =
      type: 'attribute'
      name: name
      operator: next-op
      val-type: val-type
      value: value

    consume-op tokens, ']'
    selector

function consume-prop tokens
  consume-op tokens, '.'
  if peek-type tokens, <[ identifier number null boolean ]>
    token = consume-type tokens, <[ identifier number null boolean ]>
    name = token.value
    type: 'string'
    value: attr-map[name] or name
  else
    type: 'wildcard'

function consume-complex-arg-list tokens
  consume-op tokens, '('
  result = []

  while tokens.length > 0
    arg = consume-complex-selector tokens
    if arg
      result.push arg
    else
      throw create-error 'Expected selector argument:', tokens.0, tokens

    if peek-op tokens, ','
      consume-op tokens, ','
    else
      break

  consume-op tokens, ')'
  result

function consume-arg-list tokens
  consume-op tokens, '('
  result = []

  while tokens.length > 0
    arg = consume-value tokens
    if arg
      result.push arg
    else
      throw create-error 'Expected argument:', tokens.0, tokens

    if peek-op tokens, ','
      consume-op tokens, ','
    else
      break

  consume-op tokens, ')'
  result

function consume-arg tokens
  consume-op tokens, '('
  value = consume-value tokens
  consume-op tokens, ')'
  value

function consume-value tokens
  {value, type}:token = tokens.shift!

  if type is 'type'
    throw create-error "Expected argument for 'type'.", token, tokens unless value
    token
  else if value not in <[ , ( ) [ ] [& ]>
    type: 'literal'
    value: value

function create-error message, token, tokens
  new Error "#message #{ JSON.stringify token }\nRemaining tokens: #{ JSON.stringify tokens, null, '  ' }"

module.exports = {parse, tokenize}
