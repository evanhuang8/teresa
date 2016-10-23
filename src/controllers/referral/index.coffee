moment = require 'moment-timezone'
twilio = require 'twilio'

db = require '../../db'
Client = db.model 'Client'
Referral = db.model 'Referral'

handler = require('./handler').getMessageHandler()

Interpreter = require '../../utils/interpreter'
LocationUtils = require '../../utils/location'

SERVICE_TYPES = [
  'shelter'
  'health'
  'housing'
  'job'
  'food'
  'funding'
]

findOrCreateClient = (phone) ->
  client = yield Client.findOne
    where:
      phone: phone
  if not client?
    client = yield Client.create
      phone: phone
      stage: 'unknown'
  return client

findOrCreateReferral = (client, body) ->
  referral = yield Referral.findOne
    where:
      isConnection: false
      isComplete: false
      isCanceled: false
      clientId: client.id
      updatedAt:
        $gt: new Date moment().subtract(2, 'hours').valueOf()
    order: [
      ['createdAt', 'DESC']
    ]
  if not referral?
    referral = yield createReferral client, body
  return referral

createReferral = (client, body) ->
  address = null
  lat = null
  lng = null
  type = null
  if not client?
    throw new Error 'Must include a client'
  result = yield Interpreter.interpret body
  if result.intent? and result.intent in SERVICE_TYPES
    type = result.intent
  if type? and result.location?
    data = yield LocationUtils.geocode
      keyword: result.location
    if data?
      address = result.location
      lat = data.lat
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

  add: () ->
    @render 'referral/add'
    yield return

  refer: () ->
    @render 'referral/refer'
    yield return

  message: () ->
    params = @request.body
    from = params.From
    if not from?
      @status = 400
      return
    body = params.Body?.trim()
    if not body? or body is ''
      @status = 400
      return
    client = yield findOrCreateClient from
    referral = yield findOrCreateReferral client, body
    @request.query =
      id: referral.id
    yield handler.handle this
    return

  connect_call: () ->
    response = new twilio.TwimlResponse()
    response.say 'Please hold while we try to connect you.', 
      voice: 'woman'
    response.dial '+18004274626'
    @body = response.toString()
    yield return