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
          service = yield Service.create
            type: configs[j]
            name: row[0] + ' (' + configs[j] + ')'
            description: row[0] + ' (' + configs[j] + ')'
            businessHours: hours
            maxCapacity: _.sample [150..217]
            openCapacity: _.sample [42..133]
            isConfirmationRequired: _.sample [true, false]
            organizationId: org.id
          services.push service

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

  clients = []
  initials = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'Z']
  stages = ['unknown', 'emergent', 'homeless', 'rehab']
  for i in [0..101]
    clients.push
      firstName: faker.name.firstName()
      middleName: initials[i % initials.length]
      lastName: faker.name.lastName()
      phone: faker.phone.phoneNumberFormat()
      stage: _.sample stages
  yield Client.bulkCreate clients

  process.exit()

.catch (err) ->
  console.log err.stack
  return