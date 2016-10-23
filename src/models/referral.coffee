###
Referral model
###

module.exports = (sequelize, DataTypes) ->

  Referral = sequelize.define 'Referral', 
    isInitialized:
      type: DataTypes.BOOLEAN
      defaultValue: false
    isCheckup:
      type: DataTypes.BOOLEAN
      defaultValue: false
    checkupStatus: DataTypes.INTEGER
    type: DataTypes.STRING
    serviceId: DataTypes.INTEGER # key
    address: DataTypes.STRING
    lat: DataTypes.DOUBLE
    lng: DataTypes.DOUBLE
    isReserved:
      type: DataTypes.BOOLEAN
    isConfirmed:
      type: DataTypes.BOOLEAN
      defaultValue: false
    start: DataTypes.DATE
    end: DataTypes.DATE
    isComplete:
      type: DataTypes.BOOLEAN
      defaultValue: false
    completedAt: DataTypes.DATE
    isCanceled:
      type: DataTypes.BOOLEAN
      defaultValue: false
    canceledAt: DataTypes.DATE
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
