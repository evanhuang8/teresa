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
        as: 'Client'
      ShelterIntent.belongsTo models.ShelterService,
        as: 'Shelter'
      return

  return ShelterIntent
