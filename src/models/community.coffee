###
Community model
###

module.exports = (sequelize, DataTypes) ->

  Community = sequelize.define 'Community', 
    name:
      type: DataTypes.STRING
      allowNull: false
    description:
      type: DataTypes.TEXT
      allowNull: false
  ,
    timestamps: true
    paranoid: true

  return Community
