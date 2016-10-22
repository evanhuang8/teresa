db = require '../../db'
Client = db.model 'Client'

interpreter = require '../../interpreter'

createReferral = (client, body) ->
  if not client?
    throw new Error 'Must include a client'
  result = yield interpreter.interpret body
  console.log result
  return

module.exports = 

  message: () ->
    params = @request.body
    from = params.From
    if not from?
      @body = 
        status: 'OK'
        message: 'Must include a from number'
    if from.length is 12
      from = from.substring 2
    client = yield Client.findOne
      where:
        phone: from
    if not client?
      client = yield Client.create
        phone: from
        stage: 'unknown'
    @body = 
      status: 'OK'
    yield
    return