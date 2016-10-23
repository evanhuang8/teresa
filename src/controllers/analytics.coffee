sequelize = require 'sequelize'

db = require '../db'
client = db.client

averageCostPerClient = (opts) ->
  query = "
    SELECT clientId,
      SUM(missedCost) AS cost
    FROM Services
    INNER JOIN Referrals ON Services.id = Referrals.serviceId
    WHERE isComplete = 0
      AND clientId IN
        (SELECT clientId
         FROM Referrals
  "
  if opts.refereeId?
    query += " WHERE refereeId = #{opts.refereeId} "
  query += "
         GROUP BY clientId)
    GROUP BY clientId
  "
  missedCosts = yield client.query query, 
    type: sequelize.QueryTypes.SELECT
  query = "
    SELECT clientId,
      SUM(completionCost) AS cost
    FROM Services
    INNER JOIN Referrals ON Services.id = Referrals.serviceId
    WHERE isComplete = 1
      AND clientId IN
        (SELECT clientId
         FROM Referrals
  "
  if opts.refereeId?
    query += " WHERE refereeId = #{opts.refereeId} "
  query += "
         GROUP BY clientId)
    GROUP BY clientId
  "
  completionCosts = yield client.query query, 
    type: sequelize.QueryTypes.SELECT
  costsByClients = {}
  for row in missedCosts
    costsByClients[row.clientId] = row.cost
  for row in completionCosts
    if not costsByClients[row.client]?
      costsByClients[row.client] = 0
    costsByClients[row.client]+= row.cost
  n = 0
  totalCost = 0
  for key, cost of costsByClients
    n++
    totalCost += cost
  if n is 0
    return [0, 0]
  return [totalCost / n, n]

module.exports = 

  index: () ->
    if not @passport.user?
      @redirect '/login'
      return
    @render 'analytics/index', 
      user: @passport.user
    return

  data_costs: ->
    orgId = @request.query.orgId
    [avgCost, n] = yield averageCostPerClient
      refereeId: orgId
    @body = 
      status: 'OK'
      average: avgCost
      n: n
    return