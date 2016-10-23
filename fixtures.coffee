#!/usr/bin/env coffee

_ = require 'lodash'
co = require 'co'
faker = require 'faker'

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

  orgA = yield Organization.create
    name: 'St. Patrick Center'
    description: 'We do good things.'
    communityId: community.id
    address: '80 N Tucker Blvd, St. Louis, MO 63101'
    lat: 38.633397
    lng: -90.19559
    tz: 'US/Central'
  orgB = yield Organization.create
    name: 'Mercy Ministries'
    description: 'We do good things.'
    communityId: community.id
    address: '655 Maryville Centre Dr, St. Louis, MO 63141'
    lat: 38.644379
    lng: -90.495485
    tz: 'US/Central'
  orgC = yield Organization.create
    name: 'Evanston'
    description: 'Ahhhhhhhhhh'
    communityId: community.id
    address: '4476 Barat Hall Dr, St. Louis, MO 63108'
    lat: 38.6440
    lng: -90.2574
    tz: 'US/Central'

  userA = yield User.create
    email: 'user1@example.com'
    password: 'password1'
    organizationId: orgA.id

  userB = yield User.create
    email: 'user2@example.com'
    password: 'password2'
    organizationId: orgB.id

  userC = yield User.create
    email: 'user3@example.com'
    password: 'password3'
    organizationId: orgC.id

  hours = []
  for i in [0...7]
    hours.push
      always: true
  shelterA = yield Service.create
    name: 'St. Patrick Shelters'
    type: 'housing'
    description: 'Dope crib'
    businessHours: hours
    maxCapacity: 200
    openCapacity: 150
    organizationId: orgA.id
  shelterB = yield Service.create
    name: 'Mercy Shelters'
    type: 'job'
    description: 'Not so much good'
    businessHours: hours
    maxCapacity: 100
    openCapacity: 50
    organizationId: orgB.id
  shelterC = yield Service.create
    name: 'My Crib'
    type: 'shelter'
    description: 'Great'
    businessHours: hours
    maxCapacity: 100
    openCapacity: 10
    organizationId: orgC.id

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