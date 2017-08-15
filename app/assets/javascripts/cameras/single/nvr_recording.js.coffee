retries = 0
total_tries = 6
times_list = undefined
BoldDays = []
minutes_select = null
seconds_select = null
is_come_from_url = false

showFeedback = (message) ->
  Notification.show(message)

SetInfoMessage = (from, to) ->
  from_dt = moment(from*1000)
  to_dt = moment(to*1000).toISOString()

  minutes_select.val(from_dt.minutes()).trigger("change")
  seconds_select.val(from_dt.seconds()).trigger("change")
  url = "#{Evercam.request.rootpath}/local-recordings?from=#{from_dt.toISOString()}&to=#{to_dt}"
  if $("#ul-nav-tab li.active a").text() is "Local Recordings" && history.replaceState
    window.history.replaceState({}, '', url)

load_stream = (from, to) ->
  $("#local-recording-video-player .vjs-loading-spinner").show()
  $("#local-recording-video-player .vjs-big-play-button").hide()
  SetInfoMessage(from, to)
  onSuccess = (response) ->
    retries = 0
    setTimeout(is_stream_created, 3000)

  onError = (jqXHR, status, error) ->
    $("#local-recording-video-player .vjs-loading-spinner").hide()
    $(".bb-alert").removeClass("alert-info").addClass("alert-danger")
    Notification.show("Something went wrong, Please try again.")

  query_string = "?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
  query_string += "&starttime=#{from}&endtime=#{to}"

  settings =
    cache: false
    data: {}
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/nvr/stream#{query_string}"
  $.ajax(settings)

is_stream_created = ->
  onSuccess = (response) ->
    set_stream_source()

  onError = (jqXHR, status, error) ->
    if retries >= total_tries
      $("#local-recording-video-player .vjs-loading-spinner").hide()
      $(".bb-alert").removeClass("alert-info").addClass("alert-danger")
      Notification.show("Failed to load stream.")

  settings =
    cache: false
    data: {}
    dataType: 'text'
    error: onError
    success: onSuccess
    statusCode: {
      404: ->
        setTimeout(is_stream_created, 3000) if retries < total_tries
        retries = retries + 1
    }
    type: 'GET'
    url: "https://media.evercam.io/hls/#{Evercam.Camera.id}/index.m3u8?nvr=true"

  $.ajax(settings)

play_pause = ->
  $("#local_recordings_tab .vjs-text-track-display").on "click", ->
    if (window.vjs_player_local.paused())
      window.vjs_player_local.play()
      $("#local-recording-video-player .vjs-big-play-button").hide()
    else
      window.vjs_player_local.pause()
      $("#local-recording-video-player .vjs-big-play-button").show()

  $("#local_recordings_tab .vjs-play-control").on "click", ->
    if (!window.vjs_player_local.paused())
      window.vjs_player_local.play()
      $("#local-recording-video-player .vjs-big-play-button").hide()
    else
      window.vjs_player_local.pause()
      $("#local-recording-video-player .vjs-big-play-button").show()

isplayed = ->
  if (!window.vjs_player_local.played)
    window.vjs_player_local.play()
    setTimeout(isplayed, 1000)
  else
    $("#local-recording-video-player .vjs-loading-spinner").hide()

initializePlayer = ->
  window.vjs_player_local = videojs('local-recording-video-player')
  $("#local-recording-video-player div.vjs-control-bar").append($("#div-capture"))

set_stream_source = ->
  $("#local-recording-video-player .vjs-loading-spinner").hide()
  window.vjs_player_local.play()
  window.vjs_player_local.src([
    { type: "application/x-mpegURL", src: "https://media.evercam.io/hls/#{Evercam.Camera.id}/index.m3u8?nvr=true" },
    { type: "rtmp/flv", src: "rtmp://media.evercam.io:1935/live/#{Evercam.Camera.id}?nvr=true" }
  ])

initDatePicker = ->
  $("#ui_date_picker_inline_lr").datepicker().on("changeDate", datePickerSelect).on "changeMonth", datePickerChange
  $("#ui_date_picker_inline_lr table th[class*='prev']").on "click", ->
    changeMonthFromArrow('p')

  $("#ui_date_picker_inline_lr table th[class*='next']").on "click", ->
    changeMonthFromArrow('n')

  $("#local_recording_hourCalendar td[class*='day']").on "click", ->
    hour = parseInt($(this).html())
    init_graph(hour)

datePickerSelect = (value)->
  dt = value.date
  ResetDays()
  boldRecordingHours()

datePickerChange=(value)->
  d = value.date
  year = d.getFullYear()
  month = d.getMonth() + 1
  walkDaysInMonth(year, month)

changeMonthFromArrow = (value) ->
  $("#ui_date_picker_inline_lr").datepicker('fill')
  d = $("#ui_date_picker_inline_lr").datepicker('getDate')
  month = d.getMonth()
  year = d.getFullYear()
  if value is 'n'
    month = month + 2
  if month is 13
    month = 1
    year++
  if month is 0
    month = 12
    year--

  walkDaysInMonth(year, month)

  if value =='n'
    d.setMonth(d.getMonth()+1)
  else if value =='p'
    d.setMonth(d.getMonth()-1)
  $("#ui_date_picker_inline_lr").datepicker('setDate',d)

clearHourCalendar = ->
  $("#hourCalendar td[class*='day']").removeClass("active")
  calDays = $("#hourCalendar td[class*='day']")
  calDays.each ->
    calDay = $(this)
    calDay.removeClass('has-snapshot')

FormatNumTo2 = (n) ->
  if n < 10
    "0#{n}"
  else
    n

capture_image = ->
  $("#div-capture").on "click", ->
    $pop = Popcorn("#local-recording-video-player_html5_api");
    $pop.capture
      set: false
      target: "img#captured"
      reload: false
    SaveImage.save($("#captured").attr('src'), "#{Evercam.Camera.id}.png")

set_position = ->
  content_width = Metronic.getViewPort().width
  content_height = Metronic.getViewPort().height
  content_height = content_height - $('.center-tabs').height()
  side_bar_width = $(".page-sidebar").width()
  if $(".page-sidebar").css('display') is "block"
    content_width = content_width - side_bar_width;
  $("#local_recordings_tab .left-column").css("width", "#{content_width - 225}px")
  $("#local_recordings_tab .right-column").css("width", "220px")
  $("#local_recordings_tab #local-recording-placeholder").css("height", "#{content_height - 74}px")
  $("#local_recordings_tab #local-recording-video-player").css("height", "#{content_height - 74}px")
  $("#local-recording-video-player_html5_api").css("height", "#{content_height - 74}px")

handleResize = ->
  set_position()
  $(window).resize ->
    set_position()
    load_graph(times_list) unless times_list is undefined

  $(window).unload ->
    console.log("Handler for .unload() called.")

handleTabOpen = ->
  $('.nav-tab-local-recordings').on 'shown.bs.tab', ->
    onChangeStream()
    set_position()
  $('.nav-tab-local-recordings').on 'hide.bs.tab', ->
    window.vjs_player_local.pause()
    closeStream()
  $("#spn_load_stream").on "click", ->
    onChangeStream()

onChangeStream = ->
  date = $("#ui_date_picker_inline_lr").datepicker('getDate')
  year = date.getFullYear()
  month = date.getMonth() + 1
  day = date.getDate()
  hr = $("#local_recording_hourCalendar td.active").text()
  from = moment.tz("#{year}-#{month}-#{day} #{hr}:#{minutes_select.val()}:#{seconds_select.val()}", Evercam.Camera.timezone) / 1000
  to = moment.tz("#{year}-#{month}-#{day} #{hr}:59:59", Evercam.Camera.timezone) / 1000
  if window.vjs_player_local
    window.vjs_player_local.pause()
  load_stream(from, to)

on_ended_play = ->
  window.vjs_player_local.on "ended", ->
    false

  window.vjs_player_local.on "play", ->
    #$("#local-recording-video-player .vjs-big-play-button").hide()
    true

  window.vjs_player_local.on "pause", ->
    #$("#local-recording-video-player .vjs-big-play-button").show()
    true

  window.vjs_player_local.on "error", ->
    $("#local-recording-video-player div.vjs-error-display").hide()

init_graph = (hr) ->
  onSuccess = (response) ->
    if response.times_list.length > 0
      times_list = response.times_list
      load_graph(times_list)
      if !is_come_from_url && $("#ul-nav-tab li.active a").text() is "Local Recordings"
        if window.vjs_player_local
          window.vjs_player_local.pause()
        $("#local-recording-video-player .vjs-loading-spinner").show()
        load_stream(this.from, this.to)
      is_come_from_url = false
    else
      times_list =
        [
          [
            "#{this.year}-#{FormatNumTo2(this.month)}-#{FormatNumTo2(this.day)} #{FormatNumTo2(this.hour)}:00:00",
            0,
            "#{this.year}-#{FormatNumTo2(this.month)}-#{FormatNumTo2(this.day)} #{FormatNumTo2(this.hour)}:59:59"
          ]
        ]
      load_graph(times_list)

  onError = (jqXHR, status, error) ->
    times_list =
      [
        [
          "#{this.year}-#{FormatNumTo2(this.month)}-#{FormatNumTo2(this.day)} #{FormatNumTo2(this.hour)}:00:00",
          0,
          "#{this.year}-#{FormatNumTo2(this.month)}-#{FormatNumTo2(this.day)} #{FormatNumTo2(this.hour)}:59:59"
        ]
      ]
    load_graph(times_list)

  $("#local_recording_hourCalendar td").removeClass("active")
  $("#lr_tdI#{hr}").addClass("active")
  date = $("#ui_date_picker_inline_lr").datepicker('getDate')
  year = date.getFullYear()
  month = date.getMonth() + 1
  day = date.getDate()
  from = moment.tz("#{year}-#{month}-#{day} #{hr}:00:00", Evercam.Camera.timezone) / 1000
  to = moment.tz("#{year}-#{month}-#{day} #{hr}:59:59", Evercam.Camera.timezone) / 1000

  query_string = "?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
  query_string += "&starttime=#{from}&endtime=#{to}"

  settings =
    data: {}
    dataType: 'json'
    error: onError
    success: onSuccess
    context: {year: year, month: month, day: day, hour: hr, from: from, to: to}
    type: 'GET'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/nvr/videos#{query_string}"

  $.ajax(settings)

load_graph = (times_list) ->
  record_times = [{
    "interval_s": 60 * 5
    "data": times_list
  }]
  chart = visavailChart().margin_left(1).width($("#local_recordings_tab .left-column").width() - 1)
  .line_spacing(6)
  .margin_right(2)
  .tooltip_color("#ffffff")
  $('#time_graph').text ''
  d3.select('#time_graph').datum(record_times).call chart
  $("#local_recordings_tab g.tick:first text").css("text-anchor", "right")

on_graph_click = ->
  $("#local_recordings_tab").on "click", ".rect_has_data", ->
    if window.vjs_player_local
      window.vjs_player_local.pause()
    $("#local-recording-video-player .vjs-loading-spinner").show()
    from = moment.tz("#{$(this).attr("from")}", Evercam.Camera.timezone) / 1000
    to = moment.tz("#{$(this).attr("to")}", Evercam.Camera.timezone) / 1000
    load_stream(from, to)

walkDaysInMonth = (year, month) ->
  BoldDays = []
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (response, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    for day in response.days
      HighlightDay(year, month, day, true)

  settings =
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras/#{Evercam.Camera.id}/nvr/recordings/#{year}/#{month}/days"

  $.ajax(settings)

boldRecordingHours = ->
  $("#local_recording_hourCalendar td").removeClass("has-snapshot")
  d = $("#ui_date_picker_inline_lr").datepicker('getDate')
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (response, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    for hour in response.hours
      $("#lr_tdI#{hour}").addClass('has-snapshot')

  month = FormatNumTo2(d.getMonth() + 1)
  day = FormatNumTo2(d.getDate())

  settings =
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras/#{Evercam.Camera.id}/nvr/recordings/#{d.getFullYear()}/#{month}/#{day}/hours"

  $.ajax(settings)

HighlightDay = (year, month, day, exists) ->
  d = $("#ui_date_picker_inline_lr").datepicker('getDate')
  calendar_year = d.getFullYear()
  calendar_month = d.getMonth() + 1
  if year == calendar_year and month == calendar_month
    calDays = $("#ui_date_picker_inline_lr table td[class*='day']")
    calDays.each ->
      calDay = $(this)
      if !calDay.hasClass('old') && !calDay.hasClass('new')
        iDay = calDay.text()
        if day == iDay
          if exists
            calDay.addClass('has-snapshot')
            BoldDays.push(day)
          else
            calDay.addClass('no-snapshot')

ResetDays = ->
  return unless BoldDays.length > 0
  calDays = $("#ui_date_picker_inline_lr table td[class*='day']")
  calDays.each (idx, el) ->
    calDay = $(this)
    if !calDay.hasClass('old') && !calDay.hasClass('new')
      for day in BoldDays
        if day is calDay.text()
          calDay.addClass('has-snapshot')
        else
          calDay.addClass('no-snapshot')

highlightDaysInMonth = ->
  d = $("#ui_date_picker_inline_lr").datepicker('getDate')
  year = d.getFullYear()
  month = d.getMonth() + 1
  walkDaysInMonth(year, month)

closeStream = ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (response, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    true

  settings =
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras/#{Evercam.Camera.id}/nvr/recordings/stop"

  $.ajax(settings)

getQueryStringByName = (name) ->
  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]')
  regex = new RegExp('[\\?&]' + name + '=([^&#]*)')
  results = regex.exec(location.search)
  if results == null
    null
  else
    decodeURIComponent(results[1].replace(/\+/g, ' '))

handleBodyLoad = ->
  from = getQueryStringByName("from")
  to = getQueryStringByName("to")
  if from && to
    datetime = new Date(moment.utc(from).format('MM/DD/YYYY HH:mm:ss'))
    $("#ui_date_picker_inline_lr").datepicker('update', datetime)
    $("#ui_date_picker_inline_lr").datepicker('setDate', datetime)
    current_hour = datetime.getHours()
    minutes_select.val(datetime.getMinutes()).trigger("change")
    seconds_select.val(datetime.getSeconds()).trigger("change")
    is_come_from_url = true
  else
    current_hour = parseInt($("#camera_current_time").val())
  $("#lr_tdI#{current_hour}").addClass("active")
  init_graph(current_hour)

initSelect2 = ->
  i = 0
  while i < 60
    $("#ddl_minutes").append("<option value='#{i}'>#{FormatNumTo2(i)}</option>")
    $("#ddl_seconds").append("<option value='#{i}'>#{FormatNumTo2(i)}</option>")
    i = i + 1
  minutes_select = $("#ddl_minutes").select2
    width: 49
  seconds_select = $("#ddl_seconds").select2
    width: 49

on_open_archive_model = ->
  $("#local-recording-archive-button").on "click", ->
    $("#txtCreateArchiveType").val("true")

window.initializeLocalRecordingsTab = ->
  window.local_video_player_html = $('#local-recording-stream').html()
  window.vjs_player_local = {}
  initSelect2()
  initDatePicker()
  handleBodyLoad()
  highlightDaysInMonth()
  boldRecordingHours()
  initializePlayer()
  handleResize()
  handleTabOpen()
  capture_image()
  on_ended_play()
  on_graph_click()
  play_pause()
  on_open_archive_model()
