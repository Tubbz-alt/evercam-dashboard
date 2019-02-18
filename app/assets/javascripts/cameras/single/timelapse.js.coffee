videojs_array = {}
format_time = null
camera_select = null

initNotification = ->
  Notification.init(".bb-alert")

loadTimelapses = ->
  onError = (jqXHR, status, error) ->
    Notification.error("Failed to retrive timelapses.")

  onSuccess = (timelapses, status, jqXHR) ->
    if timelapses.length is 0
      #$("#divLoadingApps").show()
    else
      $.each timelapses.timelapses, (index, timelapse) ->
        $('#divTimelapses').append getTimelapseHtml(timelapse, index)
        initPlugins(timelapse)
        toggleWatermarkLogo()

  settings =
    data: {}
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "#{Evercam.API_URL}timelapses?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"
  # cameras/#{Evercam.Camera.id}/
  $.ajax(settings)

initPlugins = (timelapse) ->
  $("#dataslot#{timelapse.id} .radio_edit").iCheck
    radioClass: "iradio_flat-blue"
  $("#dataslot#{timelapse.id} .daterange").datetimepicker({timepicker: false, format: 'd/m/Y'})
  initTimepicker("#dataslot#{timelapse.id} .timerange")
  document.getElementById("timelapse-watermark#{timelapse.id}").addEventListener 'change', readFile
  videojs_array["#{timelapse.id}"] = videojs "video-control-#{timelapse.id}", { }
  initPopup(timelapse.id)

initPopup = (key) ->
  $("#pop-#{key}").popbox
    open: "#open-#{key}"
    box: "#box-#{key}"
    arrow: "#arrow-#{key}"
    arrow_border: "#arrow-border-#{key}"
    close: "#close-popup-#{key}"

getTimelapseHtml = (timelapse, index) ->
  html = "   <div id='dataslot#{timelapse.id}' class='list-border margin-bottom10'>"
  html += "    <div class='col-xs-12 col-sm-6 col-md-4 min-width-325' style='min-height:0px;'>"

  html += "    <div class='' style='margin-top: 5px;'>"
  html += "      <ul id='ul-nav-tab' class='nav nav-tabs'><li class='dropdown pull-right tabdrop hide'></li>"
  html += "        <li id='live-view-tab' class='active'>"
  html += "          <a data-toggle='tab' data-target='#live_video#{timelapse.id}' class='nav-tab-live nav-tab-' aria-expanded='false'><span>View Video</span></a>"
  html += "        </li>"
  html += "        <li id='info-tab'>"
  html += "          <a data-toggle='tab' data-target='#info_tab#{timelapse.id}' class='nav-tab-live nav-tab-' aria-expanded='true'><span>Info</span></a>"
  html += "        </li>"
  html += "        <li>"
  html += "          <a data-toggle='tab' data-target='#settings#{timelapse.id}' class='nav-tab-recordings' aria-expanded='true'>Settings</i></a>"
  html += "        </li>"
  html += "      </ul>"
  html += "      <div class='clear-f'></div>"
  html += "    </div>"

  html += "    <div class='card tab-content' style='min-height:0px;'>"
  html += "      <div id='live_video#{timelapse.id}' class='live-video-timelapse tab-pane active'>"
  html += "        <div class='snapstack-loading' id='snaps-#{timelapse.id}'>"
  html += "          <video data-setup='{ \"playbackRates\": [0.06, 0.12, 0.25, 0.5, 1, 1.5, 2, 2.5, 3] }' poster='#{Evercam.API_URL}cameras/#{timelapse.camera_id}/thumbnail?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}' preload=\"none\" controls class=\"video-js vjs-default-skin video-bg-width\" id=\"video-control-#{timelapse.id}\">"
  html += "            <source type='application/x-mpegURL' src='#{Evercam.SEAWEEDFS_URL}#{timelapse.camera_id}/timelapses/#{timelapse.id}/index.m3u8'></source>"
  html += "          </video>"
  html += "        </div>"
  html += "        <input type='hidden' id='timelapse-camera-id#{timelapse.id}' value='#{timelapse.camera_id}'/>"
  html += "        <div class='hash-label snapmail-title'>#{timelapse.title}<span class='line-end'></span></div>"
  html += "        <div class='camera-time margin-top-20'><span class='spn-label'>Camera Name:</span><div class='div-snapmail-values'><a href='/v2/cameras/#{timelapse.camera_id}' target='_blank'>#{timelapse.camera_name}</a></div><div class='clear-f'></div></div>"
  html += "        <div class='camera-time'><span class='spn-label'>Created At:</span><div class='div-snapmail-values'>#{format_time.formatDate((new Date(timelapse.created_at*1000)), "d M Y, H:i:s")}</div><div class='clear-f'></div></div>"
  html += "        <div class='camera-time'><span class='spn-label'>Recording Status:</span><div class='div-snapmail-values'>#{(if timelapse.status is 'Active' then 'On' else 'Off')}</div><div class='clear-f'></div></div>"
  html += "        <div class='camera-time'><span class='spn-label'>Last Snapshot At:</span><div class='div-snapmail-values'>#{(if timelapse.snapshot_count == 0 then '---' else format_time.formatDate((new Date(timelapse.last_snapshot_at*1000)), "d M Y, H:i:s"))}</div><div class='clear-f'></div></div>"
  html += "      </div>"

  html += "      <div id='info_tab#{timelapse.id}' class='tab-pane'>"
  html += "        <div class='camera-time'><span class='spn-label'>Total Snapshots:</span><div class='div-snapmail-values'>#{(if timelapse.snapshot_count is null then 0 else timelapse.snapshot_count)}</div><div class='clear-f'></div></div>"
  html += "        <div class='camera-time'><span class='spn-label'>File Size:</span><div class='div-snapmail-values'>#{if timelapse.snapshot_count is null then "---" else getFileSize(timelapse.resolution, timelapse.snapshot_count)}</div><div class='clear-f'></div></div>"
  html += "        <div class='camera-time'><span class='spn-label'>Resolution:</span><div class='div-snapmail-values'>#{(if timelapse.resolution is null then '---' else timelapse.resolution)}</div><div class='clear-f'></div></div>"
  html += "        <div class='camera-time'><span class='spn-label'>HLS URL:</span><div class='div-snapmail-values hls-url-value'>#{Evercam.SEAWEEDFS_URL}#{timelapse.camera_id}/timelapses/#{timelapse.id}/index.m3u8#{Evercam.SEAWEEDFS_URL}#{timelapse.camera_id}/timelapses/#{timelapse.id}/index.m3u8"
  html += "        </div><div class='clear-f'></div></div><div class='clear-f'></div>"
  html += "        <div class='camera-time margin-top-10'><span class='spn-label'>Embedded Code:</span><div class='div-snapmail-values hls-url-value'><textarea id='code" + timelapse.id + "' class='pre-width'>&lt;div id='hls-video'&gt;&lt;/div&gt;&nbsp"
  html += "&lt;script src='#{window.location.origin}/widgets/timelapse-widget.js' class='" + timelapse.camera_id + " " + timelapse.id + " " + timelapse.id + "'&gt;&lt;/script&gt;&nbsp"
  html += "        </textarea></div><div class='clear-f'></div></div>"
  html += "      </div>"

  html += "      <div id='settings#{timelapse.id}' class='tab-pane'>"
  html += "        <table class='table' style='margin-bottom:0px;'>"
  html += "          <tr>"
  html += "            <td class='col-sm-3'><label>Title:</label></td>"
  html += "            <td class='col-sm-9'><input type='text' id='timelapse-title#{timelapse.id}' value='#{timelapse.title}' required='required' class='form-control'/></td>"
  html += "          </tr>"
  html += "          <tr><td><label>Interval:</label></td><td><select id='timelapse-frequency#{timelapse.id}' class='form-control'>"
  html += "            <option value='0'>Select Interval</option>"
  html += "            <option #{select_frequency(timelapse.frequency, 1)} value='1'>1 Frame Every 1 min</option>"
  html += "            <option #{select_frequency(timelapse.frequency, 5)} value='5'>1 Frame Every 5 min</option>"
  html += "            <option #{select_frequency(timelapse.frequency, 15)} value='15'>1 Frame Every 15 min</option>"
  html += "            <option #{select_frequency(timelapse.frequency, 30)} value='30'>1 Frame Every 30 min</option>"
  html += "            <option #{select_frequency(timelapse.frequency, 60)} value='60'>1 Frame Every 1 hour</option>"
  html += "            <option #{select_frequency(timelapse.frequency, 360)} value='360'>1 Frame Every 6 hours</option>"
  html += "            <option #{select_frequency(timelapse.frequency, 720)} value='720'>1 Frame Every 12 hours</option></select></td>"
  html += "          </tr>"
  html += "          <tr>"
  html += "            <td><label>Date Range:</label></td>"
  html += "            <td>"
  html += "              <div class='col-sm-4 radio-list padding-left0'>"
  html += "                <label class='radio-inline'>"
  html += "                  <input id='chkDateRangeAlways' name='date_range_edit#{timelapse.id}' data-val='#{timelapse.id}' type='radio' #{select_date_time_range(timelapse.date_always, true)} value='true' class='icheck radio_edit date_range_edit'/>&nbsp;Always"
  html += "                </label>"
  html += "              </div>"
  html += "              <div class='col-sm-4 radio-list padding-left0'>"
  html += "                <label class='radio-inline'>"
  html += "                  <input id='chkDateRange' name='date_range_edit#{timelapse.id}' data-val='#{timelapse.id}' type='radio' #{select_date_time_range(timelapse.date_always, false)} value='false' class='icheck radio_edit date_range_edit'/>&nbsp;Range"
  html += "                </label>"
  html += "              </div>"
  html += "            </td>"
  html += "          </tr>"

  html += "          <tr class='range-row'>"
  html += "            <td></td>"
  html += "            <td>"
  html += "              <div id='row_date_range#{timelapse.id}' style='display: #{if timelapse.date_always then "none" else "block"};'>"
  html += "                <div class='col-sm-6 padding-left0 padding-right0 min-width-140'>"
  html += "                  <div class='col-sm-3 padding-left0 margin-top-5'><label>From:</label></div>"
  html += "                  <div class='col-sm-9 padding-left0'><input type='text' id='txt_from_date#{timelapse.id}' class='form-control daterange range-input-field' value='#{setDate(timelapse.date_always, timelapse.from_date, "d/m/Y", "")}' placeholder='From Date'></div>"
  html += "                </div>"
  html += "                <div class='col-sm-6 padding-left0 padding-right0 min-width-140'>"
  html += "                  <div class='col-sm-3 padding-left0 margin-top-5 padding-right0 width20'><label>To:</label></div>"
  html += "                  <div class='col-sm-9 padding-left0 padding-right0'><input type='text' id='txt_to_date#{timelapse.id}' class='form-control daterange range-input-field' value='#{setDate(timelapse.date_always, timelapse.to_date, "d/m/Y", "")}' placeholder='To Date'></div>"
  html += "                </div>"
  html += "              </div>"
  html += "            </td>"
  html += "          </tr>"
  html += "          <tr>"
  html += "            <td><label>Time Range:</label></td>"
  html += "            <td>"
  html += "              <div class='col-sm-4 radio-list padding-left0'>"
  html += "                <label class='radio-inline'>"
  html += "                  <input id='chkTimeRangeAlways' name='time_range_edit#{timelapse.id}' data-val='#{timelapse.id}' #{select_date_time_range(timelapse.time_always, true)} type='radio' value='true' class='icheck radio_edit time_range_edit' />&nbsp;Always"
  html += "                </label>"
  html += "              </div>"
  html += "              <div class='col-sm-4 radio-list padding-left0'>"
  html += "                <label class='radio-inline'>"
  html += "                  <input id='chkTimeRange' name='time_range_edit#{timelapse.id}' data-val='#{timelapse.id}' #{select_date_time_range(timelapse.time_always, false)} type='radio' value='false' class='icheck radio_edit time_range_edit' />&nbsp;Range"
  html += "                </label>"
  html += "              </div>"
  html += "            </td>"
  html += "          </tr>"
  html += "          <tr class='range-row'>"
  html += "            <td></td>"
  html += "            <td>"
  html += "              <div id='row_time_range#{timelapse.id}' style='display: #{if timelapse.time_always then "none" else "block"};padding-top:5px;'>"
  html += "                <div class='col-sm-6 padding-left0 padding-right0 min-width-140'>"
  html += "                  <div class='col-sm-3 padding-left0 margin-top-5'><label>From:</label></div>"
  html += "                  <div class='col-sm-9 padding-left0'><input type='text' id='txt_from_time#{timelapse.id}' class='form-control range-input-field timerange' placeholder='From Time' readonly value='#{setDate(timelapse.time_always, timelapse.from_date, "H:i", "00:00")}'></div>"
  html += "                </div>"
  html += "                <div class='col-sm-6 padding-left0 padding-right0 min-width-140'>"
  html += "                  <div class='col-sm-3 padding-left0 margin-top-5 padding-right0 width20'><label>To:</label></div>"
  html += "                  <div class='col-sm-9 padding-left0 padding-right0'><input type='text' id='txt_to_time#{timelapse.id}' class='form-control range-input-field timerange' placeholder='To Time' readonly value='#{setDate(timelapse.time_always, timelapse.to_date, "H:i", "23:59")}'></div>"
  html += "                </div>"
  html += "              </div>"
  html += "            </td>"
  html += "          </tr>"
  html += "          <tr>"
  html += "            <td><label>Watermark Pos:</label></td>"
  html += "            <td>"
  html += "              <select id='timelapse-watermark-pos#{timelapse.id}' class='form-control'>"
  html += "                <option #{select_frequency(timelapse.watermark_position, "TopLeft")} value='TopLeft'>Top Left</option>"
  html += "                <option #{select_frequency(timelapse.watermark_position, "TopRight")} value='TopRight'>Top Right</option>"
  html += "                <option #{select_frequency(timelapse.watermark_position, "BottomLeft")} value='BottomLeft'>Bottom Left</option>"
  html += "                <option #{select_frequency(timelapse.watermark_position, "BottomRight")} value='BottomRight'>Bottom Right</option>"
  html += "               </select>"
  html += "            </td>"
  html += "          </tr>"
  html += "          <tr>"
  html += "            <td><label>Watermark Logo:</label></td>"
  html += "            <td>"
  html += "              <label id='custom-fileselect#{timelapse.id}' style='display: #{(if timelapse.watermark_logo is "" then "block" else "none")};' for='timelapse-watermark#{timelapse.id}' class='custom-file-upload col-sm-4' data-val='#{timelapse.id}'><i class='fa fa-upload margin-top-9'></i> Choose File</label>"
  html += "              <input id='timelapse-watermark#{timelapse.id}' data-val='#{timelapse.id}' type='file' class='choose-logo-button form-control choose-input hide' accept='image/*'>"
  html += "              <div style='display: #{(if timelapse.watermark_logo is "" then "none" else "block")};' id='div-logo-upload#{timelapse.id}' class='col-sm-12 padding-left-0'>"
  html += "                <table class='table'><tr><td class='col-sm-3' style='padding: 0;'>"
  html += "                  <img id='img-watermark#{timelapse.id}' src='#{timelapse.watermark_logo}' style='width:70px;'>"
  html += "                  <input type='hidden' id='watermark-base64#{timelapse.id}' value='#{timelapse.watermark_logo}'>"
  html += "                </td>"
  html += "                <td style='vertical-align: middle; padding: 0; padding-left:5px;'>"
  html += "                  <button class='btn btn-default cancel-upload' data-val='#{timelapse.id}'>"
  html += "                    <i class='fa fa-ban'></i>"
  html += "                    <span>Cancel</span>"
  html += "                  </button>"
  html += "                </td></tr></table>"
  html += "              </div>"
  html += "            </td>"
  html += "          </tr>"
  html += "          <tr>"
  html += "            <td></td>"
  html += "            <td colspan='2'>"
  html += "              <button type='button' class='btn btn-primary edit-timelapse margin-top-10' data-val='#{timelapse.id}'><i class='fa fa-check'></i> Save</button>&nbsp;"
  html += "              <button type='button' class='btn btn-danger delete-timelapse margin-top-10' data-val='#{timelapse.id}'><i class='fa fa-remove'></i> Delete</button>&nbsp;"
  html += "              <button type='button' class='btn btn-green toggle-status margin-top-10' status='#{(if timelapse.status is "Paused" then "start" else "stop")}' camera-id='#{timelapse.camera_id}' data-val='#{timelapse.id}'><i class='fa #{(if timelapse.status is "Paused" then "fa-play" else "fa-pause")}'></i> #{(if timelapse.status is "Paused" then "Resume" else "Pause")}</button>"
  html += "            </td>"
  html += "          </tr>"
  html += "        </table>"
  html += "      </div>"
  html += "    </div>"

  html += "    <div style='min-height:0px;display: none;'>"
  html += "        <div class='text-right delete-timelapse'>"
  html += "             <span id='pop-#{timelapse.id}' class='popbox2'><div id='open-#{timelapse.id}' href='javascript:;' class='tools-link open2' data-val='#{timelapse.id}'><div class='icon-button red margin-24 margin-left-0'><i class='fas fa-trash-alt main-color plus-btn' title='Delete'></i><paper-ripple class='circle recenteringTouch' fit></paper-ripple></div></div>"
  html += "             <div class='collapse-popup'>"
  html += "               <div class='box-snapmail' id='box-#{timelapse.id}' style='width:288px;'>"
  html += "                   <div class='arrow2' id='arrow-#{timelapse.id}'></div>"
  html += "                   <div class='arrow-border2' id='arrow-border-#{timelapse.id}'></div>"
  html += "                   <div class='margin-bottom-10'>Are you sure?</div>"
  html += "                   <div class='margin-bottom-10'><input class='btn btn-primary delete-btn' type='button' value='Yes, Remove' camera-id='#{timelapse.camera_id}' data-val='#{timelapse.id}'/><div id='close-popup-#{timelapse.id}' class='btn closepopup2 grey' fit><div class='text-center'>Cancel</div></div></div>"
  html += "               </div>"
  html += "             </div></span>"
  html += "       </div>"
  html += "       </div>"
  html += "    </div>"
  html += "  </div>"
  html

getFileSize = (resolution, files) ->
  if resolution is null || files is 0
    return "---"
  arr = resolution.split("x")
  if parseInt(arr[0]) > 640 && parseInt(arr[0]) < 799
    return calculateSize(30720 * files)
  else if parseInt(arr[0]) > 800 && parseInt(arr[0]) < 1023
    return calculateSize(43008 * files)
  else if parseInt(arr[0]) > 1024 && parseInt(arr[0]) < 1199
    return calculateSize(56320 * files)
  else if parseInt(arr[0]) > 1200 && parseInt(arr[0]) < 1599
    return calculateSize(63488 * files)
  else if parseInt(arr[0]) > 1600 && parseInt(arr[0]) < 1899
    return calculateSize(81920 * files)
  else
    return calculateSize(104448 * files)

calculateSize = (size) ->
  if size < 1024 * 1024
    return "#{(size / 1024).toFixed(2)}Kb"
  if size < 1024 * 1024 * 1024
    return "#{(size / (1024 * 1024)).toFixed(2)} Mb";
  if size > 1024 * 1024 * 1024
    gbs = size / (1024 * 1024 * 1024)
    if gbs > 1024
      tbs = gbs / 1024
      return "#{tbs.toFixed(2)}Tb"
    return "#{gbs.toFixed(2)}Gb"
  return "#{size.toFixed(2)}B";

select_frequency = (frequency, option) ->
  if frequency is option
    "selected"
  else
    ""

select_date_time_range = (is_always, option) ->
  if is_always is option
    "checked"
  else
    ""

setDate = (is_always, datetime, format, default_val) ->
  if is_always
    default_val
  else
    return format_time.formatDate((new Date(datetime*1000)), "#{format}")

saveTimelapse = ->
  $('#save-timelapse').on 'click', ->
    save_button = $(this)
    $(".bb-alert").removeClass("alert-info").addClass("alert-danger")

    if $("#timelapse-camera").val() is ''
      Notification.error("Please select camera to continue.")
      return false

    if $("#timelapse-title").val() is ''
      Notification.error("Please enter timelapse title.")
      return false

    if $("#timelapse-frequency").val() is "0"
      Notification.error("Please select timelapse interval.")
      return false

    d = new Date()
    fromDate = "#{(d.getMonth()+1)}/#{d.getDate()}/#{d.getFullYear()}"
    toDate = fromDate
    fromTime = "00:00"
    toTime = fromTime
    dateAlways = $('input[name=date_range]:checked').val()
    timeAlways = $('input[name=time_range]:checked').val()
    if dateAlways is "false"
      fromDate = change_date_format($("#txt_from_date").val())
      if fromDate is ""
        Notification.error("Please select from date range.")
        return false
      toDate = change_date_format($("#txt_to_date").val())
      if toDate is ""
        Notification.error("Please select to date range.")
        return false

    if timeAlways is "false"
      fromTime = $("#txt_from_time").val()
      if fromTime is ""
        Notification.error("Please select from time range.")
        return false

      toTime = $("#txt_to_time").val()
      if toTime is ""
        Notification.error("Please select to time range.")
        return false

      if fromTime is toTime
        Notification.error('To time and from time cannot be same.')
        return false

    img = document.getElementById("#{$("#timelapse-camera").val()}")

    o =
      title: $("#timelapse-title").val()
      date_always: dateAlways
      time_always: timeAlways
      frequency: $("#timelapse-frequency").val()
      from_datetime: (new Date("#{fromDate} #{fromTime}"))/1000
      to_datetime: (new Date("#{toDate} #{toTime}"))/1000
      watermark_position: $("#timelapse-watermark-pos").val()
      resolution: "#{img.naturalWidth}x#{img.naturalHeight}"

    o.watermark_logo = $("#watermark-base64").val() unless $("#watermark-base64").val() is ""

    save_button.attr 'disabled', true

    onError = (jqXHR, status, error) ->
      response = JSON.parse(jqXHR.responseText)
      if jQuery.type(response.message) is "object"
        Notification.error "#{response["message"]}"
      else
        Notification.error "#{response.message}"
      save_button.removeAttr('disabled')

    onSuccess = (result, status, jqXHR) ->
      timelapse = result.timelapses[0]
      $(".bb-alert").removeClass("alert-danger").addClass("alert-info")
      save_button.removeAttr('disabled')
      $('#divTimelapses').prepend getTimelapseHtml(timelapse, 0)
      initPlugins(timelapse)
      $("#timelapse-form").modal("hide")
      clearForm()

    settings =
      data: o
      dataType: 'json'
      error: onError
      success: onSuccess
      type: "POST"
      url: "#{Evercam.API_URL}cameras/#{$("#timelapse-camera").val()}/timelapses?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"

    $.ajax(settings)

deleteTimelapse = ->
  $('#divTimelapses').on 'click', '.delete-timelapse', ->
    timelapse_id = $(this).attr("data-val")
    camera_id = $("#timelapse-camera-id#{timelapse_id}").val()
    onError = (jqXHR, status, error) ->
      if jqXHR.status is 403
        Notification.error "You don't have sufficient permission."
      else
        response = JSON.parse(jqXHR.responseText)
        Notification.error "#{response.message}"

    onSuccess = (result, status, jqXHR) ->
      $(".bb-alert").removeClass("alert-danger").addClass("alert-info")
      Notification.info('Timelapse deleted successfully.')
      player = videojs_array["#{timelapse_id}"]
      player.dispose()
      $("#dataslot#{timelapse_id}").remove()

    settings =
      data: {}
      dataType: 'json'
      error: onError
      success: onSuccess
      type: "DELETE"
      url: "#{Evercam.API_URL}cameras/#{camera_id}/timelapses/#{timelapse_id}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"

    $.ajax(settings)

editTimelapse = ->
  $('#divTimelapses').on 'click', '.edit-timelapse', ->
    save_button = $(this)
    timelapse_id = $(this).attr("data-val")
    $(".bb-alert").removeClass("alert-info").addClass("alert-danger")

    if $("#timelapse-title#{timelapse_id}").val() is ''
      Notification.error("Please enter timelapse title.")
      return false

    if $("#timelapse-frequency#{timelapse_id}").val() is "0"
      Notification.error("Please select timelapse interval.")
      return false

    d = new Date()
    fromDate = "#{(d.getMonth()+1)}/#{d.getDate()}/#{d.getFullYear()}"
    toDate = fromDate
    fromTime = "00:00"
    toTime = fromTime
    dateAlways = $("input[name=date_range_edit#{timelapse_id}]:checked").val()
    timeAlways = $("input[name=time_range_edit#{timelapse_id}]:checked").val()
    if dateAlways is "false"
      fromDate = change_date_format($("#txt_from_date#{timelapse_id}").val())
      if fromDate is ""
        Notification.error("Please select from date range.")
        return false
      toDate = change_date_format($("#txt_to_date#{timelapse_id}").val())
      if toDate is ""
        Notification.error("Please select to date range.")
        return false

    if timeAlways is "false"
      fromTime = $("#txt_from_time#{timelapse_id}").val()
      if fromTime is ""
        Notification.error("Please select from time range.")
        return false

      toTime = $("#txt_to_time#{timelapse_id}").val()
      if toTime is ""
        Notification.error("Please select to time range.")
        return false

      if fromTime is toTime
        Notification.error('To time and from time cannot be same.')
        return false

    watermark_logo = ""
    if $("#watermark-base64#{timelapse_id}").val() isnt ""
      watermark_logo = $("#watermark-base64#{timelapse_id}").val()

    o =
      title: $("#timelapse-title#{timelapse_id}").val()
      date_always: dateAlways
      time_always: timeAlways
      frequency: $("#timelapse-frequency#{timelapse_id}").val()
      from_datetime: (new Date("#{fromDate} #{fromTime}"))/1000
      to_datetime: (new Date("#{toDate} #{toTime}"))/1000
      watermark_position: $("#timelapse-watermark-pos#{timelapse_id}").val()
      watermark_logo: $("#watermark-base64#{timelapse_id}").val()

    save_button.attr 'disabled', true

    onError = (jqXHR, status, error) ->
      if jqXHR.status is 500
        Notification.error "500 Internal Server Error"
      else
        response = JSON.parse(jqXHR.responseText)
        Notification.error "#{response.message}"
      save_button.removeAttr('disabled')

    onSuccess = (result, status, jqXHR) ->
      snapMail = result.timelapses[0]
      $(".bb-alert").removeClass("alert-danger").addClass("alert-info")
      Notification.info('Timelapse updated.')
      save_button.removeAttr('disabled')

    settings =
      data: o
      dataType: 'json'
      error: onError
      success: onSuccess
      type: "PATCH"
      url: "#{Evercam.API_URL}cameras/#{$("#timelapse-camera-id#{timelapse_id}").val()}/timelapses/#{timelapse_id}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"

    $.ajax(settings)

toggleStatus = ->
  $('#divTimelapses').on 'click', '.toggle-status', ->
    control = $(this)
    timelapse_id = $(this).attr("data-val")
    camera_id = $(this).attr("camera-id")
    if $(this).attr("status") is 'stop'
      timelapse_status = 3
    else
      timelapse_status = 0

    onError = (jqXHR, status, error) ->
      if jqXHR.status is 403
        Notification.error "You don't have sufficient permission."
      else
        response = JSON.parse(jqXHR.responseText)
        Notification.error "#{response.message}"


    onSuccess = (result, status, jqXHR) ->
      # snapMail = result.timelapses[0]
      $(".bb-alert").removeClass("alert-danger").addClass("alert-info")
      if timelapse_status is 3
        control.attr('status', 'start')
        control.html("<i class='fa fa-play'></i> Resume")
      else
        control.attr('status', 'stop')
        control.html("<i class='fa fa-pause'></i> Pause")

    settings =
      data: {status: timelapse_status}
      dataType: 'json'
      error: onError
      success: onSuccess
      type: "PATCH"
      url: "#{Evercam.API_URL}cameras/#{camera_id}/timelapses/#{timelapse_id}?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"

    $.ajax(settings)

clearForm = ->
  camera_select.val("").trigger("change")
  $("#txt_timelapse_id").val("")
  $("#timelapse-title").val("")
  $("#timelapse-frequency").val("0")
  $("#txt_from_date").val("")
  $("#txt_to_date").val("")
  $("#txt_from_time").val("00:00")
  $("#txt_to_time").val("23:59")
  $('#chkDateRangeAlways').iCheck('check')
  $("#row_date_range").slideUp()
  $('#chkTimeRangeAlways').iCheck('check')
  $("#row_time_range").slideUp()
  $("#timelapse-watermark").val()
  $('#timelapse-form .caption').html 'New Timelapse'

change_date_format = (date) ->
  if date isnt ""
    dates_array = date.split("/")
    "#{dates_array[1]}/#{dates_array[0]}/#{dates_array[2]}"
  else
    ""

show_hide_datetime = ->
  $('[name="date_range"]').on 'ifClicked', ->
    id = $(this).attr('id')
    if $(this).val() is "false"
      $("#row_date_range").slideDown()
    else
      $("#row_date_range").slideUp()

  $('#divTimelapses').on 'ifClicked', '.date_range_edit', ->
    id = $(this).attr('id')
    timelapse_id = $(this).attr("data-val")
    if $(this).val() is "false"
      $("#row_date_range#{timelapse_id}").slideDown()
    else
      $("#row_date_range#{timelapse_id}").slideUp()

  $('[name="time_range"]').on 'ifClicked', ->
    id = $(this).attr('id')
    if $(this).val() is "false"
      $("#row_time_range").slideDown()
    else
      $("#row_time_range").slideUp()

  $('#divTimelapses').on 'ifClicked', '.time_range_edit', ->
    id = $(this).attr('id')
    timelapse_id = $(this).attr("data-val")
    if $(this).val() is "false"
      $("#row_time_range#{timelapse_id}").slideDown()
    else
      $("#row_time_range#{timelapse_id}").slideUp()

initTimepicker = (control) ->
  $("#{control}").timepicker
    timeFormat: 'h:i'
    minuteStep: 1
    showSeconds: false
    showMeridian: false

handleModelEvents = ->
  $("#timelapse-form").on "hide.bs.modal", ->
    clearForm()

initSelect2 = ->
  camera_select = $('#timelapse-camera').select2
    placeholder: 'Select Camera',
    allowClear: true,
    templateSelection: format,
    templateResult: format

format = (state) ->
  if !state.id
    return state.text
  if state.id == '0'
    return state.text
  if state.element
    if state.element.attributes[1].value is "false"
      camera_status = "<i class='red main-sidebar fa fa-unlink'></i>"
    else
      camera_status = ""
    return $("<span><img id='#{state.id}' style='width: 25px;height: auto;' src='#{state.element.attributes[2].value}' class='gravatar1'/>&nbsp;#{state.text}#{camera_status}</span>")
  else
    state.text

initControls = ->
  $("input[type=radio]").iCheck
    radioClass: "iradio_flat-blue"
  $('.daterange').datetimepicker({timepicker: false, format: 'd/m/Y'})
  format_time = new DateFormatter()

readFile = ->
  timelapse_id = $(this).attr("data-val")
  if @files and @files[0]
    FR = new FileReader
    FR.addEventListener 'load', (e) ->
      $("#img-watermark#{timelapse_id}").attr("src", e.target.result)
      $("#watermark-base64#{timelapse_id}").val(e.target.result)
      $("#div-logo-upload#{timelapse_id}").slideDown()
    FR.readAsDataURL @files[0]
  else
    $("#img-watermark#{timelapse_id}").attr("src", "")
    $("#watermark-base64#{timelapse_id}").val("")
    $("#div-logo-upload#{timelapse_id}").slideUp()

cancelUpload = ->
  $("#tab_timelapse").on "click", ".cancel-upload", ->
    timelapse_id = $(this).attr("data-val")
    $("#timelapse-watermark#{timelapse_id}").val("")
    $("#img-watermark#{timelapse_id}").attr("src", "")
    $("#watermark-base64#{timelapse_id}").val("")
    $("#div-logo-upload#{timelapse_id}").slideUp()
    $("#custom-fileselect#{timelapse_id}").slideDown()
    $("#custom-fileselect").slideDown()

toggleWatermarkLogo = ->
  $(".choose-logo-button").change ->
    time_lapse = $(this).attr("data-val")
    if time_lapse is ''
      $("#custom-fileselect#{time_lapse}").slideDown()
    else
      $("#custom-fileselect#{time_lapse}").slideUp()

toggleDialogueWatermarkLogo = ->
  $(".dialogue-logo-button").change ->
    $("#custom-fileselect").slideUp()

window.initializeTimelapse = ->
  loadTimelapses()
  show_hide_datetime()
  initTimepicker(".timerange")
  handleModelEvents()
  saveTimelapse()
  editTimelapse()
  toggleStatus()
  deleteTimelapse()
  initNotification()
  initSelect2()
  initControls()
  cancelUpload()
  document.getElementById('timelapse-watermark').addEventListener 'change', readFile
  toggleWatermarkLogo()
  toggleDialogueWatermarkLogo()
