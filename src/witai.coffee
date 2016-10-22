###
Wit.ai Functions
###

{Wit, log} = require 'node-wit'

params =
  accessToken: process.env.WIT_AI_TOKEN
  actions:
    send: (request, response) ->
      console.log request
      yield
      return

client = new Wit params

module.exports = client