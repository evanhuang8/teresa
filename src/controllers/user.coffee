passport = require 'koa-passport'

db = require '../db'
User = db.model 'User'

module.exports = 
  index: () ->
    @render 'user/index'
    yield return
    return

  create: () ->
    email = @request.body.email
    password = @request.body.password
    if not email? or not password?
      @status = 400
      return
    try
      user = yield User.create
        email: email
        password: password
        lastLoginAt: new Date()
      yield @login user
    catch err
      console.log err.stack
      message = err.message
      if message is 'Validation error'
        message = err.errors[0].message
        message = message.charAt(0).toUpperCase() + message.slice(1) + '.'
      @body =
        status: 'FAIL'
        message: message
      return
    @status = 201
    @body =
      status: 'OK'
    yield return
    return

  auth: () ->
    yield passport.authenticate 'local', (err, user, info) =>
      throw err if err
      if not user
        @body =
          status: 'FAIL'
          message: 'Email/password combination does not exist.'
        return
      # Update info
      user.lastLoginAt = new Date()
      yield user.save()
      # Write session
      yield @login user
      @body =
        status: 'OK'
      return
    return