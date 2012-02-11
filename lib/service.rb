module Service
  module ClassMethods
    def get(svc, user)
      const_get(svc.to_s.capitalize).new(user["services"][svc])
    end
  end

  extend ClassMethods
end

require File.join(File.dirname(__FILE__), 'service/flickr')
require File.join(File.dirname(__FILE__), 'service/facebook')
require File.join(File.dirname(__FILE__), 'service/dropbox')