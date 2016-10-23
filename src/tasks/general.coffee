Q = require 'q'

twilio = require 'twilio'
client = new twilio.RestClient process.env.T_TWILIO_SID, process.env.T_TWILIO_TOKEN
sendSMS = Q.denodeify client.messages.create

T_ROOT = process.env.T_ROOT
FALLBACK_URL = 'https://twimlets.com/message?Message%5B0%5D=&'

T_FROM_NUMBER = process.env.T_FROM_NUMBER

module.exports = 

  sendMessage: (data) ->
    result = yield sendSMS
      to: data.to
      from: T_FROM_NUMBER
      body: data.body
    return result

  makeCall: (data) ->
    result = yield client.makeCall
      to: data.to
      from: T_FROM_NUMBER
      url: data.url
      FallbackUrl: FALLBACK_URL
    return result