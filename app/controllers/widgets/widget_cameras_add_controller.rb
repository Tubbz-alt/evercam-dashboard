class Widgets::WidgetCamerasAddController < ApplicationController
  before_action :authenticate_user!
  before_action :allow_iframe, only: [:add_public_camera]
  after_action :allow_iframe, only: [:add_public_camera]
  before_action :allow_iframe, only: [:add_public_camera]
  skip_before_action :verify_authenticity_token, only: [:add_camera]
  skip_before_action :authenticate_user!, only: [:add_public_camera, :add_camera]

  include SessionsHelper
  include ApplicationHelper

  def WidgetCamerasAdd
    current_user
  end

  def widget_add_camera
    @cameras = load_user_cameras(true, false)
  end

  def add_public_camera
    render :layout => false
  end

  def add_camera
    respond_to do |format|
      format.js { render :file => "widgets/widget_cameras_add/add.camera.js.erb", :mime_type => Mime::Type.lookup('text/javascript')}
    end
  end

end
