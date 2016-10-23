###
Teresa server
###

path = require 'path'

co = require 'co'
koa = require 'koa'
formidable = require 'koa-formidable'
pug = require 'koa-pug'
logger = require 'koa-logger'
mount = require 'koa-mount'
serve = require 'koa-static'
session = require 'koa-session'

passport = require 'koa-passport'
LocalStrategy = require 'passport-local'

urls = require './urls'
db = require './db'
queue = require './tasks/queue'

User = db.model 'User'

module.exports = class Teresa

  port: undefined
  app: undefined

  constructor: () ->
    @port = +process.env.T_PORT or 8080
    return

  init: () ->

    yield db.client.sync()
    queue.init()

    @app = koa()
    if 1 isnt parseInt process.env.T_TEST
      @app.use logger()
    @app.use formidable()

    @app.keys = ['fZsD2ENWT6nN2]G']
    @app.use session @app

    @app.use passport.initialize()
    @app.use passport.session()

    passport.serializeUser (user, cb) ->
      cb null, user.id
      return

    passport.deserializeUser (id, cb) ->
      User.findById(id).then (user) ->
        cb null, user
        return
      .catch (err) ->
        cb err
        return
      return

    passport.use new LocalStrategy
      usernameField: 'email'
      passwordField: 'password'
    , (email, password, cb) ->
      co () ->
        try
          user = yield User.findOne
            where:
              email: email
          result = yield user.verifyPassword password
          return null if not result
          return user
        catch err
          return null
      .then (result) ->
        cb null, result
        return
      return

    @app.use mount '/static/', serve path.join __dirname, '../static/'

    new pug
      viewPath: path.join __dirname, '../views/templates/'
      debug: true
      noCache: true
      locals:
        staticPrefix: process.T_STATIC_PREFIX or '/static/'
      helperPath: [
        _: require 'lodash'
        moment: require 'moment-timezone'
      ]
      app: @app

    router = urls()
    @app.use router.routes()

    server = @app.listen @port

    return server