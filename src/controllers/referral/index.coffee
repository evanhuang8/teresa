moment = require 'moment-timezone'

db = require '../../db'
Client = db.model 'Client'
Service = db.model 'Service'
Referral = db.model 'Referral'

handler = require('./handler').getMessageHandler()

Interpreter = require '../../utils/interpreter'
LocationUtils = require '../../utils/location'
ServiceUtils = require '../../controllers/service/utils'

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
  if result.location?
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
    id = @request.query.client
    client = yield Client.findById id
    @render 'referral/add',
      client: client
    yield return

  refer: () ->
    @render 'referral/refer'
    yield return

  create: () ->
    if not @passport.user?
      @status = 403
    clientId = @request.body.client
    serviceId = @request.body.service
    if not clientId? or not serviceId?
      @body =
        status: 'FAIL'
        message: 'Must include a client and a service'
      return
    client = yield Client.findById clientId
    if not client?
      @body =
        status: 'FAIL'
        message: 'The client does not exist'
      return
    service = yield Service.findById serviceId
    if not service?
      @body =
        status: 'FAIL'
        message: 'The service does not exist'
      return
    if service.maxCapacity > 0 and service.openCapacity is 0
      @body =
        status: 'FAIL'
        message: 'The service is at capacity'
      return
    referral = null
    intent = yield ServiceUtils.reserve
      client: client
      service: service
    if intent?
      referral = yield Referral.create
        isConfirmed: not service.isConfirmationRequired
        clientId: client.id
        serviceId: service.id
        refereeId: service.organizationId
        refererId: @passport.user.organizationId
        userId: @passport.user.id
    @body =
      status: 'OK'
      referral: referral
    return

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