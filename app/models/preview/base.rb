#To add a new previewer for a CfsFile (via the show action), you basically need to
#- add the appropriate content types/extensions to config/settings.yml with a new key
#- make Preview::Resolver resolve that key to a new subclass of Preview::Base
#- implement view_partial on that subclass
#- add that view partial to the cfs file views and implement any new controller actions/routes that are needed by the view
#Note that you may also want to implement functionality here that doesn't really belong in the controller, e.g. for Preview::Image
module Preview
  class Base < Object
    attr_accessor :cfs_file

    def initialize(cfs_file)
      self.cfs_file = cfs_file
    end

  end
end