chalk = require 'chalk'
_ = require '../vendor/lodash'
{CIRCULAR_REF} = require './serialize'

WRAPPER_KEY = '__SB_WRAPPER__'
BUFFER_EXPLICIT_LIMIT = 40

_isBuffer = (val) -> val instanceof Buffer

_tree = (node, options, prefix, stack) ->
  out = []
  options.ignoreKeys ?= []
  stack.push node
  postponedArrayAttrs = []
  postponedObjectAttrs = []
  for key, val of node
    continue if options.ignoreKeys.indexOf(key) >= 0
    finalPrefix = if key is WRAPPER_KEY then prefix else "#{prefix}#{key}: "
    if (_.isObject(val) and stack.indexOf(val) >= 0) or  # Avoid circular dependencies
       (val is CIRCULAR_REF)
      out.push "#{finalPrefix}#{chalk.green.bold '[CIRCULAR]'}"
    else if Array.isArray(val) and val.length is 0
      out.push "#{finalPrefix}#{chalk.bold '[]'}"
    else if Array.isArray(val) and val.length and _.isString(val[0])
      strVal = _.map(val, (o) -> "'#{o}'").join ', '
      strVal = chalk.yellow.bold "[#{strVal}]"
      out.push "#{finalPrefix}#{strVal}"
    else if _.isDate(val)
      out.push "#{finalPrefix}#{chalk.magenta.bold val.toISOString()}"
    else if _isBuffer(val)
      str = val.slice(0, BUFFER_EXPLICIT_LIMIT).toString('hex').toUpperCase().match(/(..)/g).join(' ')
      if val.length > BUFFER_EXPLICIT_LIMIT then str += '...'
      str = "Buffer [#{val.length}]: #{str}"
      out.push "#{finalPrefix}#{chalk.magenta.bold str}"
    else if _.isObject(val) and Object.keys(val).length is 0
      out.push "#{finalPrefix}#{chalk.bold '{}'}"
    else if Array.isArray val
      postponedArrayAttrs.push key
    else if _.isObject val
      postponedObjectAttrs.push key
    else if _.isString val
      lines = val.split '\n'
      if lines.length is 1
        out.push "#{finalPrefix}" + chalk.yellow.bold("'#{val}'")
      else
        for line in lines
          out.push "#{finalPrefix}" + chalk.yellow.bold(line)
    else if val is null
      out.push "#{finalPrefix}#{chalk.red.bold 'null'}"
    else if val is undefined
      out.push "#{finalPrefix}#{chalk.bgRed.bold 'undefined'}"
    else if (val is true) or (val is false)
      out.push "#{finalPrefix}#{chalk.cyan.bold val}"
    else if _.isNumber val
      out.push "#{finalPrefix}#{chalk.blue.bold val}"
    else
      ### istanbul ignore next ###
      out.push "#{finalPrefix}#{chalk.bold val}"
  for key in postponedObjectAttrs
    val = node[key]
    out.push "#{prefix}#{key}:"
    out = out.concat _tree val, options, "#{options.indenter}#{prefix}", stack
  for key in postponedArrayAttrs
    val = node[key]
    out.push "#{prefix}#{key}:"
    out = out.concat _tree val, options, "#{options.indenter}#{prefix}", stack
  stack.pop()
  out

treeLines = (obj, options = {}) ->
  options.indenter ?= '  '
  prefix = options.prefix ? ''
  if _.isError obj
    obj = _.pick obj, ['name', 'message', 'stack']
  else if (not _.isObject(obj)) or _isBuffer obj
    obj = {"#{WRAPPER_KEY}": obj}
  return _tree obj, options, prefix, []

treeLines.log = ->
  lines = treeLines arguments...
  for line in lines
    console.log line
  return

module.exports = treeLines
