###
Context
###

twilio = require 'twilio'
utils = require './utils'

class MessageContext

  # @property [Object] koa context
  ctx: undefined
  # @property [twilio.TwimlResponse] TwiML response
  response: undefined

  # @property [Object] data models
  data: undefined

  constructor: (@ctx) ->
    @data = {}
    @response = new twilio.TwimlResponse()
    return

  ###
  Add a reply to the response

  @param message [String] body of the message
  ###
  reply: (message) ->
    @response.message message
    return

  ###
  Write the TwiML response out to the http response body
  ###
  writeout: () ->
    @ctx.body = @response.toString()
    return

  # Pass through

  isYes: (value) ->
    return utils.isYes value

  isNo: (value) ->
    return utils.isNo value

  isYesNo: (value) ->
    return utils.isYesNo value

module.exports = 

  MessageContext: MessageContext
