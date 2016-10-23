#!/usr/bin/env coffee

fs = require 'fs'

_ = require 'lodash'
co = require 'co'
faker = require 'faker'
csv = require 'csv'
Q = require 'q'

parseCSV = Q.denodeify csv.parse

configs = 
  5: 'shelter'
  6: 'housing'
  7: 'job'
  8: 'health'
  9: 'food'
  10: 'funding'

co ->

  db = require './src/db'
  yield db.client.sync
    force: true

  Community = db.model 'Community'
  Organization = db.model 'Organization'
  User = db.model 'User'
  Client = db.model 'Client'
  Service = db.model 'Service'
  Referral = db.model 'Referral'

  community = yield Community.create
    name: 'St. Louis CoC'
    description: 'St. Louis Continuum of Care'

  rawData = fs.readFileSync './preset.csv'
  data = yield parseCSV rawData
  
  orgs = []
  services = []
  hours = []
  for i in [0...7]
    hours.push
      always: true
  for row, i in data
    if i > 1 # Start at row 3
      org = yield Organization.create
        name: row[0]
        description: row[0] # FIXME
        address: row[0] # FIXME
        lat: row[3]
        lng: row[4]
        phone: row[2]
        tz: 'US/Central'
        communityId: community.id
      orgs.push org
      for j in [5..10]
        if 1 is parseInt row[j]
          completionCost = _.random 50, 350
          factor = _.random 0.1, 0.7
          missedCost = completionCost * factor
          service = yield Service.create
            type: configs[j]
            name: row[0] + ' (' + configs[j] + ')'
            description: row[0] + ' (' + configs[j] + ')'
            businessHours: hours
            maxCapacity: _.sample [150..217]
            openCapacity: _.sample [42..133]
            isConfirmationRequired: _.sample [true, false]
            completionCost: completionCost
            missedCost: missedCost
            organizationId: org.id
          services.push service

  servicesByTypes =
    shelter: []
    health: []
    housing: []
    job: []
    food: []
    funding: []
  types = Object.keys servicesByTypes
  for service in services
    servicesByTypes[service.type].push service

  userA = yield User.create
    email: 'user1@example.com'
    password: 'password1'
    organizationId: orgs[0].id

  userB = yield User.create
    email: 'user2@example.com'
    password: 'password2'
    organizationId: orgs[1].id

  userC = yield User.create
    email: 'user3@example.com'
    password: 'password3'
    organizationId: orgs[2].id

  users = [userA, userB, userC]

  clients = []
  initials = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'Z']
  stages = ['unknown', 'emergent', 'homeless', 'rehab']
  for i in [0..2000]
    clients.push
      firstName: faker.name.firstName()
      middleName: initials[i % initials.length]
      lastName: faker.name.lastName()
      phone: faker.phone.phoneNumberFormat()
      stage: _.sample stages
  yield Client.bulkCreate clients

  clients = yield Client.findAll {}
  for client in clients
    if client.stage is 'homeless'
      for type in types
        if Math.random() > 0.5
          service = _.sample servicesByTypes[type]
          referral = yield Referral.create
            isInitialized: true
            type: type
            isConfirmed: true
            isDirectionSent: _.sample [true, false]
            isComplete: _.sample [true, false]
            clientId: client.id
            serviceId: service.id
            refereeId: service.organizationId
            refererId: _.sample(orgs).id
            userId: _.sample(users).id
    else if client.stage is 'rehab'
      for type in types
        if type is 'housing' or Math.random() > 0.7
          service = _.sample servicesByTypes[type]
          referral = yield Referral.create
            isInitialized: true
            type: type
            isConfirmed: true
            isDirectionSent: _.sample [true, false]
            isComplete: true
            clientId: client.id
            serviceId: service.id
            referee: service.organizationId
            referer: _.sample(orgs).id
            userId: _.sample(users).id

  process.exit()

.catch (err) ->
  console.log err.stack
  return