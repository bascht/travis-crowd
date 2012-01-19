String.prototype.camelize = ->
  this.slice(0, 1).toUpperCase() + this.slice(1)

Array.prototype.compact = ->
  _this = this
  $.each this, (ix, value) ->
    _this.splice(ix, 1) if !value

Donations = (table, pagination) ->
  this.tbody = $('tbody', table)
  this.pagination = new Pagination(this, pagination, Donations.COUNT)
  this.load()

$.extend Donations,
  URL: '/donations.json'
  COUNT: 10

$.extend Donations.prototype,
  load: ()->
    $.get Donations.URL, this.render.bind(this)
  clear: ->
    $(this.tbody).empty()
  render: (data) ->
    _this = this
    this.data = data if data
    this.clear()
    this.pagination.update()

    $.each this.pagination.data(), (ix, record) ->
      row = $('<tr></tr>')
      $.each new Donation(record).values(), (ix, value)->
        row.append $('<td>' + value + '</td>')
      _this.tbody.append(row)

Donation = (data) ->
  this.data = data
  this.user = data.user
  this

$.extend Donation.prototype,
  values: ->
    _this = this
    names = ['gravatar', 'links', 'amount', 'package', 'date', 'comment']
    $.map names, (name) ->
      _this[name]()
  gravatar: ->
    '<img src="' + this.user.gravatar_url + '">'
  links: ->
    [this.name(), this.github(), this.twitter()].compact().join('')
  name: ->
    if this.user.homepage
      "<a href=\"#{this.user.homepage}\">#{this.user.name}</a>"
    else
      this.user.name
  github: ->
    "<a href=\"https://github.com/#{this.user.github_handle}\" class=\"github\">#{this.user.github_handle}</a>" if this.user.github_handle
  twitter: ->
    "<a href=\"https://twitter.com/#{this.user.twitter_handle}\" class=\"twitter\">#{this.user.twitter_handle}</a>" if this.user.twitter_handle
  amount: ->
    '$' + this.data.total
  package: ->
    "<span class=\"package #{this.data.package}\">#{this.data.package.camelize()}</span>" + this.subscription()
  subscription: ->
    if this.data.subscription then '<span class="subscription" title="subscription">yes</span>' else ''
  date: ->
    new Date(this.data.created_at).format('mediumDate')
  comment: ->
    this.data.comment


$.fn.donations = ()->
  new Donations(this, $('.pagination', this))

$(document).ready ->
  if $('#donations').length > 0
    $('#donations').donations()

    if EventSource?
      src = new EventSource('/orders.es')
      src.onmessage = (e) ->
        payload = JSON.parse e.data
        order   = payload.order
        user    = order.user
        Notifier.notify "We've got another one!", "#{user.name} just donated $#{order.total}!", user.gravatar_url, 2000
