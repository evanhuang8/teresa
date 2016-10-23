###
Core tests
###

require 'co-mocha'
_ = require 'lodash'
chai = require 'chai'
chai.config.includeStack = true
should = chai.should()
supertest = require 'co-supertest'
request = supertest.agent
moment = require 'moment-timezone'
Q = require 'q'
xml2js = require 'xml2js'
parseXML = Q.denodeify xml2js.parseString

MessageTests = require './libs/messenger'

describe 'Teresa', ->

  before (done) ->
    mysql = require 'mysql'
    connection = mysql.createConnection
      user: process.env.EPX_DB_USER or 'root'
      password: process.env.EPX_DB_PASS or '1tism0db'
      host: process.env.EPX_DB_HOST or 'localhost'
    connection.connect()
    connection.query 'DROP DATABASE IF EXISTS Teresa', (err) ->
      connection.query 'CREATE DATABASE Teresa', (err) ->
        done err
        return
      return
    return

  gb = {}
  authedRequest = null

  describe 'Server', ->

    it 'should exist', ->
      @timeout 10000
      gb.Server = require '../src/teresa'
      should.exist gb.Server
      gb.db = require '../src/db'
      return

    it 'should start', ->
      gb.server = new gb.Server()
      gb.app = yield gb.server.init()
      return

  describe 'Authentication', ->

    it '#create', ->
      res = yield request gb.app
        .post '/user/create/'
        .send
          email: 'user@example.com'
          password: 'password1'
        .expect 201
        .end()
      res.body.status.should.equal 'OK'
      gb.User = gb.db.model 'User'
      user = yield gb.User.findOne
        where:
          email: 'user@example.com'
      should.exist user
      (yield user.verifyPassword('password1')).should.be.true
      return

    it '#auth', ->
      authedRequest = request gb.app
      res = yield authedRequest
        .post '/user/auth/'
        .send
          email: 'user@example.com'
          password: 'password1'
        .expect 200
        .end()
      res.body.status.should.equal 'OK'
      should.exist res.headers['set-cookie']
      return

  describe 'CURD', ->

    describe 'Community', ->

      before ->
        gb.Community = gb.db.model 'Community'
        return

      it '#create', ->
        res = yield authedRequest
          .post '/community/create/'
          .send
            name: 'STL CoC'
            description: 'The Community of Care of the greater St. Louis region.'
          .expect 201
          .end()
        res.body.status.should.equal 'OK'
        community = yield gb.Community.findById res.body.obj.id
        should.exist community
        community.name.should.equal 'STL CoC'
        community.description.should.equal 'The Community of Care of the greater St. Louis region.'
        gb.community = community
        return

      it '#edit', ->
        res = yield authedRequest
          .post '/community/edit/'
          .send
            id: gb.community.id
            name: 'St. Louis CoC'
            description: 'The Continuum of Care of the greater St. Louis region.'
          .expect 200
          .end()
        res.body.status.should.equal 'OK'
        community = yield gb.Community.findById res.body.obj.id
        should.exist community
        community.name.should.equal 'St. Louis CoC'
        community.description.should.equal 'The Continuum of Care of the greater St. Louis region.'
        gb.community = community
        return

    describe 'Organization', ->

      before ->
        gb.Organization = gb.db.model 'Organization'
        return

      after ->
        yield gb.Organization.destroy
          where: {}
          force: true
        orgA = yield gb.Organization.create
          name: 'St. Patrick Center'
          description: 'We do good things.'
          communityId: gb.community.id
          address: '80 N Tucker Blvd, St. Louis, MO 63101'
          lat: 38.633397
          lng: -90.19559
          tz: 'US/Central'
        orgB = yield gb.Organization.create
          name: 'Mercy Ministries'
          description: 'We do good things.'
          communityId: gb.community.id
          address: '655 Maryville Centre Dr, St. Louis, MO 63141'
          lat: 38.644379
          lng: -90.495485
          tz: 'US/Central'
        orgC = yield gb.Organization.create
          name: 'Evanston'
          description: 'Ahhhhhhhhhh'
          communityId: gb.community.id
          address: '4476 Barat Hall Dr, St. Louis, MO 63108'
          lat: 38.6440
          lng: -90.2574
          tz: 'US/Central'
        gb.organization = orgA
        gb.organizations = [orgA, orgB, orgC]
        return

      it '#create', ->
        params =
          name: 'St. Patrick'
          description: 'We do good things.'
          communityId: gb.community.id
          address: '80 N Tucker Blvd, St. Louis, MO 63101'
          lat: 38.633397
          lng: -90.19559
          tz: 'US/Pacific'
        res = yield authedRequest
          .post '/organization/create/'
          .send params
          .expect 201
          .end()
        res.body.status.should.equal 'OK'
        organization = yield gb.Organization.findById res.body.obj.id
        should.exist organization
        for key, val of params
          organization[key].should.equal val
        gb.organization = organization
        return

      it '#edit', ->
        params =
          id: gb.organization.id
          name: 'St. Patrick Center'
          description: 'We do good things together.'
          communityId: gb.community.id
          address: '800 N Tucker Blvd, St. Louis, MO 63101'
          lat: 38.6333972
          lng: -90.195599
          tz: 'US/Central'
        res = yield authedRequest
          .post '/organization/edit/'
          .send params
          .expect 200
          .end()
        res.body.status.should.equal 'OK'
        organization = yield gb.Organization.findById res.body.obj.id
        should.exist organization
        for key, val of params
          organization[key].should.equal val
        gb.organization = organization
        return

    describe 'Client', ->

      before ->
        gb.Client = gb.db.model 'Client'
        return

      it '#create', ->
        params = 
          firstName: 'Julio'
          middleName: 'J'
          lastName: 'Jones'
          phone: '6613177375'
          dob: '1947-09-18'
          stage: 'emergent'
        res = yield authedRequest
          .post '/client/create/'
          .send params
          .expect 201
          .end()
        res.body.status.should.equal 'OK'
        client = yield gb.Client.findById res.body.obj.id
        should.exist client
        for key, val of params
          client[key].should.equal val
        gb.client = client
        return

      it '#edit', ->
        params = 
          id: gb.client.id
          firstName: 'Marty'
          middleName: 'K'
          lastName: 'Mack'
          phone: '3140010002'
          dob: '1940-03-12'
          stage: 'homeless'
        res = yield authedRequest
          .post '/client/edit/'
          .send params
          .expect 200
          .end()
        res.body.status.should.equal 'OK'
        client = yield gb.Client.findById res.body.obj.id
        should.exist client
        for key, val of params
          client[key].should.equal val
        gb.client = client
        return

  describe 'Location', ->

    before ->
      gb.LocationUtils = require '../src/utils/location'
      return

    it '#geocode', ->
      @timeout 5000
      result = yield gb.LocationUtils.geocode
        keyword: 'maryland and taylor'
        near:
          lat: 38.6333972
          lng: -90.195599
      should.exist result.lat
      should.exist result.lng
      parseInt(result.lat * 1000).should.equal 38643
      parseInt(result.lng * 1000).should.equal -90257
      return

    it '#direction', ->
      @timeout 5000
      yield gb.LocationUtils.directions
        origin:
          lat: 38.6440
          lng: -90.2574
        destination:
          lat: 38.633397
          lng: -90.19559
      return

  describe 'Service', ->

    before ->
      gb.Service = gb.db.model 'Service'
      gb.ServiceUtils = require '../src/controllers/service/utils'
      return

    after ->
      hours = []
      for i in [0...7]
        hours.push
          always: true
      yield gb.Service.destroy
        where: {}
        force: true
      serviceA = yield gb.Service.create
        type: 'shelter'
        name: 'St. Patrick Shelter'
        description: 'Dope crib'
        businessHours: hours
        maxCapacity: 200
        openCapacity: 150
        organizationId: gb.organizations[0].id
      serviceB = yield gb.Service.create
        type: 'shelter'
        name: 'Mercy Shelter'
        description: 'Not so much good'
        businessHours: hours
        maxCapacity: 100
        openCapacity: 50
        organizationId: gb.organizations[1].id
      return

    it '#create', ->
      hours = []
      for i in [0...7]
        hours.push
          always: true
      params = 
        type: 'shelter'
        name: 'St. Paddy Shelter'
        description: 'Welcome to my house - Flo.Rider'
        businessHours: hours
        maxCapacity: 190
        openCapacity: 100
        organizationId: gb.organization.id
      res = yield authedRequest
        .post '/service/create/'
        .send params
        .expect 201
        .end()
      res.body.status.should.equal 'OK'
      service = yield gb.Service.findById res.body.obj.id
      should.exist service
      for key, val of params
        service[key].should.deep.equal val
      gb.service = service
      return

    it '#edit', ->
      hours = []
      for i in [0...7]
        if i in [2, 4]
          hours.push
            start: '05:00PM'
            end: '9:00AM'
            overnight: true
        else
          hours.push
            always: true
      params = 
        id: gb.service.id
        name: 'St. Patrick Shelter'
        description: 'Welcome to my house'
        businessHours: hours
        maxCapacity: 200
        openCapacity: 200
      res = yield authedRequest
        .post '/service/edit/'
        .send params
        .expect 200
        .end()
      res.body.status.should.equal 'OK'
      service = yield gb.Service.findById res.body.obj.id
      should.exist service
      for key, val of params
        service[key].should.deep.equal val
      gb.service = service
      return

    it 'should be able to return nearest open service', ->
      @timeout 5000
      hours = []
      for i in [0...7]
        hours.push
          always: true
      yield gb.Service.destroy
        where: {}
        force: true
      serviceA = yield gb.Service.create
        type: 'shelter'
        name: 'St. Patrick Service'
        description: 'Dope crib'
        businessHours: hours
        maxCapacity: 200
        openCapacity: 150
        organizationId: gb.organizations[0].id
      serviceB = yield gb.Service.create
        type: 'shelter'
        name: 'Mercy Service'
        description: 'Not so much good'
        businessHours: hours
        maxCapacity: 100
        openCapacity: 50
        organizationId: gb.organizations[1].id
      serviceC = yield gb.Service.create
        type: 'shelter'
        name: 'My Crib'
        description: 'Great'
        businessHours: hours
        maxCapacity: 100
        openCapacity: 0
        organizationId: gb.organizations[2].id
      result = yield gb.LocationUtils.geocode
        keyword: 'maryland and taylor'
        near:
          lat: 38.6333972
          lng: -90.195599
      services = yield gb.ServiceUtils.nearestServices
        type: 'shelter'
        lat: result.lat
        lng: result.lng
        isAvailable: true
      services[0].id.should.equal serviceA.id
      gb.services = [serviceA, serviceB, serviceC]
      return

    it 'should be able to return the nearest service', ->
      result = yield gb.LocationUtils.geocode
        keyword: 'maryland and taylor'
        near:
          lat: 38.6333972
          lng: -90.195599
      services = yield gb.ServiceUtils.nearestServices
        type: 'shelter'
        lat: result.lat
        lng: result.lng
      services[0].id.should.equal gb.services[2].id
      return

    it.skip 'should be able to reserve a service', ->
      @timeout 10000
      result = yield gb.LocationUtils.geocode
        keyword: 'maryland and taylor'
        near:
          lat: 38.6333972
          lng: -90.195599
      origin = 
        lat: result.lat
        lng: result.lng
      service = yield gb.Service.findOne
        include: [
          model: gb.Organization
          as: 'organization'
        ] 
        where:
          id: gb.services[0].id
      destination =
        lat: service.organization.lat
        lng: service.organization.lng
      [intent, directions] = yield gb.ServiceUtils.reserve
        client: gb.client
        service: service
        origin: origin
        destination: destination
      should.exist intent
      should.exist directions
      capacity = service.openCapacity
      service = yield gb.Service.findById service.id
      service.openCapacity.should.equal capacity - 1
      return

  describe.skip 'Handlers', ->

    describe 'Interpreter', ->

      before ->
        gb.interpreter = require '../src/utils/interpreter'
        gb.Referral = gb.db.model 'Referral'
        return

      it 'should interpret string', ->
        result = yield gb.interpreter.interpret 'I want to find a place to sleep near University City'
        result.intent.should.equal 'service'
        result.location.should.equal 'University City'
        return

    describe 'Incoming Message', ->

      it 'should create referral from generic string', ->
        steps = [
          input: 'i need some help'
        ]
        messenger = new MessageTests
          app: gb.app
          from: '3141230909'
          steps: steps
          url: '/referral/message/'
          debug: true
        yield messenger.run()
        referral = yield gb.Client.findOne
          where:
            phone: '3141230909'
        should.exist referral

        return

      it 'should create referral from intent string', ->
        yield gb.Referral.destroy
          where: {}
        res = yield request(gb.app)
          .post '/referral/message/'
          .send
            From: gb.client.phone
            Body: 'I need help finding an apartment'
          .expect 200
          .end()
        res = yield parseXML res.text
        should.exist res.Response.Message
        referral = yield gb.Referral.findOne
          where:
            clientId: gb.client.id
        should.exist referral
        referral.type.should.equal 'housing'
        should.not.exist referral.address
        should.not.exist referral.lat
        should.not.exist referral.lng
        referral.isCheckup.should.be.false
        return

      it 'should create referral from intent & location string', ->
        @timeout 5000
        yield gb.Referral.destroy
          where: {}
        res = yield request(gb.app)
          .post '/referral/message/'
          .send
            From: gb.client.phone
            Body: 'I want to find a bed near Broadway Oyster Bar'
          .expect 200
          .end()
        res = yield parseXML res.text
        should.exist res.Response.Message
        referral = yield gb.Referral.findOne
          where:
            clientId: gb.client.id
        should.exist referral
        referral.type.should.equal 'service'
        should.exist referral.address
        should.exist referral.lat
        should.exist referral.lng
        referral.isCheckup.should.be.false
        res = yield request(gb.app)
          .post '/referral/message/'
          .send
            From: gb.client.phone
            Body: 'yes'
          .expect 200
          .end()
        res = yield parseXML res.text
        return

  after ->
    gb.app?.close()
    return