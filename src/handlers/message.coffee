###
Message handler
###

twilio = require 'twilio'

utils = require './utils'
MessageContext = require('./context').MessageContext

module.exports = class MessageHandler

  # @property [Function] a function to retrieve data models from context
  retriever: undefined

  # @property [Array<Array<Function>>] Message hooks
  #
  # @example Example hooks
  #
  #   fn = (handler, body) ->
  #     return body is 'A'
  #   hook = (handler) ->
  #     @data.objA.is_real = true
  #     yield handler.data.objA.save()
  #     return
  #   hooks = [
  #     [fn, hook]
  #   ]
  #
  hooks: undefined

  constructor: (@retriever) ->
    @hooks = []
    return

  ###
  Add a hook

  @param [Function] fn trigger function
  @param [Function] handler handler function
  ###
  addHook: (fn, handler) ->
    @hooks.push [fn, handler]
    return

  ###
  Handle incoming message request

  @param [Object] koa context
  ###
  handle: (ctx) ->
    # Create new context
    context = new MessageContext ctx
    params = ctx.request.body
    # Check from number
    from = params.From
    if not from?
      context.writeout()
      return
    if from.length is 12
      from = from.substring 2
    # Wrap in exception handling
    try
      # Retrieve models by parameter
      if @retriever?
        yield @retriever.call context
      # Trim whitespace off beginning and end of response
      if params.Body?
        params.Body = params.Body.trim()
      else
        params.Body = ''
      # Check if it's a STOP signal
      if params.Body.toLowerCase() is 'stop'
        # Handle STOP
      else
        # Go through hooks
        for hook in @hooks
          # Check if condition is met
          if hook[0] context, params.Body
            # If so, execute the hook handler
            yield hook[1] context, params.Body
            # Break out
            break
      # Output response
      context.writeout()
    catch err
      console.log err.stack
      # Throw it out to upstream for a 500 response
      throw err
    return