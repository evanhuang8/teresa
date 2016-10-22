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

      it '#create', ->
        params =
          name: 'St. Patrick'
          description: 'We do good things.'
          communityId: gb.community.id
          address: '80 N Tucker Blvd, St. Louis, MO 63101'
          lat: 38.633397
          lng: -90.19559
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

  after ->

    return