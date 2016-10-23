_ = require 'lodash'
sequelize = require 'sequelize'

db = require '../db'
client = db.client

Organization = db.model 'Organization'

averageCostPerClient = (opts) ->
  query = "
    SELECT SUM(Services.missedCost) AS cost,
       clientId,
       organizationId
    FROM Referrals
    INNER JOIN Services ON Referrals.serviceId = Services.id 
    WHERE Referrals.isComplete = 0 
    GROUP BY clientId,
             organizationId
  "
  missedCosts = yield client.query query, 
    type: sequelize.QueryTypes.SELECT
  query = "
    SELECT SUM(Services.completionCost) AS cost,
       clientId,
       organizationId
    FROM Referrals
    INNER JOIN Services ON Referrals.serviceId = Services.id 
    WHERE Referrals.isComplete = 0 
    GROUP BY clientId,
             organizationId
  "
  completionCosts = yield client.query query, 
    type: sequelize.QueryTypes.SELECT
  costsByOrgs = {}
  for row in missedCosts
    if not costsByOrgs[row.organizationId]?
      costsByOrgs[row.organizationId] = {}
    costsByOrgs[row.organizationId][row.clientId] = row.cost
  for row in completionCosts
    if not costsByOrgs[row.organizationId]?
      costsByOrgs[row.organizationId] = {}
    if not costsByOrgs[row.organizationId][row.clientId]?
      costsByOrgs[row.organizationId][row.clientId] = 0
    costsByOrgs[row.organizationId][row.clientId] += row.cost
  dataByOrgs = {}
  for orgId, costsByClients of costsByOrgs
    n = 0
    totalCost = 0
    for key, cost of costsByClients
      n++
      totalCost += cost
    if n is 0
      dataByOrgs[orgId] = 
        avg: 0
        n: 0
    else
      dataByOrgs[orgId] = 
        avg: totalCost / n
        n: n
  ids = Object.keys dataByOrgs
  orgs = []
  if ids.length > 0
    orgs = yield Organization.findAll
      where:
        id:
          $in: ids
    for org in orgs
      if dataByOrgs[org.id]?
        org.dataValues.avgCost = dataByOrgs[org.id].avg
        org.dataValues.avgCostN = dataByOrgs[org.id].n
  return orgs

module.exports = 

  index: () ->
    if not @passport.user?
      @redirect '/login'
      return
    @render 'analytics/index', 
      user: @passport.user
    yield return

  data_costs: ->
    orgs = yield averageCostPerClient {}
    orgs = _.sortBy orgs, (org) -> org.avgCost
    @body = 
      status: 'OK'
      orgs: orgs
    return