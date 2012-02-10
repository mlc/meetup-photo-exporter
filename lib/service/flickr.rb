class Service::Flickr
  def initialize(user)
    @client = ::Flickr.new(
      token: user["token"],
      token_secret: user["secret"],
      consumer_key: ENV['FACEBOOK_KEY'],
      consumer_secret: ENV['FACEBOOK_SECRET'],
      format: :json
    )
  end

  def upload(fn, title)
    @client.upload(fn, title: title)
  end
end