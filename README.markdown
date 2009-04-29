Milton
======

Milton is an upload and attachment handling plugin for Rails. It is built for
extensibility and has support for resizing images and Amazon S3 built in.

Description
-----------

Milton is an upload handling plugin for Rails. The main goals of Milton are:

* Extensibility: by allowing easy addition of processors for various types of
uploads and extra storage options.
* Flexibility: by assuming as little as possible about what
types of things you'll be uploading.
* Simplicity: by trying to keep the code base small and avoiding reflection, 
mixins, and reopening classes as much as possible.

Getting Started
---------------

You can get started with Milton with the default settings by simply calling
`is_attachment` in your Asset model (or Attachment model, or whatever else 
you want to call it) and then setting the file attribute on your model to the
uploaded file.

### Example

Your `Asset` model:

    class Asset < ActiveRecord::Base
      is_uploadable
    end

**Note:** your underlying table (in this case `assets`) must have a string column called `filename`.

Your new `Asset` form:

    - form_for Asset.new, :html => { :enctype => 'multipart/form-data' } do |f|
      = f.file_field :file
      = f.submit 'Upload'

Your `AssetsController`:

    class AssetsController < ApplicationController
      def create
        @asset = Asset.create params[:asset]
      end
    end

Resizing Images
---------------

Milton creates resized versions of images on demand, as opposed to 
attachment_fu and Paperclip which create the resized versions when the
source file is uploaded. The resized versions are created with a consistent
filename and saved to the file system, so they will only be created the first
time they are asked for.

Currently Milton relies on ImageMagick (but not RMagick!). Once you
have ImageMagick installed, just add `is_resizeable` to your model in
order to allow for image manipulation.

    class Image < ActiveRecord::Base
      is_uploadable
      is_resizeable
    end
    
**Note:** there is also a helper `is_image` which can be used to specify both
`is_uploadable` and `is_resizeable`

    class Image < ActiveRecord::Base
      is_image
    end

Once your model has `is_resizeable` you can pass an options hash to the
`#path` method to define how you want your resized version. The path to
the resized version will be returned (and if no version has been created
w/ the given options it will be created).

### Example

    @image.path => .../000/000/000/001/milton.jpg

    @image.path(:size => '50x50') => .../000/000/000/001/milton.size_50x50.jpg

    @image.path(:size => '50x50', :crop => true) => .../000/000/000/001/milton.size-50x50_crop-true.jpg

### Resizing Options

**Note:** currently the only options supported are `:size` and `:crop`.

`:size` takes a geometry string similar to other image-manipulation
plugins (based off ImageMagick's geometry strings).

`:size => '50x50'` will resize the larger dimension down to 50px and maintain aspect ratio (you 
can use `:crop` for forced zoom/cropping).

`:size => '50x'` will resize the width to 50px and maintain aspect ratio.

`:size => 'x50'` will resize the height to 50px and maintain aspect ratio.

Then you can throw in `:crop` to get zoom/cropping functionality:

    @image.path(:size => '50x50', :crop => true)
    
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

    @asset.public_path(:size => '50x50') => '/assets/000/000/001/234/milton.jpg'

As opposed to:

    @asset.path(:size => '50x50') => '/var/www/site/public/assets/000/000/001/234/milton.jpg'

**Note:** if you use the `:file_system_path` option to upload your files to
somewhere outside of your `public` folder this will no longer work. You can
pass a different folder to `public_path` to use as an alternate base.

    @asset.public_path(:size => '50x50', 'uploads')

Options
-------
A few options can be passed to the `is_uploadable`/`is_resizeable` calls in your models.

<dl>
  <dt><code>:separator</code> (default <code>'.'</code>)</dt>
  <dd>is the character used to separate the options from the filename in cached derivative files (i.e. resized images). It will be stripped from the filename of any incoming file.</dd>

  <dt><code>:replacement</code> (default <code>'-'</code>)</dt>
  <dd>is the character used to replace <code>:separator</code> after stripping it from the incoming filename.</dd>

  <dt><code>:file_system_path</code> (default <code>&lt;RAILS_ROOT&gt;/public/&lt;table name&gt;</code>)</dt>
  <dd>is the root path to where files are/will be stored on your file system. The partitioned portion of the path is then added onto this root to generate the full path. You can do some useful stuff with this like pulling your assets out of /public if you want them to be non-web-accessible.</dd>

  <dt><code>:chmod</code> (default <code>0755</code>)</dt>
  <dd>is the mode to set on on created folders and uploaded files.</dd>

  <dt><code>:tempfile_path</code> (default <code>&lt;RAILS_ROOT&gt;/tmp/milton</code>)</dt>
  <dd>is the path used for Milton's temporary storage (will be created if it doesn't already exist).</dd>
</dl>

**Note:** If you're using Capistrano for deployment remember to put `:file_system_path` path in `shared` and link it up on deploy so you don't lose your uploads between deployments!

### Example

    is_uplodable :chmod => 700, :file_system_path => File.join(Rails.root, 'uploads')

Installation
------------

### Gem

    $ gem install citrusbyte-milton --source http://gems.github.com

###  Ruby on Rails gem plugin:

Add to your environment.rb:

    config.gem "citrusbyte-milton", :source => "http://gems.github.com", :lib => "milton"

Then run:
    
    $ rake gems:install

### Ruby on Rails plugin

    script/plugin install git://github.com/citrusbyte/milton.git

You will also need to install ImageMagick to use image resizing.

Dependencies
------------

* ActiveRecord
* Ruby on Rails (for now?)
* A filesystem (hopefully this one is covered...)

For image manipulation (not required!)

* ImageMagick (more processors coming soon)

More
----

* [Extended Usage Examples](USAGE.markdown)
* [Extending Milton](EXTENDING.markdown)

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
