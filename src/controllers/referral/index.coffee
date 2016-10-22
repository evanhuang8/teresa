db = require '../../db'
Client = db.model 'Client'

interpreter = require '../../utils/interpreter'

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
    body = params.Body
    if not body? or body.trim() is ''
      @body =
        status: 'OK'
        message: 'Must include a message body'
    if from.length is 12
      from = from.substring 2
    client = yield Client.findOne
      where:
        phone: from
    if not client?
      client = yield Client.create
        phone: from
        stage: 'unknown'
    yield createReferral client, body
    @body = 
      status: 'OK'
    yield
    return