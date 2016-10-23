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
        Teresa.alert 'Success', 'The referral has been confirmed!'
        @fetchReferrals()
      else
        console.log response
    return

  componentDidMount: ->
    @fetchReferrals()
    return

  render: ->
    <table className="table">
      <thead>
        <tr>
          <th>Date</th>
          <th>Client Name</th>
          <th>Service Name</th>
          <th>Referred By</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        {
          if @state.referrals? and @state.referrals.length > 0
            @state.referrals.map (referral) =>
              <ReferralListItem
                referral={referral}
                handleConfirmReferral={@handleConfirmReferral}
              />
        }
      </tbody>
    </table>

ReferralListItem = React.createClass

  getInitialState: ->
    state = {}
    return state

  render: ->
    referral = @props.referral
    <tr>
      <td>
        {moment.tz(referral.createdAt, 'US/Central').format('MM/DD hh:mmA')}
      </td>
      <td>
        {referral.client.firstName} {referral.client.lastName}
      </td>
      <td>
        {
          if referral.referer?
            referral.referer.name
        }
      </td>
      <td>
        {referral.service.name}
      </td>
      <td>
        {
          if not referral.isConfirmed
            <a className="btn btn-sm btn-success" href="javascript:;" onClick={@props.handleConfirmReferral.bind @, referral}>Confirm</a>
          else
            <span>
              {
                if referral.isComplete
                  'Completed'
                else
                  'Confirmed'

              }
            </span>
        }
      </td>
    </tr>

@Teresa.referral.all = 

  referralList: undefined

  init: () ->

    @referralList = React.render(<ReferralList />, $('div#referral-list')[0])

    Teresa.handleNewReferral = (referral) =>
      @referralList.fetchReferrals()
      return
  
    return