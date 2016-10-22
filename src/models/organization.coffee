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
    address: 
      type: DataTypes.STRING
      allowNull: false
    lat: 
      type: DataTypes.DOUBLE
      allowNull: false
      validate:
        min: -90
        max: 90
    lng:
      type: DataTypes.DOUBLE
      allowNull: false
      validate:
        min: -180
        max: 180
  ,
    timestamps: true
    paranoid: true
    associate: (models) ->
      Organization.belongsTo models.Community, 
        as: 'community'
      return

  return Organization
