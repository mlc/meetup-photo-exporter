require 'sinatra'
require 'haml'
require 'sass'
require 'omniauth'
require 'omniauth-meetup'
require 'pp'
require 'couchrest'

set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, "views"
set :public_folder, 'static'

use Rack::Session::Cookie, :session => ENV['SESSION_SECRET']
use OmniAuth::Builder do
  provider :meetup, ENV['MEETUP_KEY'], ENV['MEETUP_SECRET']
end

couch = CouchRest.new(ENV['CLOUDANT_URL'])
DB = couch.database('users')
DB.create!

def skip_session
  request.session_options[:skip] = true
end

before do
  @user_id = session[:user_id]
  unless @user_id.nil?
    @user = DB.get(@user_id) rescue nil
  end
end

get '/stylesheets/:name.css' do
  skip_session
  response['Cache-Control'] = 'public, max-age=7200'
  content_type 'text/css', :charset => 'utf-8'
  scss :"stylesheets/#{params[:name]}", :layout => false, :style => :compact
end

get '/' do
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