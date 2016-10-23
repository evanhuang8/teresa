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
          <div className="card">
            <div className="card-block">
              <h4 className="card-title" style={
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis'
              }>{org.name}</h4>
              <h6 className="card-subtitle text-muted" style={
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis'
              }>{org.description}</h6>
            </div>
            <ul className="list-group list-group-flush">
              <li className="list-group-item" style={
                  height: '150px'
                }>            
                <img src={org.image} style={
                  maxWidth: '75%',
                  maxHeight: '75%',
                  margin: '20px auto',
                  display: 'block'
                } />
              </li>
            </ul>
            <div className="card-block">
              <div className="row card-text">
                <div className="col-md-4">                
                  <h6>
                    H30P
                  </h6>
                  <h3>{if org.rate? then (org.rate * 100).toFixed(0) else '0'}%</h3>
                </div>
                <div className="col-md-4">                
                  <h6>
                    ATTH
                  </h6>
                  <h3>{if org.atth? then org.atth.toFixed(0) else '?'}D</h3>
                </div>
                <div className="col-md-4">                
                  <h6>
                    Clients
                  </h6>
                  <h3>{org.avgCostN}</h3>
                </div>
              </div>                
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