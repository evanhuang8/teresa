Q = require 'q'
moment = require 'moment-timezone'
twilio = require 'twilio'
_client = new twilio.RestClient process.env.T_TWILIO_SID, process.env.T_TWILIO_TOKEN
sendSMS = Q.denodeify _client.messages.create

T_ROOT = process.env.T_ROOT
FALLBACK_URL = 'https://twimlets.com/message?Message%5B0%5D=&'

T_FROM_NUMBER = process.env.T_FROM_NUMBER

db = require '../db'
Client = db.model 'Client'
Organization = db.model 'Organization'
Checkup = db.model 'Checkup'
Referral = db.model 'Referral'

queue = require './queue'

messenger = require '../controllers/referral/messenger'

module.exports = 

  sendMessage: (data) ->
    result = yield sendSMS
      to: data.to
      from: T_FROM_NUMBER
      body: data.body
    return result

  makeCall: (data) ->
    result = yield _client.makeCall
      to: data.to
      from: T_FROM_NUMBER
      url: data.url
      FallbackUrl: FALLBACK_URL
    return result

  scheduleCheckup: (data) ->
    checkup = yield Checkup.findOne
      include: [
        model: Client
        as: 'client'
      ,
        model: Organization
        as: 'organization'
      ]
      where:
        id: data.id
    if not checkup? or not checkup.client? or checkup.client.stage isnt 'emergent' or not checkup.client.phone?
      return
    client = checkup.client
    organization = checkup.organization
    start = moment.tz checkup.start, 'US/Central'
    nextCheckupAt = moment.tz('US/Central')
      .add 15, 'days'
      .hour start.hour()
      .minute start.minute()
      .startOf 'minute'
    tasks = []
    if checkup.pastTasks?.trim().length > 0
      tasks = checkup.pastTasks.split ','
    tasks.push checkup.task
    checkup.pastTasks = tasks.join ','
    task = yield queue.add
      name: 'general'
      params:
        type: 'scheduleCheckup'
        id: checkup.id
      eta: nextCheckupAt.clone()
    checkup.task = task.id
    referralIds = []
    if checkup.pastReferralIds?.trim().length > 0
      referralIds = checkup.pastReferralIds.split ','
    if checkup.referralId?
      referralIds.push checkup.referralId
    checkup.pastReferralIds = referralIds.join ','
    referral = yield Referral.create
      isCheckup: true
      clientId: client.id
    checkup.referralId = referral.id
    yield checkup.save()
    yield @sendMessage
      to: client.phone
      body: messenger.checkup client.firstName, organization.name
    return
