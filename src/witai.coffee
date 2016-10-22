###
Wit.ai Functions
###

{Wit, log} = require 'node-wit'

params =
  accessToken: '32ORZCTBTNNMMQ3XFAKDWN2PV7QPLRY4'
  actions:
    send: (request, response) ->
      console.log request
      yield
      return

client = new Wit params

module.exports = client