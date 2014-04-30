require 'data_uri'

class CamerasController < ApplicationController
  before_filter :authenticate_user!
  include SessionsHelper
  include ApplicationHelper

  def index
    @cameras = []
    @shares  = []
    response  = API_call("users/#{current_user.username}/cameras", :get)
    if response.success?
      @cameras =  JSON.parse(response.body)['cameras']
      @cameras.each do |c|
        c['jpg'] = "#{EVERCAM_API}cameras/#{c['id']}/snapshot.jpg?api_id=#{current_user.api_id}&api_key=#{current_user.api_key}"
      end
      response = API_call("shares/user/#{current_user.username}", :get)
      if response.success?
        list = JSON.parse(response.body)['shares']
        if list && !list.empty?
          camera_ids = []
          list.each {|share| camera_ids << share['camera_id']}
          response = API_call("/cameras", :get, {ids: camera_ids.join(",")})
          @shares = JSON.parse(response.body)['cameras'] if response.success?
          @shares.each do |c|
            c['jpg'] = "#{EVERCAM_API}cameras/#{c['id']}/snapshot.jpg?api_id=#{current_user.api_id}&api_key=#{current_user.api_key}"
          end
        end
      else
        Rails.logger.warn "Request for user camera shares was unsuccessful."
      end
    else
      Rails.logger.warn "Request for user cameras was unsuccessful."
    end
  end

  def new
    @vendors = Vendor.all
    @models  = VendorModel.all
  end

  def jpg
    #TODO: rewrite getting latest snapshot for offline camera
  end

  def create
    response = nil
    begin
      body = {:id => params['camera-id'],
              :name => params['camera-name'],
              :is_public => false,
              :external_host => params['camera-url'],
              :jpg_url => params['snapshot']
      }
      body[:cam_username] = params['camera-username'] unless params['camera-username'].empty?
      body[:cam_password] = params['camera-password'] unless params['camera-password'].empty?
      body[:vendor] = params['camera-vendor'] unless params['camera-vendor'].empty?
      if body[:vendor]
        body[:model] = params["camera-model#{body[:vendor]}"] unless params["camera-model#{body[:vendor]}"].empty?
      end

      body[:internal_http_port] = params['local-http'] unless params['local-http'].empty?
      body[:external_http_port] = params['port'] unless params['port'].empty?
      body[:internal_host] = params['local-ip'] unless params['local-ip'].empty?
      response  = API_call('cameras', :post, body)
    rescue NoMethodError => _
    end

    if response.nil? or not response.success?
      flash[:message] = JSON.parse(response.body)['message'] unless response.nil?
      @vendors = Vendor.all
      @models  = VendorModel.all
      render :new
    elsif response.success?
      redirect_to "/cameras/#{params['camera-id']}"
    end
  end

  def update
    body = {:id => params['camera-id'],
            :name => params['camera-name'],
            :is_public => false,
            :external_host => params['camera-url'],
            :internal_host => params['local-ip'],
            :external_http_port => params['port'],
            :internal_http_port => params['local-http'],
            :external_rtsp_port => params['ext-rtsp-port'],
            :internal_rtsp_port => params['local-rtsp'],
            :jpg_url => params['snapshot'],
            :cam_username => params['camera-username'],
            :cam_password => params['camera-password'],
            :vendor => params['camera-vendor'],
            :model => params['camera-vendor'].blank? ? '' : params["camera-model#{params['camera-vendor']}"]
    }

    response  = API_call("cameras/#{params['camera-id']}", :patch, body)

    if response.success?
      flash[:message] = 'Settings updated successfully'
      redirect_to "/cameras/#{params['camera-id']}#camera-settings"
    else
      Rails.logger.info "RESPONSE BODY: '#{response.body}'"
      flash[:message] = JSON.parse(response.body)['message'] unless response.body.blank?
      response  = API_call("cameras/#{params[:id]}", :get)
      @camera =  JSON.parse(response.body)['cameras'][0]
      @camera['jpg'] = "#{EVERCAM_API}cameras/#{@camera['id']}/snapshot.jpg?api_id=#{current_user.api_id}&api_key=#{current_user.api_key}"
      @vendors = Vendor.all
      @models  = VendorModel.all
      response  = API_call("users/#{current_user.username}/cameras", :get)
      if response.success?
        @cameras =  JSON.parse(response.body)['cameras']
      else
        @cameras = []
      end
      render :single
    end
  end

  def delete
    response  = API_call("cameras/#{params['id']}", :delete, {})
    if response.success?
      flash[:message] = 'Camera deleted successfully'
      redirect_to "/"
    else
      Rails.logger.info "RESPONSE BODY: '#{response.body}'"
      flash[:message] = JSON.parse(response.body)['message'] unless response.body.blank?
      response  = API_call("cameras/#{params[:id]}", :get)
      @camera =  JSON.parse(response.body)['cameras'][0]
      @camera['jpg'] = "#{EVERCAM_API}cameras/#{@camera['id']}/snapshot.jpg?api_id=#{current_user.api_id}&api_key=#{current_user.api_key}"
      @vendors = Vendor.all
      @models = VendorModel.all
      render :single
    end
  end

  def single
    response  = API_call("cameras/#{params[:id]}", :get)
    @camera   = JSON.parse(response.body)['cameras'][0]
    @camera['jpg'] = "#{EVERCAM_API}cameras/#{@camera['id']}/snapshot.jpg?api_id=#{current_user.api_id}&api_key=#{current_user.api_key}"
    response        = API_call("shares/camera/#{params[:id]}", :get)
    @shares         = JSON.parse(response.body)['shares']
    response        = API_call("shares/requests/#{@camera['id']}", :get, status: "PENDING")
    @share_requests = JSON.parse(response.body)['share_requests']
    @vendors  = Vendor.all
    @models   = VendorModel.all
    response  = API_call("users/#{current_user.username}/cameras", :get)
    if response.success?
      @cameras =  JSON.parse(response.body)['cameras']
    else
      @cameras = []
    end
  end
end
