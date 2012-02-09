require 'sinatra'
require 'haml'
require 'sass'
require 'omniauth'
require 'omniauth-meetup'
require 'pp'

set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, "views"
set :public_folder, 'static'

use Rack::Session::Cookie, :session => ENV['SESSION_SECRET']
use OmniAuth::Builder do
  provider :meetup, ENV['MEETUP_KEY'], ENV['MEETUP_SECRET']
end

def skip_session
  request.session_options[:skip] = true
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

get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  content_type 'text/plain', :charset => 'utf-8'
  pp(auth)
end