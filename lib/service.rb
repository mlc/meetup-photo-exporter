module Service
  module ClassMethods
    def get(svc, user)
      const_get(svc.to_s.capitalize).new(user["services"][svc])
    end
  end

  extend ClassMethods
end

begin
  require File.join(File.dirname(__FILE__), 'service/flickr')
  require File.join(File.dirname(__FILE__), 'service/facebook')
  require File.join(File.dirname(__FILE__), 'service/dropbox')
rescue LoadError # IronWorker is a bit weird
  require File.join(File.dirname(__FILE__), 'flickr')
  require File.join(File.dirname(__FILE__), 'facebook')
  require File.join(File.dirname(__FILE__), 'dropbox')
end