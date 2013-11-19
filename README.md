# grasp squery [![Build Status](https://travis-ci.org/gkz/grasp-squery.png?branch=master)](https://travis-ci.org/gkz/grasp-squery)
A query engine for [grasp](http://graspjs.com) - use CSS style selectors to query your JavaScript AST.

For documentation on the selector format, see [the grasp page on squery](http://graspjs.com/docs/squery).

See also the other query engine for grasp: [equery](https://github.com/gkz/grasp-equery).

Initially derived from [esquery](https://github.com/jrfeenst/esquery).

## Usage

Add `grasp-squery` to your `package.json`, and then require it: `var squery = require('grasp-squery);`.

The `squery` object exposes five properties: three functions, `parse`, `queryParsed`, `query`, a constructor, `Cache`, and the version string as `VERSION`.

Use `parse(selector)` to parse a string selector into a parsed selector.

Use `queryParsed(parsedSelector, ast)` to query your parsed selector.

`query(selector, ast)` is shorthand for doing `queryParsed(parse(selector), ast)`.

The AST must be in the [Mozilla SpiderMonkey AST format](https://developer.mozilla.org/en-US/docs/SpiderMonkey/Parser_API) - you can use [acorn](https://github.com/marijnh/acorn) to parse a JavaScript file into the format.

If you are using one selector for multiple ASTs, parse it first, and then feed the parsed version to `queryParsed`. If you are only using the selector once, just use `query`.

Both `queryParsed` and `query` take an optional third parameter `cache`. A cache is automatically created from the AST you supply if you do not supply a cache. You can create your own cache by calling the `Cache` constructor with your AST.
