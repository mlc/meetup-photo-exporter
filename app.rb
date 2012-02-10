require 'rubygems'
require 'bundler'

Bundler.require

require './lib/meetup'

class App < Sinatra::Base
  set :app_file, __FILE__
  set :root, File.dirname(__FILE__)
  set :views, "views"
  set :public_folder, 'static'

  configure :development do
    register Sinatra::Reloader
  end

  Encoding.default_external = 'utf-8'

  use Rack::Session::Cookie, :session => ENV['SESSION_SECRET']
  use OmniAuth::Builder do
    provider :meetup, ENV['MEETUP_KEY'], ENV['MEETUP_SECRET']
  end

  register Sinatra::CssSupport
  serve_css '/stylesheets', from: "./app/css"

  configure do |m|
    m.set :scss, {
      :load_paths => [ File.join(File.dirname(__FILE__), 'app/css') ]
    }
    m.set :scss, self.scss.merge(:style => :compressed) if m.production?
  end

  couch = CouchRest.new(ENV['CLOUDANT_URL'])
  DB = couch.database('users')
  DB.create!

  def skip_session
    request.session_options[:skip] = true
  end

  def set_user
    @user_id = session[:user_id]
    unless @user_id.nil?
      @user = DB.get(@user_id) rescue nil
    end
    if @user && @user["credentials"]["expires_at"] && @user["credentials"]["expires_at"] < Time.now.to_i
      mup = Meetup.new(ENV['MEETUP_KEY'], ENV['MEETUP_SECRET'])
      begin
        creds = mup.exchange_token(@user["credentials"]["refresh_token"])
        if creds["expires_in"] && !creds["expires_at"]
          creds["expires_at"] = Time.now.to_i + creds["expires_in"]
        end
        @user["credentials"] = creds
        DB.save_doc(@user)
      rescue
        @user = nil
      end
    end
  end

  get '/' do
    set_user
    if @user
      @photos = Meetup.new(ENV['MEETUP_KEY'], ENV['MEETUP_SECRET'], @user['credentials']).get('/2/photos', member_id: 'self')
    end
    $stderr.puts @photos.to_json
    haml :index, :format => :html5
  end

  # meetup auth is special; set UID etc.
  get '/auth/meetup/callback' do
    auth = request.env['omniauth.auth']
    uid = auth.uid.to_s
    session[:user_id] = uid
    user_doc = DB.get(uid) rescue { "_id" => uid }
    user_doc["credentials"] = auth.credentials
    user_doc["name"] = auth.info.name
    # $stderr.puts(user_doc.to_json)
    DB.save_doc(user_doc)

    redirect to('/')
  end

  get '/auth/:service/callback' do
    # something useful
  end
end