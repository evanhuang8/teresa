###
Client model
###

CLIENT_STAGE_OK = 'ok'
CLIENT_STAGE_UNKNOWN = 'unknown'
CLIENT_STAGE_EMERGENT = 'emergent'
CLIENT_STAGE_HOMELSS = 'homeless'
CLIENT_STAGE_REHAB = 'rehab'

module.exports = (sequelize, DataTypes) ->

  Client = sequelize.define 'Client', 
    firstName: DataTypes.STRING
    middleName: DataTypes.STRING
    lastName: DataTypes.STRING
    phone: DataTypes.STRING
    dob: 
      type: DataTypes.STRING
      validate:
        isDOB: (value) ->
          result = /^\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])$/.test value
          if not result
            throw new Error 'The date of birth is invalid!'
          return
    ssn: DataTypes.STRING
    # Control states
    stage: 
      type: DataTypes.STRING
      allowNull: false
      validate: 
        isIn: [
          [
            CLIENT_STAGE_OK
            CLIENT_STAGE_UNKNOWN
            CLIENT_STAGE_EMERGENT
            CLIENT_STAGE_HOMELSS
            CLIENT_STAGE_REHAB
          ]
        ]
  ,
    timestamps: true
    paranoid: true

  return Client
