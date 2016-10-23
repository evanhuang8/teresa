if not @Teresa.referral?
  @Teresa.referral = {}

ReferralList = React.createClass

  getInitialState: ->
    state =
      keyword: @props.keyword
      referrals: null
    return state

  fetchReferrals: ->
    params =
      keyword: @state.keyword
    Teresa.postJSON '/referral/fetch', params, (response) =>
      if response.status is 'OK'
        @setState
          referrals: response.referrals
      return
    return

  handleConfirmReferral: (referral) ->
    params =
      referral: referral.id
    Teresa.postJSON '/referral/confirm', params, (response) =>
      if response.status is 'OK'
        console.log response
      else
        console.log response
    return

  componentDidMount: ->
    @fetchReferrals()
    return

  render: ->
    console.log @state.referrals
    <div>
      {
        if @state.referrals? and @state.referrals.length > 0
          @state.referrals.map (referral) =>
            <ReferralListItem
              referral={referral}
              handleConfirmReferral={@handleConfirmReferral}
            />
      }
    </div>

ReferralListItem = React.createClass

  getInitialState: ->
    state = {}
    return state

  render: ->
    referral = @props.referral
    <div className="row">
      <div className="col-md-2">
        {moment.tz(referral.createdAt, 'US/Central').format('MM/DD/YYYY')}
      </div>
      <div className="col-md-2">
        {referral.client.firstName} {referral.client.lastName}
      </div>
      <div className="col-md-3">
        {
          if referral.referer?
            referral.referer.name
        }
      </div>
      <div className="col-md-3">
        {referral.service.name}
      </div>
      <div className="col-md-2 text-right">
        {
          if not referral.isConfirmed
            <a className="btn btn-sm btn-success" href="javascript:;" onClick={@props.handleConfirmReferral.bind @, referral}>Confirm</a>
          else
            <div>
              {
                if referral.isComplete
                  'Completed'
                else
                  'Pending'

              }
            </div>
        }
      </div>
    </div>

@Teresa.referral.all = 

  init: () ->
    React.render(<ReferralList />, $('div#referral-list')[0])
    return