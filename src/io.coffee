co = require 'co'
io = require 'socket.io'

db = require './db'
Service = db.model 'Service'

module.exports = 

  instance: null

  init: (server) ->

    @instance = io server

    @instance.on 'connection', (socket) ->

      socket.emit 'welcome'

      socket.on 'join_room', (data) ->
        socket.join String data.orgId
        return

      return

    return

  addReferralRequest: (referral) ->
    service = referral.service
    if not service?
      service = yield Service.findById referral.serviceId
    orgId = service.organizationId
    @instance.to(String(orgId)).emit 'new_referral', referral
    return