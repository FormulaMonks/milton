Extended Usage Examples
-----------------------

### Basic User Avatar

    class User < ActiveRecord::Base
      has_one :avatar, :dependent => :destroy
    end
  
    class Avatar < ActiveRecord::Base
      is_image
      belongs_to :user
    end
    
Allow user to upload an avatar when creating

    class UsersController < ActiveRecord::Base
      def create
        @user = User.new params[:user]
        @user.avatar = Avatar.new(params[:avatar]) if params[:avatar] && params[:avatar][:file]
        
        if @user.save
          ...
        else
          ...
        end
        
        ...
      end
    end
    
Allow user to upload a new avatar, note that we don't care about updating files
in this has_one case, we're just gonna set a new relationship (which will
destroy the existing one)

    class AvatarsController < ActiveRecord::Base
      def create
        @user = User.find params[:user_id]

        # setting a has_one on a saved object saves the new related object
        if @user.avatar = Avatar.new(params[:avatar])
          ...
        else
          ...
        end
        
        ...
      end
    end
    
User's profile snippet (in Haml)
    
    #profile
      = image_tag(@user.avatar.public_path(:size => '100x100', :crop => true))
      = @user.name
