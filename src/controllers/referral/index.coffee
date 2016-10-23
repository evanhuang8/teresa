db = require '../../db'
Client = db.model 'Client'
Referral = db.model 'Referral'

MessageHandler = require('./handler').getMessageHandler()

Interpreter = require '../../utils/interpreter'
LocationUtils = require '../../utils/location'

INTENT_TYPES = ['shelter', 'housing', 'health', 'finances']

findOrCreateReferral = (client, body) ->
  referral = yield Referral.findOne
    where:
      isComplete: false
      isCanceled: false
      clientId: client.id
    order: [
      ['createdAt', 'DESC']
    ]
  if not referral?
    referral = yield createReferral client, body
  return referral

createReferral = (client, body) ->
  type = null
  address = null
  lat = null
  lng = null
  if not client?
    throw new Error 'Must include a client'
  result = yield Interpreter.interpret body
  if result.intent? and result.intent in INTENT_TYPES
    type = result.intent
  if result.location?
    data = yield LocationUtils.geocode
      keyword: result.location
    if data?.address?
      address = data.address
    if data?.lat?
      lat = data.lat
    if data?.lng?
      lng = data.lng
  referral = yield Referral.create
    type: type
    address: address
    lat: lat
    lng: lng
    clientId: client.id
  return referral

module.exports = 

  all: () ->
    @render 'referral/all'
    yield return
    return

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
    referral = null
    if from.length is 12
      from = from.substring 2
    client = yield Client.findOne
      where:
        phone: from
    if not client?
      client = yield Client.create
        phone: from
        stage: 'unknown'
      referral = yield createReferral client, body
    if not referral?
      referral = yield findOrCreateReferral client, body
    @request.query =
      id: referral.id
    yield MessageHandler.handle this
    return