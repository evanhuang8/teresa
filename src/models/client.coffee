###
Client model
###

module.exports = (sequelize, DataTypes) ->

  Client = sequelize.define 'Client', 
    firstName: DataTypes.STRING
    middleName: DataTypes.STRING
    lastName: DataTypes.STRING
    dob: DataTypes.STRING
    ssn: DataTypes.STRING
  ,
    timestamps: true
    paranoid: true

  return Client
