###
Service
###

moment = require 'moment-timezone'

SERVICE_TYPES = [
  'shelter'
  'health'
  'housing'
  'job'
  'food'
  'funding'
]

module.exports = (sequelize, DataTypes) ->

  Service = sequelize.define 'Service', 
    type: 
      type: DataTypes.STRING
      allowNull: false
      validate:
        isIn: [SERVICE_TYPES]
    name: 
      type: DataTypes.STRING
      allowNull: false
    description:
      type: DataTypes.TEXT
      allowNull: false
    businessHours: 
      type: DataTypes.TEXT
      allowNull: false
      set: (intervals) ->
        if not Array.isArray(intervals) or intervals.length isnt 7
          throw new Error 'Invalid business hour intervals!'
        for i in [0...7]
          interval = intervals[i]
          if not interval?
            throw new Error 'Invalid business hour intervals!'
          if not interval.always
            start = moment interval.start, 'hh:mmA', true
            end = moment interval.end, 'hh:mmA', false
            if interval.overnight
              end.add 1, 'day'
            if not start.isValid() or not end.isValid() or start > end
              throw new Error 'Invalid business hour intervals!'
        @setDataValue 'businessHours', JSON.stringify intervals
        return
      get: () ->
        intervals = []
        try
          intervals = JSON.parse @getDataValue 'businessHours'
        catch err
          intervals = []
        return intervals
    maxCapacity:
      type: DataTypes.INTEGER
      allowNull: false
      validate:
        min: 0
    openCapacity:
      type: DataTypes.INTEGER
      allowNull: false
      validate:
        min: 0
    isConfirmationRequired: 
      type: DataTypes.BOOLEAN
      defaultValue: false
    completionCost: DataTypes.FLOAT
    missedCost: DataTypes.FLOAT
    refreshedAt: DataTypes.DATE
  ,
    timestamps: true
    paranoid: true
    associate: (models) ->
      Service.belongsTo models.Organization,
        as: 'organization'
      return
    classMethods: 
      isOpen: (businessHours, tz) ->
        now = moment.tz tz
        day = now.day()
        interval = businessHours[day]
        if interval.always
          return true
        start = moment interval.start, 'hh:mmA'
        end = moment interval.end, 'hh:mmA'
        if interval.overnight
          end.add 1, 'day'
        return start < now and now < end

  return Service
