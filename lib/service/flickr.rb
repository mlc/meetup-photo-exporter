class Service::Flickr
  def initialize(user)
    @oauth_options = {
        token: user["token"],
        token_secret: user["secret"],
        consumer_key: ENV['FLICKR_KEY'],
        consumer_secret: ENV['FLICKR_SECRET']
    }
  end

  def upload(fn, title)
    flickr.upload(fn, {title: title}.merge(@oauth_options))
  end
end