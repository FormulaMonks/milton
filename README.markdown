Milton
======

Milton is an upload and attachment handling plugin for Rails. It is built for
extensibility and has support for resizing images and Amazon S3 built in.

Description
-----------

Milton is an upload handling plugin for Rails. It is meant to handle multiple
types of file uploads. It includes support for thumbnailing of image uploads,
and more processors can easily be added for handling other file types. It also
supports multiple file stores including disk storage and Amazon S3. Milton also
supports on-demand file processing for prototyping.

Getting Started
---------------

You can get started with Milton with the default settings by simply calling
`is_attachment` on your ActiveRecord model you'll be handling files with. It is
expected that your underlying table will have a `filename` (string) column. If 
you'd like you can also define `content_type` (string) and `size` (integer)
columns to have that info automatically stored as well.

### Example

An `Asset` model:

    class Asset < ActiveRecord::Base
      is_attachment
    end

Your new `Asset` form:

    - form_for Asset.new, :html => { :enctype => 'multipart/form-data' } do |f|
      = f.file_field :file
      = f.submit 'Upload'

**Note:** don't forget to add `:html => { :enctype => 'multipart/form-data' }`

Your `AssetsController`:

    class AssetsController < ApplicationController
      def create
        @asset = Asset.create params[:asset]
      end
    end

Resizing Images
---------------

Currently Milton relies on ImageMagick (but not RMagick!). Once you have 
ImageMagick installed, add the `:thumbnail` processor to your configuration
and define your processing recipes:

    class Image < ActiveRecord::Base
      is_attachment :recipes => { :thumb => [{ :thumbnail => { :size => '100x100', :crop => true } }] }
    end

    @image.path => .../000/000/000/001/milton.jpg
    @image.path(:thumb) => .../000/000/000/001/milton.crop_size-100x100.jpg

### Thumbnail Options

**Note:** currently the only options supported are `:size` and `:crop`.

`:size` takes a geometry string similar to other image-manipulation
plugins (based off ImageMagick's geometry strings).

`:size => '50x50'` will resize the larger dimension down to 50px and maintain aspect ratio (you 
can use `:crop` for forced zoom/cropping).

`:size => '50x'` will resize the width to 50px and maintain aspect ratio.

`:size => 'x50'` will resize the height to 50px and maintain aspect ratio.

Then you can throw in `:crop` to get zoom/cropping functionality:

    @image.path(:thumbnail => { :size => '50x50', :crop => true })

This will create a 50px x 50px version of the image regardless of the source
aspect-ratio. It will *not* distort the source image, rather it will resize the
image as close to fitting as possible without distorting, then crop off the
remainder.

By default `:crop` uses a North/Center gravity -- so the remainder will be
cropped from the bottom and equally from both sides.

**Note:** the `:size` option is required when resizing.

### Embedding Images

`#path` will always return the full path to the image, in your views
you probably want to refer to the "public" path -- the portion of the
path from your `/public` folder up for embedding your images. For
now there is a helper method that gets attached to your model called
`#public_path` that simply gives you the path from `public` on.

    @image.public_path => '/assets/000/000/001/234/milton.jpg'

As opposed to:

    @image.path(:thumb) => '/var/www/site/public/assets/000/000/001/234/milton.jpg'

**Note:** if you use the `:file_system_path` option to upload your files to
somewhere outside of your `public` folder this will no longer work. You can
pass a different folder to `public_path` to use as an alternate base.

    @image.public_path(:thumb, 'uploads')

Processors
----------

Processors are defined in recipes and are loaded when Milton is loaded. In the
above example we're telling Milton to load the thumbnail processor (which comes
with Milton) and then telling it to pass
`{ :size => '100x100', :crop => true }` to the thumbnail processor in order to
create a derivative called `:thumb` for all uploaded Images.

More processors can be loaded and combined into the recipe, to be run in the
order specified (hence the array syntax), i.e.:

    class Image < ActiveRecord::Base
      is_attachment :recipes => {
        :watermarked_thumb => [{ :watermark => 'Milton' }, { :thumbnail => { :size => '100x100', :crop => true } }]
      }
    end

This recipe would create a watermarked version of the originally uploaded file,
then create a 100x100, cropped thumbnail of the watermarked version.

When processors would create the same derivative they use the already created
derivative and do not recreate it, so if you had:

    class Image < ActiveRecord::Base
      is_attachment :processors => [ :thumbnail, :watermark ], :recipes => { 
        :thumb => [{ :watermark => 'Milton' }, { :thumbnail => { :size => '100x100', :crop => true } }],
        :small => [{ :watermark => 'Milton' }, { :thumbnail => { :size => '250x' } }]
      }
    end

The watermarking would only be done once and both thumbnails would be created
from the same watermarked version of the original image.

**Note:** There is no `:watermark` processor, just an example of how processors
can be combined.

Post-processing
---------------

Post-processing allows you to create derivatives by running processors on
demand instead of when the file is uploaded. This is particularly useful for
prototyping or early-on in development when processing options are changing
rapidly and you want to play with results immediately.

You can pass `:postprocessing => true` to `is_attachment` in order to turn on
post-processing of files. This is recommended only for prototyping as it works
by checking the existence of the requested derivative every time the derivative
is requested to determine if it should be processed or not. With disk storage
in development this can be quite fast, but when using S3 or in production mode
it is definitely not recommended.

Post-processing allows you to pass recipes to `path`, i.e.:

    @image.path(:thumbnail => { :size => '100x100', :crop => true })
    
If the particular derivative (size of 100x100 and cropped) doesn't exist it
will be created.

**Note:** Without post-processing turned on the call to `path` above would
still return the same path, it just wouldn't create the underlying file.

Amazon S3
---------

Milton comes with support for Amazon S3. When using S3 uploads and derivatives
are stored locally in temp files then sent to S3. To use S3 you need to pass a
few options to `is_attachment`:

    class Asset < ActiveRecord::Base
      is_attachment :storage => :s3, :storage_options => { :api_access_key => '123', :secret_access_key => '456', :bucket => 'assets' }
    end
    
Where `:api_access_key` and `:secret_access_key` are your API access key and
secret access key from your Amazon AWS account and `:bucket` is the S3 bucket
you would like your files to be stored in.

When using S3 files are stored in folders according to the associated model's
ID. So in the above example the URL to a stored file might be:

    @image.path => http://assets.amazonaws.com/1/milton.jpg

Storage Options
---------------

By default Milton uses your local disk for storing files. Additional storage
methods can be used by passing the `:storage` option to `is_attachment` (as in
the S3 example above). Milton comes included with `:s3` and `:disk` storage.

Disk Storage Options
--------------------

When using disk storage (default) the following options can be passed in
`:storage_options`:

* `:root` (default `<Rails.root>/public/<table name>`) -- is the root path to where files are/will be stored on your file system. The partitioned portion of the path is then added onto this root to generate the full path. You can do some useful stuff with this like pulling your assets out of /public if you want them to be non-web-accessible.
* `:chmod` (default `0755`) -- is the mode to set on on created folders and uploaded files.

**Note:** If you're using Capistrano for deployment with disk storage remember to put your `:root` path in `shared` and link it up on deploy so you don't lose your uploads between deployments!

General Options
---------------

* `:separator` (default `'.'`) -- is the character used to separate the options from the filename in cached derivative files (i.e. resized images). It will be stripped from the filename of any incoming file.
* `:replacement` (default `'-'`) -- is the character used to replace `:separator` after stripping it from the incoming filename.
`:tempfile_path` (default `<Rails.root>/tmp/milton`) -- is the path used for Milton's temporary storage.

Installation
------------

### Gem

    $ gem install citrusbyte-milton --source=http://gems.github.com

###  Ruby on Rails gem plugin:

Add to your environment.rb:

    config.gem "citrusbyte-milton", :lib => 'milton', :source => 'http://gems.github.com'

Then run:
    
    $ rake gems:install

### Ruby on Rails plugin

    script/plugin install git://github.com/citrusbyte/milton.git

You will also need to install ImageMagick to use image resizing.

Dependencies
------------

* Ruby on Rails w/ ActiveRecord
* A filesystem (hopefully this one is covered...)
* ImageMagick (only if using :thumbnail processor)
* mimetype-fu (not required, but if available will be used to recognized mime
  types of incoming files)
* right_aws (if using S3 storage option)

Migrating
---------

### From 0.2.4

Milton is initialized with only `is_attachment` as of 0.3.0, so 
`is_resizeable`, `is_uploadable`, etc... are no longer used.

`:postprocessing` is off by default and should only be used in development now.
Recipes should be used instead of post-processing -- see Processors above.

Extended Usage Examples
-----------------------

### Basic User Avatar

    class User < ActiveRecord::Base
      has_one :avatar, :dependent => :destroy
    end
  
    class Avatar < ActiveRecord::Base
      is_attachment :recipes => { :small => [{ :thumbnail => { :size => '100x100', :crop => true } }] }
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
in this `has_one` case, we're just gonna set a new relationship (which will
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
      = image_tag(@user.avatar.public_path(:small))
      = @user.name

Contributors
------------

* Upload and file handling based on AttachmentPow by Ari Lerner (auser)
* Cropping and thumbnailing calculations based on code by Nicolás Sanguinetti (foca)
* Damian Janowski (djanowski)
* Michel Martens (soveran)

License
-------

Copyright (c) 2009 Ben Alavi for Citrusbyte

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
