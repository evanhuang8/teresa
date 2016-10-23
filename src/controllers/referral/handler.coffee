###
Referral handler factory
###

db = require '../../db'
Client = db.model 'Client'
Organization = db.model 'Organization'
Referral = db.model 'Referral'
Service = db.model 'Service'
Intent = db.model 'Intent'

MessageHandler = require '../../handlers/message'
messenger = require './messenger'

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

findServices = (referral) ->
  services = yield ServiceUtils.nearestServies
    type: referral.type
    lat: referral.lat
    lng: referral.lng
    isAvailable: true
    isOpen: true
  return services

module.exports = 

  getMessageHandler: () ->

    retriever = () ->
      id = @ctx.request.query.id
      @data.referral = yield Referral.findOne
        include: [
          model: Client
          as: 'client'
        ,
          model: Organization
          as: 'referer'
        ,
          model: Organization
          as: 'referee'
        ,
          model: Service
          as: 'service'
        ]
        where:
          id: id
      return

    handler = new MessageHandler retriever

    # Disclaimer
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return not referral? or referral.isConnection
    , (handler) ->
      handler.reply 'You have reached the Clover system. Message & data rates may apply.'
      yield
      return

    ###
    Initialize & type
    ###
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return not referral.isInitialized
    , (handler, body) ->
      referral = handler.data.referral
      referer = referral.referer
      client = referral.client
      message = messenger.menu()
      handler.reply message 
      referral.isInitialized = true
      yield referral.save()
      return

    ###
    Select type
    ###
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return referral.isInitialized and not referral.type?
    , (handler, body) ->
      values = [1..7]
      value = parseInt body
      if value not in values
        handler.reply messenger.parseErrorMenu()
        return
      if value is 7
        referral.isConnection = true
        yield referral.save()
        # FIXME: out going call with 211
        return
      referral.type = types[value - 1]
      yield referral.save()
      handler.reply messenger.address()
      return

    ###
    Location
    ###
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return referral.type? and not referral.address?
    , (handler, body) ->
      referral = handler.data.referral
      if body is ''
        handler.reply messenger.parseErrorAddress()
        return
      result = yield LocationUtils.geocode
        keyword: body
      if not (result? and result.lat? and result.lng?)
        handler.reply messenger.parseErrorAddress()
        return
      # Update status
      referral.address = result.address
      referral.lat = result.lat
      referral.lng = result.lng
      yield referral.save()
      services = yield findServices referral
      message = ''
      if services.length > 0
        service = services[0]
        organization = yield Organization.findById service.organizationId
        directions = yield LocationUtils.directions
          origin: 
            lat: referral.lat
            lng: referral.lng
          destination:
            lat: organization.lat
            lng: organization.lng
        message = messenger.referral service, directions
        # Confirm intent
        intent = true
        if service.maxCapacity > 0
          intent = false
          for i in [0...3] # Try 3 times
            try
              intent = yield ServiceUtils.reserve
                client: referral.client
                referral: referral
                service: service
              break
            catch err
              true
        if intent
          referral.serviceId = shelter.id
          referral.refereeId = shelter.organizationId
          message = messenger.referral service, directions, intent isnt true
        else
          referral.isUnavailable = true
          message = messenger.noReferrals()
      else
        referral.isUnavailable = true
        message = messenger.noReferrals()
      yield referral.save()
      handler.reply message
      return

    ###
    Confirm referral
    ###
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return referral.service? and not referral.isReserved?
    , (handler, body) ->
      referral = handler.data.referral
      referee = referral.referee
      if not handler.isYesNo body
        handler.reply messenger.parseErrorYesNo()
        return
      isReserved = handler.isYes body
      referral.isReserved = isReserved
      message = ''
      if isReserved
        # FIXME: Cancel the intent expiration
        service = referral.service
        if services.isConfirmationRequired
          # FIXME: send message to notify service provider
        else
          referral.isConfirmed = true
      else
        referral.isCanceled = true
        referral.canceledAt = new Date()
        message = messenger.canceled()
      yield referral.save()
      handler.reply message
      yield referral.save()
      return

    return handler
