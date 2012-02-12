require 'curb'
require 'yajl'

class CopyWorker < IronWorker::Base
  attr_accessor :user, :services, :photo_id, :client_env

  merge_gem "multi_json"
  merge_gem "oauth"
  merge_gem "oauth2"
  merge_gem "faraday_middleware"
  merge_gem "flickr_oauth"
  merge_gem "dropbox-api"
  unmerge_gem 'yajl-ruby'

  merge "../lib/service.rb"
  merge_folder "../lib/service/"
  merge "../lib/meetup.rb"

  def run
    @client_env.each{|k,v| ENV[k] = v}

    Dropbox::API::Config.app_key    = ENV['DROPBOX_KEY']
    Dropbox::API::Config.app_secret = ENV['DROPBOX_SECRET']
    Dropbox::API::Config.mode       = "sandbox"

    clients = @services.map{|svc| Service.get(svc, @user)}
    mup = Meetup.new(ENV['MEETUP_KEY'], ENV['MEETUP_SECRET'], @user['credentials'])
    photo = mup.get('/2/photos', photo_id: @photo_id)["results"].first
    curb = Curl::Easy.new

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
end