require 'sinatra'
require 'haml'
require 'sass'

set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, "views"
set :public_folder, 'static'

enable :sessions

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