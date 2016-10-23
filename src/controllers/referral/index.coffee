db = require '../../db'
Client = db.model 'Client'
Service = db.model 'Service'
Referral = db.model 'Referral'

MessageHandler = require('./handler').getMessageHandler()

Interpreter = require '../../utils/interpreter'
LocationUtils = require '../../utils/location'
ServiceUtils = require '../../controllers/service/utils'

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
    referral = yield createIncomingReferral client, body
  return referral

createIncomingReferral = (client, body) ->
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

  add: () ->
    id = @request.query.client
    client = yield Client.findById id
    @render 'referral/add',
      client: client
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
    service = yield Service.findById clientId
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
      referral = yield createIncomingReferral client, body
    if not referral?
      referral = yield findOrCreateReferral client, body
    @request.query =
      id: referral.id
    yield MessageHandler.handle this
    return