###
ShelterIntent
###

moment = require 'moment-timezone'

module.exports = (sequelize, DataTypes) ->

  ShelterIntent = sequelize.define 'ShelterIntent', 
    expiresAt: 
      type: DataTypes.DATE
      allowNull: false
    code:
      type: DataTypes.STRING
      allowNull: false
    task: DataTypes.STRING
  ,
    timestamps: true
    paranoid: true
    associate: (models) ->
      ShelterIntent.belongsTo models.Client, 
        as: 'client'
      ShelterIntent.belongsTo models.ShelterService,
        as: 'shelter'
      return

  return ShelterIntent
