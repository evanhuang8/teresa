###
Referral model
###

module.exports = (sequelize, DataTypes) ->

  Referral = sequelize.define 'Referral', 
    isCheckup:
      type: DataTypes.BOOLEAN
    checkupStatus:
      type: DataTypes.INTEGER
    type:
      type: DataTypes.INTEGER
    address:
      type: DataType.STRING
    lat:
      type: DataType.DOUBLE
    lng:
      type: DataType.DOUBLE
    isConfirmed:
      type: DataTypes.BOOLEAN
      defaultValue: false
    start:
      type: DataTypes.DATE
    end:
      type: DataTypes.DATE
    isComplete:
      type: DataTypes.BOOLEAN
      defaultValue: false
  ,
    timestamps: true
    paranoid: true
    associate: (models) ->
      Referral.belongsTo models.Client, 
        as: 'client'
      Referral.belongsTo models.Organization, 
        as: 'referee'
      Referral.belongsTo models.Organization, 
        as: 'referer'
      Referral.belongsTo models.User, 
        as: 'user'
      return

  return Referral
