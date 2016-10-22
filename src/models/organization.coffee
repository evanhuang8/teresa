###
Organization model
###

module.exports = (sequelize, DataTypes) ->

  Organization = sequelize.define 'Organization', 
    name:
      type: DataTypes.STRING
      allowNull: false
    description:
      type: DataTypes.TEXT
      allowNull: false
    lat: 
      type: DataTypes.FLOAT
      allowNull: false
    lng:
      type: DataTypes.FLOAT
      allowNull: false
  ,
    timestamps: true
    paranoid: true
    associate: (models) ->
      Organization.belongsTo models.Community, 
        as: 'community'
      return

  return Organization
