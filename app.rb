require 'rubygems'
require 'bundler'

Bundler.require

require './lib/meetup'
require './lib/service'

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
    provider :flickr, ENV['FLICKR_KEY'], ENV['FLICKR_SECRET'], scope: 'write'
    provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'], scope: 'user_photos,publish_stream', display: 'page'
  end

  register Sinatra::CssSupport
  serve_css '/stylesheets', from: "./app/css"
  register Sinatra::JsSupport
  serve_js '/js', from: "./app/js"

  register Sinatra::Flash

  configure do |m|
    m.set :scss, {
      :load_paths => [ File.join(File.dirname(__FILE__), 'app/css') ]
    }
    m.set :scss, self.scss.merge(:style => :compressed) if m.production?
  end

  couch = CouchRest.new(ENV['CLOUDANT_URL'])
  DB = couch.database('users')
  DB.create!

  ALL_SERVICES = ["flickr", "facebook"]

  helpers do
    def stylesheet(sheet)
      fn = sheet.to_s + ".css"
      "<link href=\"/stylesheets/#{fn}?#{css_mtime_for("app/css/#{fn}")}\" type=\"text/css\" rel=\"stylesheet\" />"
    end

    def script(js)
      fn = js.to_s + ".js"
      "<script src=\"/js/#{fn}?#{File.mtime("app/js/#{fn}").to_i}\"></script>"
    end

    def english_join(list)
      case list.length
        when 0
          ""
        when 1
          list.first
        when 2
          "#{list.first} and #{list.last}"
        else
          list[0..-2].join(", ") + ", and #{list.last}"
      end
    end
  end

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
    if @user
      @services = @user["services"] || {}
      @missing_services = ALL_SERVICES - @services.keys
    end
  end

  get '/' do
    set_user
    if @user
      data = make_client.get('/2/photos', member_id: 'self')
      @photos = data["results"]
    end
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

  # other services just copy the credentials into the db
  get '/auth/:service/callback' do
    set_user
    auth = request.env['omniauth.auth']
    # pp auth
    @user["services"] ||= {}
    @user["services"][params[:service]] = auth.credentials
    DB.save_doc(@user)

    redirect to('/')
  end

  post '/photos' do
    set_user
    if params[:services].nil? || params[:services].empty?
      flash[:message] = "Can't upload! You must select at least one service to upload to."
    elsif params[:photo].nil? || params[:photo].empty?
      flash[:message] = "Can't upload! You must select at least one photo."
    else
      clients = params[:services].keys.map{|svc| Service.get(svc, @user)}
      mup = make_client
      photos = mup.get('/2/photos', photo_id: params[:photo].keys.join(','))["results"]
      curb = Curl::Easy.new
      photos.each do |photo|
        file = Tempfile.new(['mup-photo', File.extname(photo["highres_link"])])
        begin
          curb.url = photo["highres_link"]
          curb.on_body do |data|
            file.write(data)
          end
          curb.perform
          file.close
          clients.each {|cli| cli.upload(file.path, photo["caption"])}
        ensure
          file.close!
        end
      end
      flash[:message] = "Your photos have been uploaded!"
    end
    redirect to('/')
  end

  private
  def make_client
    Meetup.new(ENV['MEETUP_KEY'], ENV['MEETUP_SECRET'], @user['credentials'])
  end
end