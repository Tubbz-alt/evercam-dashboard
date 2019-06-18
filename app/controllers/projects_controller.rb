class ProjectsController < ApplicationController
  before_action :authenticate_user!
  include SessionsHelper
  include ApplicationHelper

  def index
    @cameras = load_user_cameras(true, false)
    api = get_evercam_api
    @projects = api.get_projects()
  end
end
