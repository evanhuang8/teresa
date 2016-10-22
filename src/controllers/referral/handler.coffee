###
Referral handler factory
###

db = require '../../db'
Referral = db.model 'Referral'
Client = db.model 'Client'
Organization = db.model 'Organization'
MessageHandler = require '../../handlers/message'

locationUtils = require '../../utils/location'
shelterUtils = require '../../controllers/shelter/utils'

INTENT_TYPES = ['shelter', 'housing', 'health', 'finances']

notCheckup = (referral) ->
  return not referral.isCheckup or referral.checkupStatus?

findAndSelectShelter = (referral) ->
  nearShelters = yield shelterUtils.nearestShelters
    lat: referral.lat
    lng: referral.lng
    isAvailable: true
  console.log nearShelters
  return

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
        ]
        where:
          id: id
      return

    handler = new MessageHandler retriever

    # Disclaimer
    handler.addHook (handler, body) ->
      return not handler.data.referral? or handler.data.referral.isComplete
    , (handler) ->
      handler.reply 'You have reached the Teresa system.'
      yield
      return

    ###
    Initialize
    ###
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return referral? and not referral.isInitialized
    , (handler, body) ->
      referral = handler.data.referral
      referer = referral.referer
      client = referral.client
      if referral.isCheckup
        message = 'Hi'
        if client.firstName?
          message += " #{client.firstName}"
        message += ', '
        if referer?
          message += " this is #{referer.name} checking in on you."
        else
          message += ' we are wondering how you are doing.'
        message += ' Are you:\n\n1: doing OK\n2: Worried about losing your home\n3:Lost your home\n\nReply 1, 2 or 3'
      else if not referral.type? and not referral.address?
        message = 'Do you need help with anything today?\n\n1: Shelter\n2: Health\n3: Housing\n4: Job/Money\n5: Talk to someone\nPlease reply 1, 2, 3, 4 or 5'
      else if referral.type? and not referral.address?
        message = 'Where are you right now? Please reply with a street address or an intersection (ex: Main Street and North Ave.)'
      else if referral.type? and referral.address? and referral.lat? and referral.lng?
        shelter = yield findAndSelectShelter referral
        directions = yield locationUtils.directions
          origin:
            lat: referral.lat
            lng: referral.lng
          destination:
            lat: shelter.lat
            lng: shelter.lng
        message = test
      handler.reply message 
      referral.isInitialized = true
      yield referral.save()
      return

    ###
    Checkup
    ###
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return referral.isCheckup and not referral.checkupStatus?
    , (handler, body) ->
      referral = handler.data.referral
      client = referral.client
      values = [1, 2, 3]
      if parseInt(body) not in values
        handler.reply 'Sorry, we didn\'t get that. If you are doing OK, reply 1. If you are worried about loosing you home, reply 2. If you lost your home, reply 3.'
        return
      referral.checkupStatus = parseInt(body)
      yield referral.save()
      switch referral.checkupStatus
        when 1
          handler.reply 'That is great! If you are worried about losing your home, you can always call this number to get help.'
          client.stage = 'ok'
        when 2
          handler.reply 'We will now connect you with a preventative service. You will receive a call from this number in a few seconds.'
          client.stage = 'emergent'
        when 3
          handler.reply 'Do you need help with anything today?\n\n1: Shelter\n2: Health\n3: Housing\n4: Job/Money\n5: Talk to someone\nPlease reply 1, 2, 3, 4 or 5'
          client.stage = 'homeless'
      yield client.save()
      return

    ###
    Main
    ###
    
    # No type yet
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return notCheckup(referral) and not referral.type?
    , (handler, body) ->
      values = [1, 2, 3, 4, 5]
      if parseInt(body) not in values
        handler.reply 'Sorry, we didn\'t get that. If you are doing OK, reply 1. If you are worried about loosing you home, reply 2. If you lost your home, reply 3.'
        return
      referralTypes =
        1: 'shelter'
        2: 'housing'
        3: 'health'
        4: 'finances'
        5: 'other'
      referral.type = referralTypes[parseInt(body)]
      yield referral.save()
      handler.reply 'Where are you right now? Please reply with a street address or an intersection (ex: Main Street and North Ave.)'
      return

    # Referral has type but no location
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return notCheckup(referral) and referral.type? and not referral.address?
    , (handler, body) ->
      referral = handler.data.referral
      if not body? or body.trim() is ''
        handler.reply 'Please send your location.'
        return
      result = yield locationUtils.geocode
        keyword: body
      if not (result? and result.lat? and result.lng?)
        handler.reply 'Sorry, we couldn\'t find your location. Please enter an intersection near you (example: \'Washington Ave. and McPherson Ave.\')'
        return
      referral.address = result.address
      referral.lat = result.lat
      referral.lng = result.lng
      yield referral.save()
      shelter = yield findAndSelectShelter referral
      return

    # Has type and location
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return notCheckup(referral) and referral.type? and referral.address?
    , (handler, body) ->
      handler.reply 'Ask for reservation'
      yield
      return

    return handler
