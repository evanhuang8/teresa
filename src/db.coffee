path = require 'path'

sequelize = require 'sequelize'

T_DB_HOST = process.env.T_DB_HOST or 'localhost'
T_DB_USER = process.env.T_DB_USER or 'root'
T_DB_PASS = process.env.T_DB_PASS or '1tism0db'
T_DB_NAME = process.env.T_DB_NAME or 'Teresa'

client = new sequelize T_DB_NAME, T_DB_USER, T_DB_PASS, 
  host: T_DB_HOST
  logging: false
  dialect: 'mysql'
  timezone: '+00:00'

importTable = (name) ->
  return client.import path.join __dirname, "/models/#{name}"

models = 
  Client: importTable 'client'
  Community: importTable 'community'
  Organization: importTable 'Organization'
  User: importTable 'user'
  Referral: importTable 'referral'
  ShelterService: importTable 'shelter'

# Association
for name, model of models
  if model.options.hasOwnProperty 'associate'
    model.options.associate models
  if model.options.hasOwnProperty 'overrideScopes'
    model.options.overrideScopes models

module.exports.client = client
module.exports.model = (name) ->
  return client.model name