{map, any, all} = require 'prelude-ls'
{literal-map, syntax-flat} = require 'grasp-syntax-javascript'
{Cache, visit-pre, visit-children, get-path} = require './common'

function final-matches results
  matches = []
  if results.subject.length > 0
    for subjects in results.subject
      matches ++= subjects
  else
    matches = results.matches
  matches

function match-ast ast, selector, cache
  subject = []
  matches = []

  unless selector
    return {subject, matches}

  is-subject = selector.subject

  switch selector.type
  | 'wildcard' =>
    for node in cache.nodes
      matches.push node
      if is-subject
        subject.push [node]

  | 'root' =>
    matches.push ast
    if is-subject
      subject.push [ast]

  | 'identifier' =>
    if cache.types.has-own-property selector.value
      for node in cache.types[selector.value]
        matches.push node
        if is-subject
          subject.push [node]

  | 'nth-child' =>
    visit-pre ast, (node) !->
      index = selector.index.value
      for , val of node when typeof! val is 'Array'
        len = val.length
        if 0 <= index < len
          matches.push val[index]
          if is-subject
            subject.push [val[index]]

  | 'nth-last-child' =>
    visit-pre ast, (node) !->
      index = selector.index.value
      for , val of node when typeof! val is 'Array'
        len = val.length
        i = len - index - 1
        if 0 <= i < len
          matches.push val[i]
          if is-subject
            subject.push [val[i]]

  | 'attribute' =>
    sel-val = selector.value
    name = selector.name

    if sel-val?
      op = selector.operator
      value = sel-val.value
      value-type = typeof! value

      switch selector.val-type
      | 'primitive' =>
        switch sel-val.type
        | 'literal' =>
          visit-pre ast, (node) !->
            if is-match-primitive-literal (get-path node, name), op, value, value-type
              matches.push node
              if is-subject
                subject.push [node]
        | 'type' =>
          visit-pre ast, (node) !->
            if is-match-type (get-path node, name), op, value
              matches.push node
              if is-subject
                subject.push [node]

      | 'either' =>
        sel = sel-val.sel
        visit-pre ast, (node) !->
          node-value = get-path node, name
          if 'object' is typeof node-value and is-match-complex node-value, op, value, sel
          or is-match-primitive-literal node-value, op, value, value-type
            matches.push node
            if is-subject
              subject.push [node]
      | 'complex' =>
        visit-pre ast, (node) !->
          if is-match-complex (get-path node, name), op, value, sel-val
            matches.push node
            if is-subject
              subject.push [node]
    else
      visit-pre ast, (node) !->
        if (get-path node, name)?
          matches.push node
          if is-subject
            subject.push [node]

  | 'prop' =>
    {left, props, subjects} = selector
    left-results = final-matches match-ast ast, left, cache
    left-subject = left.subject
    for result in left-results
      node = result
      subs = []
      props-len = props.length
      has-match = false
      var previous-node
      for prop, i in props
        previous-node := node
        if prop.type is 'wildcard'
          if typeof! node is 'Array'
            new-node = []
            for p in node
              node-info = syntax-flat[p.type]
              for field in node-info.nodes ++ node-info.node-arrays when p[field]?
                new-node.push p[field]
            node = new-node
          else
            node-info = syntax-flat[node.type]
            node = [node[field] for field in node-info.nodes ++ node-info.node-arrays when node[field]?]
        else if prop.type is 'string'
          prop-value = prop.value
          if typeof! node is 'Array'
            node = [p[prop-value] for p in node when p[prop-value]?]
          else
            node = node[prop-value]
        else if typeof! node is 'Array'
          switch prop.type
          | 'first' 'head'
            node = node.0
          | 'tail'
            node = node.slice 1
          | 'last'
            node = node[*-1]
          | 'initial'
            node = node.slice 0, (node.length - 1)
          | 'nth'
            node = node[prop.index.value]
          | 'nth-last'
            node = node[*-prop.index.value-1]
          | 'slice'
            node = node.slice.apply node, (map (.value), prop.indicies)
        else
          break
        break unless node?
        if typeof! node is 'String' and prop.value is 'operator'
          node =
            type: 'Operator'
            value: node
            loc:
              start: previous-node.left.loc?.end
              end: previous-node.right.loc?.start
            raw: node
        if node.type?
          if subjects[i]
            subs.push node
        else if typeof! node is 'Array' and node.length
          if subjects[i]
            subs ++= node
        else
          break

        if i is props-len - 1
          has-match = true

      if has-match
        if typeof! node is 'Array'
          matches ++= node
        else
          matches.push node
        if left-subject
          subject.push [result]
        if subs.length
          for sub in subs
            subject.push [sub]

  | 'matches' =>
    for matches-selector in selector.selectors
      for node in final-matches match-ast ast, matches-selector, cache
        matches.push node
        if is-subject
          subject.push [node]

  | 'not' =>
    right-results = []
    for sel in selector.selectors
      right-results ++= final-matches match-ast ast, sel, cache

    visit-pre ast, (node) !->
      if node not in right-results
        matches.push node
        if is-subject
          subject.push [node]

  | 'compound' =>
    right-results = [final-matches match-ast ast, sel, cache for sel in selector.selectors]
    is-subject = is-subject or any (.subject), selector.selectors

    for node in right-results.0 when all (node in), right-results[1 to]
      matches.push node
      if is-subject
        subject.push [node]

  | 'descendant' =>
    {subject: left-subject, matches: left-matches} = match-ast ast, selector.left, cache
    {subject: right-subject, matches: right-matches} = match-ast ast, selector.right, cache

    for left-node, left-i in left-matches
      visit-pre left-node, (right-node) !->
        return if left-node is right-node
        right-i = right-matches.index-of right-node
        if right-i > -1
          matches.push right-node
          new-subject = []
          if left-subject[left-i]
            new-subject = that
          if right-subject[right-i]
            new-subject ++= that
          if new-subject.length > 0
            subject.push new-subject

  | 'child' =>
    {subject: left-subject, matches: left-matches} = match-ast ast, selector.left, cache
    {subject: right-subject, matches: right-matches} = match-ast ast, selector.right, cache

    for left-node, left-i in left-matches
      visit-children left-node, (child) !->
        right-i = right-matches.index-of child
        if right-i > -1
          matches.push child
          new-subject = []
          if left-subject[left-i]
            new-subject = that
          if right-subject[right-i]
            new-subject ++= that
          if new-subject.length > 0
            subject.push new-subject

  | 'sibling' =>
    {subject: left-subject, matches: left-matches} = match-ast ast, selector.left, cache
    {subject: right-subject, matches: right-matches} = match-ast ast, selector.right, cache

    visit-pre ast, (node, context) !->
      for key, val of node when typeof! val is 'Array'
        for x, i in val
          left-i = left-matches.index-of x
          if left-i > -1
            j = i + 1
            while j < val.length, j++
              right-i = right-matches.index-of val[j]
              if right-i > -1
                matches.push val[j]
                new-subject = []
                if left-subject[left-i]
                  new-subject = that
                if right-subject[right-i]
                  new-subject ++= that
                if new-subject.length > 0
                  subject.push new-subject

  | 'adjacent' =>
    {subject: left-subject, matches: left-matches} = match-ast ast, selector.left, cache
    {subject: right-subject, matches: right-matches} = match-ast ast, selector.right, cache

    visit-pre ast, (node, context) !->
      for key, val of node when typeof! val is 'Array'
        for x, i in val
          left-i = left-matches.index-of x
          if left-i > -1
            right-i = right-matches.index-of val[i + 1]
            if right-i > -1
              matches.push val[i + 1]
              new-subject = []
              if left-subject[left-i]
                new-subject = that
              if right-subject[right-i]
                new-subject ++= that
              if new-subject.length > 0
                subject.push new-subject

  {subject, matches}

function is-match-primitive-literal node-value, op, value, value-type
  node-type = typeof! node-value
  return false if node-type in <[ Undefined Object ]>

  op is '=' and (node-value is value
                 or node-type is value-type is 'RegExp' and node-value.to-string! is value.to-string!)
  or op is '!=' and (node-type isnt 'RegExp' and node-value isnt value
                  or node-type is value-type is 'RegExp' and node-value.to-string! isnt value.to-string!)
  or op in <[ =~ ~= ]> and value.test node-value
  or op is '<=' and node-value <= value
  or op is '>=' and node-value >= value
  or op is '<' and node-value < value
  or op is '>' and node-value > value

function is-match-type node-value, op, value
  test = (literal-map[value] or value).match //#{ typeof! node-value }//i
  op is '=' and test or op is '!=' and not test

function add-subject-to-first sel
  if sel.type in <[ descendant child sibling adjacent ]>
    add-subject-to-first sel.left
  else
    sel.subject = true

function is-match-complex node-value, op, value, selector
  return false unless node-value?
  cache = new Cache node-value

  add-subject-to-first selector
  sel =
    type: 'compound'
    selectors: [selector, {type: 'root'}]

  sub-matches = final-matches match-ast node-value, sel, cache
  sub-matches-len = sub-matches.length

  op is '=' and sub-matches-len
  or op is '!=' and not sub-matches-len

module.exports = {final-matches, match-ast}
