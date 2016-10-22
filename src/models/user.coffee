###
User model
###

bcrypt = require 'bcrypt'
Q = require 'q'

module.exports = (sequelize, DataTypes) ->

  User = sequelize.define 'User', 
    email:
      type: DataTypes.STRING
      unique: true
      allowNull: false
      validate:
        notEmpty: true
        isEmail: true
    password:
      type: DataTypes.STRING
      allowNull: false
      validate:
        notEmpty: true
    lastLoginAt: DataTypes.DATE
  ,
    timestamps: true
    paranoid: true
    associate: (models) ->
      User.belongsTo models.Organization, 
        as: 'organization'
      return
    instanceMethods:
      verifyPassword: (password) ->
        return false if not password?
        return yield Q.nfbind(bcrypt.compare) password, @password

  hashPasswordHook = (user, opts, cb) ->
    return cb() if user.password is '' or not user.changed 'password'
    bcrypt.hash user.get('password'), 12, (err, hash) ->
      return cb err if err
      user.set 'password', hash
      cb()
      return
    return

  User.beforeCreate hashPasswordHook
  User.beforeUpdate hashPasswordHook

  return User