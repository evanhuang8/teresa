###
Referral model
###

module.exports = (sequelize, DataTypes) ->

  Referral = sequelize.define 'Referral', 
    # Checkup
    isCheckup: 
      type: DataTypes.BOOLEAN
      defaultValue: false
    checkupStatus: DataTypes.INTEGER
    # Text-in
    isInitialized:
      type: DataTypes.BOOLEAN
      defaultValue: false
    isConnection:
      type: DataTypes.BOOLEAN
      defaultValue: false
    type: DataTypes.STRING
    # Current client state
    address: DataTypes.STRING
    lat: DataTypes.DOUBLE
    lng: DataTypes.DOUBLE
    # Control states
    isUnavailable: 
      type: DataTypes.BOOLEAN
      defaultValue: false
    isReserved: DataTypes.BOOLEAN
    isConfirmed:
      type: DataTypes.BOOLEAN
      defaultValue: false
    isDirectionSent: DataTypes.BOOLEAN
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
      Referral.belongsTo models.Service,
        as: 'service'
      Referral.belongsTo models.Organization, # Dest
        as: 'referee'
      Referral.belongsTo models.Organization, # Source
        as: 'referer'
      Referral.belongsTo models.User, 
        as: 'user'
      return

  return Referral
