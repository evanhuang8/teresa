###
Checkup model
###

module.exports = (sequelize, DataTypes) ->

  Checkup = sequelize.define 'Checkup', 
    start: DataTypes.DATE
    nextCheckupAt: DataTypes.DATE
    task: DataTypes.STRING
    pastTasks: DataTypes.TEXT
    pastReferralIds: DataTypes.TEXT
  ,
    timestamps: true
    paranoid: true
    associate: (models) ->
      Checkup.belongsTo models.Referral, 
        as: 'referral'
      Checkup.belongsTo models.Client,
        as: 'client'
      Checkup.belongsTo models.Organization,
        as: 'organization'
      return

  return Checkup
