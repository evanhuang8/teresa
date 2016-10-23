###
Intent
###

module.exports = (sequelize, DataTypes) ->

  Intent = sequelize.define 'Intent', 
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
      Intent.belongsTo models.Client, 
        as: 'client'
      Intent.belongsTo models.Service,
        as: 'service'
      Intent.belongsTo models.Referral,
        as: 'referral'
      return

  return Intent
