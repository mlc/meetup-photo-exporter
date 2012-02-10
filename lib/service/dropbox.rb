require 'oauth/request_proxy/curb_request'

class File
  alias_method :length, :size
end

class Service::Dropbox
  def initialize(user)
    @client = Dropbox::API::Client.new :token => user["token"], :secret => user["secret"]
  end

  def upload(file, title)
    filename = "meetup_export_#{Time.now.to_i}#{File.extname(file)}"
    File.open(file, 'rb') do |f|
      @client.upload filename, f
    end
  end
end