class Service::Facebook
  def initialize(user)
    @credentials = user
  end

  def upload(photo, caption)
    c = Curl::Easy.new('https://graph.facebook.com/me/photos?access_token=' + @credentials["token"])
    c.multipart_form_post = true
    # c.on_body {|data| $stderr.write(data) }
    c.http_post(Curl::PostField.file('source', photo),
        Curl::PostField.content('name', caption || "Photo Copied from Meetup")
    )
  end
end