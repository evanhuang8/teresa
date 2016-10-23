AnalyticsCanvas = React.createClass

  getInitialState: () ->
    state = 
      orgs: []
    return state

  componentDidMount: ->
    @fetch()
    return

  fetch: ->
    Teresa.postJSON '/analytics/data_costs/', 
      page: 0
      limit: 50
    , (response) =>
      if response.status is 'OK'
        @setState
          orgs: response.orgs
      return
    return

  render: ->
    <div className="row">
    {
      @state.orgs.map (org, i) ->
        <div key={i} className="col-md-4 col-sm-6">
          <div class="card">
            <img class="card-img-top" src="https://www.fillmurray.com/g/200/300" />
            <div class="card-block">
              <h4 class="card-title">{org.name}</h4>
              <p class="card-text">
                <h6>
                  Average Cost / Client: <b>${org.avgCost.toFixed(2)}</b>
                </h6>
                <h6>
                  Clients: <b>{org.avgCostN}</b>
                </h6>
              </p>
              <a href="#" class="btn btn-primary">View Details</a>
            </div>
          </div>
        </div>
    }
    </div>


@Teresa.analytics = @Teresa.analytics or {}
@Teresa.analytics.index = 

  init: () ->
    React.render <AnalyticsCanvas />, $('#rct-analytics-canvas')[0]
    return