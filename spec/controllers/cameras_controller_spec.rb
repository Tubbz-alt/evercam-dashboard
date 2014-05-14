require 'spec_helper'

describe CamerasController do
  let!(:user) {
    create(:active_user)
  }

  let!(:camera) {
    create(:private_camera)
  }

  let(:params) {
    {'camera-id' => camera.exid,
     'camera-name' => 'My Cam',
     'camera-url' => '1.1.1.1',
     'snapshot' => '/jpg',
     'camera-username' => '',
     'camera-password' => '',
     'camera-vendor' => '',
     'camera-model' => '',
     'local-http' => '',
     'port' => '',
     'ext-rtsp-port' => '',
     'local-rtsp' => '',
     'local-ip' => ''}
  }

  let(:patch_params) {
    {'camera-id' => camera.exid,
     'id' => camera.exid,
     'camera-name' => 'My New Cam',
     'camera-url' => '1.1.1.2',
     'snapshot' => '/jpeg',
     'camera-username' => '',
     'camera-password' => '',
     'camera-vendor' => '',
     'local-http' => '',
     'ext-rtsp-port' => '',
     'port' => '',
     'local-rtsp' => '',
     'local-ip' => ''}
  }

  describe 'GET #index without auth' do
    it "redirects to signup" do
      get :index
      expect(response).to redirect_to('/signin')
    end
  end

  describe 'GET #new without auth' do
    it "redirects to signup" do
      get :new
      expect(response).to redirect_to('/signin')
    end
  end

  describe 'POST #new without auth' do
    it "redirects to signup" do
      post :new
      expect(response).to redirect_to('/signin')
    end
  end

  context 'with auth' do
    describe 'GET #index' do
      it "renders the :index" do
        stub_request(:get, "#{EVERCAM_API}users/#{user.username}/cameras?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(status: 200, headers: {},
                    body: "{\"cameras\": []}")

        stub_request(:get, "#{EVERCAM_API}shares/user/#{user.username}?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => "{}", :headers => {})

        session['user'] = user.email
        get :index
        expect(response.status).to eq(200)
        expect(response).to render_template :index
      end
    end

    describe 'GET #new' do
      it "renders the :new" do
        session['user'] = user.email
        get :new
        expect(response.status).to eq(200)
        expect(response).to render_template :new
      end
    end

    describe 'POST #create with valid parameters' do
      it "redirects to the newly created camera" do
        stub_request(:post, "#{EVERCAM_API}cameras").
          to_return(:status => 200, :body => "", :headers => {})

        session['user'] = user.email
        post :create, params
        expect(response.status).to eq(302)
        expect(response).to redirect_to("/cameras/#{params['camera-id']}")
      end
    end

    let!(:model) {
      create(:vendor_model)
    }

    let(:full_params) {
      {'camera-id' => camera.exid,
       'camera-name' => 'My Cam',
       'camera-url' => '1.1.1.1',
       'snapshot' => '/jpg',
       'camera-username' => 'aaa',
       'camera-password' => 'xxx',
       'camera-vendor' => model.vendor.exid,
       "camera-model#{model.vendor.exid}" => model.name,
       'local-http' => '111',
       'ext-rtsp-port' => '333',
       'port' => '8888',
       'local-rtsp' => '222',
       'local-ip' => '127.0.1.1'}
    }

    describe 'POST #create with valid full parameters' do
      it "redirects to the newly created camera" do
        stub_request(:post, "#{EVERCAM_API}cameras").
          to_return(:status => 200, :body => "", :headers => {})

        session['user'] = user.email
        post :create, full_params
        expect(response.status).to eq(302)
        expect(response).to redirect_to("/cameras/#{params['camera-id']}")
      end
    end

    describe 'POST #create with missing parameters' do
      it "renders new camera form" do
        session['user'] = user.email
        post :create, {}
        expect(response.status).to eq(200)
        expect(response).to render_template :new
      end
    end

    describe 'POST #update with valid parameters' do
      it "redirects to the updated camera" do
        stub_request(:patch, "#{EVERCAM_API}cameras/#{camera.exid}").
          to_return(:status => 200, :body => "", :headers => {})

        session['user'] = user.email
        post :update, patch_params
        expect(response.status).to eq(302)
        expect(response).to redirect_to "/cameras/#{camera.exid}#camera-settings"
        expect(flash[:message]).to eq('Settings updated successfully')
      end
    end

    describe 'POST #update with missing parameters' do
      it "renders camera settings form" do
        stub_request(:patch, "#{EVERCAM_API}cameras/#{camera.exid}").
          to_return(status: 400, headers: {},
                    body: "{\"message\": [\"name can't be blank\", \"jpg url can't be blank\", \"external host can't be blank\"]}")
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}?api_id=#{user.api_id}&api_key=#{user.api_key}").
         to_return(:status => 200, :body => "{\"cameras\": [{}]}", :headers => {})

        stub_request(:get, "#{EVERCAM_API}users/#{user.username}/cameras?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => '{"cameras": []}', :headers => {})

        session['user'] = user.email
        post :update, {'id' => camera.exid, 'camera-id' => camera.exid}
        expect(response.status).to eq(200)
        expect(response).to render_template :single
        expect(flash[:message]).to eq(["name can't be blank", "jpg url can't be blank", "external host can't be blank"])
      end
    end


    describe 'GET #single' do
      it "renders the :single" do
        stub_request(:get, "#{EVERCAM_API}cameras/#{params['camera-id']}?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(status: 200, headers: {}, body: "{\"cameras\": [{}]}")
        stub_request(:get, "#{EVERCAM_API}shares/camera/#{params['camera-id']}?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => "{\"shares\": []}", :headers => {})
        stub_request(:get, "#{EVERCAM_API}users/#{user.username}/cameras?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => '{"cameras": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}shares/requests/?api_id=#{user.api_id}&api_key=#{user.api_key}").
          with(:body => "status=PENDING").
          to_return(:status => 200, :body => '{"share_requests": []}', :headers => {})

        session['user'] = user.email
        get :single, {'id' => params['camera-id']}
        expect(response.status).to eq(200)
        expect(response).to render_template :single
      end
    end

    describe 'POST #delete with valid parameters' do
      it "deletes the camera redirects to index" do
        stub_request(:delete, "#{EVERCAM_API}cameras/#{camera.exid}").
          to_return(:status => 200, :body => "", :headers => {})

        session['user'] = user.email
        post :delete, {'id' => params['camera-id']}
        expect(response.status).to eq(302)
        expect(response).to redirect_to "/"
        expect(flash[:message]).to eq('Camera deleted successfully.')
      end
    end


    describe 'POST #delete with invalid parameters' do
      it "rerenders single camera page" do
        stub_request(:delete, "#{EVERCAM_API}cameras/#{camera.exid}").
          to_return(:status => 500, :body => '{"message": "failed"}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(status: 200, headers: {},
                    body: "{\"cameras\": [{}]}")
        session['user'] = user.email
        post :delete, {'id' => params['camera-id']}
        expect(response.status).to eq(302)
        expect(response.location).to eq("http://test.host/cameras/#{camera.exid}")
        expect(flash[:message]).to eq('failed')
      end
    end

  end
end
