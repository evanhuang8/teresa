moment = require 'moment-timezone'
twilio = require 'twilio'

db = require '../../db'
Client = db.model 'Client'
Service = db.model 'Service'
Referral = db.model 'Referral'
Organization = db.model 'Organization'

io = require '../../io'
queue = require '../../tasks/queue'
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
    @render 'referral/all',
      user: @passport.user
    yield return

  add: () ->
    id = @request.query.client
    client = yield Client.findById id
    @render 'referral/add',
      client: client
      user: @passport.user
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
      yield io.addReferralRequest referral
    @body =
      status: 'OK'
      referral: referral
    return

  confirm: () ->
    id = @request.body.referral
    if not id?
      @body =
        status: 'FAIL'
        message: 'You must include a referral id'
      return
    referral = yield Referral.findOne
      include: [
        model: Client
        as: 'client'
      ,
        model: Organization
        as: 'referee'
      ]
      where:
        id: id
    if not referral?
      @body =
        status: 'FAIL'
        message: 'The referral does not exist'
      return
    if referral.isConfirmed
      @body =
        status: 'FAIL'
        message: 'The referral is already confirmed'
      return
    referral.isConfirmed = true
    yield referral.save()
    client = referral.client
    if client.phone?
      message = 'Hi'
      if client.firstName?
        message += " #{client.firstName}"
      message += "! Your service at #{referral.referee.name} has been confirmed."
      task = yield queue.add
        name: 'general'
        params:
          type: 'sendMessage'
          to: client.phone
          body: message
        eta: moment()
    @body =
      status: 'OK'
      referral: referral
    return

  fetch: () ->
    if not @passport.user?
      @status = 403
    referrals = yield Referral.findAll
      include: [
        model: Client
        as: 'client'
      ,
        model: Service
        as: 'service'
      ,
        model: Organization
        as: 'referer'
      ]
      where:
        refereeId: @passport.user.organizationId
        isCanceled: false
      order: [
        ['isConfirmed', 'ASC']
        ['isComplete', 'ASC']
        ['createdAt', 'DESC']
      ]
    @body =
      status: 'OK'
      referrals: referrals
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