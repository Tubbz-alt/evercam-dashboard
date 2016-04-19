stream_paused = false
img_real_width = 0
img_real_height = 0
live_view_timestamp = 0
image_placeholder = null

sendAJAXRequest = (settings) ->
  token = $('meta[name="csrf-token"]')
  if token.size() > 0
    headers =
      "X-CSRF-Token": token.attr("content")
    settings.headers = headers
  xhrRequestChangeMonth = $.ajax(settings)

controlButtonEvents = ->
  $(".play-pause").on "click", ->
    if stream_paused
      $(this).children().removeClass "icon-control-play"
      $(this).children().addClass "icon-control-pause"
      playJpegStream()
    else
      $(this).children().removeClass "icon-control-pause"
      $(this).children().addClass "icon-control-play"
      stopJpegStream()
    stream_paused = !stream_paused

  $('#refresh-offline-camera').on "click", ->
    $('.fa-refresh').hide()
    $('.refresh-gif').show()
    refreshCameraStatus()

hidegif = ->
  $('.refresh-gif').hide()
  $('.fa-refresh').show()

refreshCameraStatus = ->
  data = {}
  data.with_data = true

  onError = (jqXHR, status, error) ->
    message = jqXHR.responseJSON.message
    Notification.show message
    hidegif()

  onSuccess = (data, status, jqXHR) ->
    location.reload()
    hidegif()

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/x-www-form-urlencoded"
    type: 'POST'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"

  sendAJAXRequest(settings)

fullscreenImage = ->
  $("#toggle").click ->
    screenfull.toggle $("#live-player-image")[0]
  $("#live-player-image").dblclick ->
    screenfull.toggle $(this)[0]

  if screenfull.enabled
    document.addEventListener screenfull.raw.fullscreenchange, ->
      $("#live-player-image").css('width','auto')

openPopout = ->
  $("#link-popout").on "click", ->
    $("<img/>").attr("src", image_placeholder.src).load( ->
      window.open("/live/#{Evercam.Camera.id}", "_blank", "width=#{@width}, height=#{@height}, scrollbars=0")
    ).error ->
      window.open("/live/#{Evercam.Camera.id}", "_blank", "width=640, height=600, scrollbars=0")

initializePlayer = ->
  window.vjs_player = videojs 'camera-video-player', {techOrder: ["flash", "hls", "html5"]}
  $("#camera-video-player").append($("#ptz-control"))
  setInterval (->
    if $('.vjs-control-bar').css('visibility') == 'visible'
      $('#live-view-placeholder .pull-right table').css 'marginTop', '-78px'
      $('#live-view-placeholder .pull-right table').stop().animate()
    else
      $('#live-view-placeholder .pull-right table').animate { 'marginTop': '-39px' }, 500
  ), 10

destroyPlayer = ->
  unless $('#camera-video-stream').html() == ''
    $("#jpg-portion").append($("#ptz-control"))
    window.vjs_player.dispose()
    $("#camera-video-stream").html('')

handleChangeStream = ->
  $("#select-stream-type").on "change", ->
    switch $(this).val()
      when 'jpeg'
        destroyPlayer()
        $('.flash-error-message').hide()
        $("#streams").removeClass("active").addClass "inactive"
        $("#fullscreen").removeClass("inactive").addClass "active"
        playJpegStream()
        $('#live-view-placeholder .pull-right table').css 'margin-top', '-39px'
        $('.tabbable-custom > .tab-content').css 'padding-bottom', '0px'
        $("#camera-video-stream").hide()
        $(".video-js").css 'height', '0px'
      when 'video'
        $("#camera-video-stream").html(video_player_html)
        initializePlayer()
        flashDetection()
        $("#fullscreen").removeClass("active").addClass "inactive"
        $("#streams").removeClass("inactive").addClass "active"
        stopJpegStream()
        $('#live-view-placeholder .pull-right table').css 'background-color', 'transparent'
        $("#camera-video-stream").show()
        imgHeight = $("#camera-video-stream").height()
        $(".video-js").css 'height', "#{imgHeight}px"

handleTabOpen = ->
  $('.nav-tab-live').on 'show.bs.tab', ->
    playJpegStream()
    if $('#select-stream-type').length
      $("#select-stream-type").trigger "change"

  $('.nav-tab-live').on 'hide.bs.tab', ->
    stopJpegStream()
    if $('#select-stream-type').length
      destroyPlayer()

  if $(".nav-tabs li.active a").attr("data-target") is "#live"
    if $('#select-stream-type').length
      $("#select-stream-type").trigger "change"
    else
      $(".nav-tabs li.active a").trigger("show.bs.tab")

handleSaveSnapshot = ->
  $('#save-live-snapshot').on 'click', ->
    SaveImage.save($("#live-player-image").attr('src'), "#{Evercam.Camera.id}-#{moment().toISOString()}.jpg")

getImageRealRatio = ->
  $('<img/>').attr('src', $("#live-player-image").attr('src')).load ->
    img_real_width = @width
    img_real_height = @height
    if img_real_width is 0 && img_real_height is 0
      setTimeout(getImageRealRatio(), 1000)

calculateHeight = ->
  content_height = Metronic.getViewPort().height + $(".page-header").height()
  content_width = Metronic.getViewPort().width
  tab_menu_height = $("#ul-nav-tab").height()
  side_bar_width = $(".page-sidebar").width()
  image_height = content_height - (tab_menu_height *2)
  if $(".page-sidebar").css('display') is "none"
    content_width = content_width - side_bar_width

  $("#console-log").text("Real-Width: #{img_real_width}, content-width: #{content_width}")
  if $(".page-sidebar").css('display') is "none" && img_real_width > content_width
    image_height = img_real_height / img_real_width * content_width

  $("#live-player-image").css({"height": "#{image_height}px","max-height": "100%"})
  $(".offline-camera-placeholder .camera-thumbnail").css({"height": "#{image_height}px","max-height": "100%"})

  if $(window).width() >= 668
    $("#camera-video-stream").css({"height": "#{image_height}px","max-height": "100%"})
    $(".video-js").css({"height": "#{image_height}px"})

  if $(window).width() <= 668
    $("#live-player-image").css({"height": "375px"})
  if $(window).width() <= 480
    $("#live-player-image").css({"height": "270"})
  if $(window).width() <= 380
    $("#live-player-image").css({"height": "220"})

handleResize = ->
  getImageRealRatio()
  calculateHeight()
  $(window).resize ->
    calculateHeight()

handlePtzCommands = ->
  $(".ptz-controls").on 'click', 'i', ->
    headingText = $('#ptz-control table thead tr th').text()
    $('#ptz-control table thead tr th').html 'Waiting <div class="loader"></div>'
    ptz_command = $(this).attr("data-val")
    if !ptz_command
      return
    api_url = "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/relative?#{ptz_command}&api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    if ptz_command is "home"
      api_url = "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/#{ptz_command}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    data = {}

    onComplete = (result) ->
      $('#ptz-control table thead tr th').html headingText

    settings =
      cache: false
      data: data
      dataType: 'json'
      error: onComplete
      success: onComplete
      contentType: "application/json; charset=utf-8"
      type: 'POST'
      url: api_url
    sendAJAXRequest(settings)

getPtzPresets = ->
  if !$(".ptz-controls").html()
    return
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onSuccess = (result) ->
    for preset in result.Presets
      if preset.token < 33
        divPresets =$('<div>', {class: "row-preset"})
        divPresets.append($(document.createTextNode(preset.Name)))
        divPresets.attr("token_val", preset.token)
        $("#presets-table").append(divPresets)

  settings =
    cache: false
    data: data
    dataType: 'json'
    success: onSuccess
    contentType: "application/json; charset=utf-8"
    type: 'GET'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/presets"
  sendAJAXRequest(settings)

changePtzPresets = ->
  $("#camera-presets").on 'click', '.row-preset', ->
    data = {}

    settings =
      cache: false
      data: data
      dataType: 'json'
      contentType: "application/json; charset=utf-8"
      type: 'POST'
      url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/presets/go/#{$(this).attr("token_val")}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    sendAJAXRequest(settings)
    $('#camera-presets').modal('hide')

createPtzPresets = ->
  $('#create-preset').on 'click', '.add-preset', ->
    preset_name = $('.preset-value').val()
    encoded_name = encodeURIComponent(preset_name)
    data = {}
    data.id = Evercam.Camera.id
    data.preset_name = preset_name

    onError = (jqXHR, status, error) ->
      message = jqXHR.responseJSON.message
      Notification.show message

    onSuccess = (data, status, jqXHR) ->
      Notification.show "Preset Added Successfully"

    settings =
      cache: false
      data: data
      dataType: 'json'
      success: onSuccess
      error: onError
      contentType: "application/json; charset=utf-8"
      type: 'POST'
      url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/ptz/presets/create/#{encoded_name}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
    sendAJAXRequest(settings)

handleModelEvents = ->
  $("#camera-presets").on "show.bs.modal", ->
    $("#ptz-control").addClass("hide")

  $("#camera-presets").on "hidden.bs.modal", ->
    $("#ptz-control").removeClass("hide")
    $('#ptz-control table thead tr th').html 'PTZ'

playJpegStream = ->
  Evercam.camera_channel = Evercam.socket.channel("cameras:#{Evercam.Camera.id}", {api_id: Evercam.User.api_id, api_key: Evercam.User.api_key})
  Evercam.camera_channel.join()
  Evercam.camera_channel.on 'snapshot-taken', (payload) ->
    $(".btn-live-player").removeClass "hide"
    if payload.timestamp >= live_view_timestamp and not stream_paused
      live_view_timestamp = payload.timestamp
      $('#live-player-image').attr('src', 'data:image/jpeg;base64,' + payload.image)

stopJpegStream = ->
  Evercam.camera_channel.leave() if Evercam.camera_channel

checkPTZExist = ->
  if $(".ptz-controls").length > 0
    $('.live-options').css('top','114px').css('right','32px')

$(window).load HideMessage = ->
  if !$(".wrap img#message").hasClass("no-thumbnail")
    $("#offline_message").show()

flashDetection = ->
  if !swfobject.hasFlashPlayerVersion("9.0.115") and Evercam.Camera.is_online and $('#select-stream-type').val() is "video"
    $('.vjs-error-display').hide()
    $('.flash-error-message').show()

window.initializeLiveTab = ->
  window.video_player_html = $('#camera-video-stream').html()
  window.vjs_player = {}
  image_placeholder = document.getElementById("live-player-image")
  controlButtonEvents()
  fullscreenImage()
  openPopout()
  handleResize()
  handleChangeStream()
  handleTabOpen()
  handleSaveSnapshot()
  handlePtzCommands()
  getPtzPresets()
  changePtzPresets()
  handleModelEvents()
  checkPTZExist()
  flashDetection()
  createPtzPresets()

->
  calculateHeight()
