###
Wit.ai Functions
###

{Wit, log} = require 'node-wit'

console.log process.env.WIT_AI_TOKEN

params =
  accessToken: process.env.WIT_AI_TOKEN
  actions:
    send: (request, response) ->
      console.log request
      yield
      return

console.log params

client = new Wit params

module.exports = client