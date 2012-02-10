require 'pp'

class Meetup
  REQUEST_HEADERS = {'Accept-Charset' => 'utf-8,*;q=0.9'}

  def initialize(consumer_key, consumer_secret, credentials = nil)
    @consumer_key = consumer_key
    @consumer_secret = consumer_secret
    if credentials
      @token = credentials['token'] || credentials['access_token']
    end
  end

  def exchange_token(refresh_token)
    connection = Faraday.new 'http://secure.meetup.com' do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      builder.adapter Faraday.default_adapter
    end

    response = connection.post '/oauth2/access', {:client_id => @consumer_key,
                                                  :client_secret => @consumer_secret,
                                                  :grant_type => 'refresh_token',
                                                  :refresh_token => refresh_token},
        REQUEST_HEADERS

    raise "couldn't refresh token" unless response.status == 200
    response.body
  end

  def get(url, params = nil)
    client = make_client
    response = client.get(url, :params => params.merge({access_token: @token}), :headers => {"Accept-Charset" => "utf-8"})
    #pp(response)
    raise "boo. #{response.status} getting #{url}" unless (200..206).include?(response.status)
    MultiJson.decode(response.body)
  end

  private
  def make_client
    cli = OAuth2::Client.new(@consumer_key, @consumer_secret, :site => "https://api.meetup.com")
    OAuth2::AccessToken.new(cli, @token)
  end
end