###
Referral handler factory
###

db = require '../../db'
Referral = db.model 'Referral'
Client = db.model 'Client'
Organization = db.model 'Organization'
MessageHandler = require '../../handlers/message'

notCheckup = (referral) ->
  return not referral.isCheckup or referral.checkupStatus?

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
    Checkup
    ###
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return referral.isCheckup and not referral.checkupStatus?
    , (handler, body) ->
      handler.reply 'Checkup Response'
      yield
      return

    ###
    Main
    ###
    
    # No type yet
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return notCheckup(referral) and not referral.type?
    , (handler, body) ->
      handler.reply 'Type Response'
      yield
      return

    # Referral has type but no location
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return notCheckup(referral) and referral.type? and not referral.address?
    , (handler, body) ->
      handler.reply 'Location Response'
      yield
      return

    # Has type and location
    handler.addHook (handler, body) ->
      referral = handler.data.referral
      return notCheckup(referral) and referral.type? and referral.address?
    , (handler, body) ->
      handler.reply 'Resend Directions'
      yield
      return

    return handler
