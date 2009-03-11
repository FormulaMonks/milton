Milton
======

Milton is an extensible attachment handling plugin that makes few
assumptions but provides a lot of power.

Description
-----------

<img src="http://github.com/citrusbyte/milton/raw/master/spec/fixtures/milton
.jpg" style="float:left;margin-right:10px;"/>

Milton is an asset handling plugin that assumes little and is highly
extensible. Many similar plugins make assumptions about the type of
things you'll be uploading and require some hacking when you want to,
say, upload images with thumbnails as well as PDFs with previews.
Milton attempts to solve this by assuming nothing about what you'll be
uploading and giving you, at the very least, a plugin for dealing with
an underlying file-system.

You can then tack on extra functionality, like handling uploaded files
(`is_uploadable`), or resizing images (`is_resizeable`) to certain types
of assets.

Milton also has a key architectural difference from other asset plugins
that lends to its extensibility. Where other asset handlers tack tons
of methods directly onto your model, Milton only tacks on a couple
and instead has it's own underlying structure for dealing with the
actual attached file. This allows you to have a simple and small API for
extending Milton with your own functionality (think handling different
types of files, alternate file stores, alternate image processors,
etc...).

Handling uploads
----------------

Handling uploads is as simple as calling `is_uploadable` in your Asset
model (or Attachment model, or whatever else you want to call it) and
then setting the file attribute on your model to the uploaded file.

### Example

Your `Asset` model:

    class Asset < ActiveRecord::Base
      is_uploadable
    end

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

Currently Milton relies on ImageMagick (but not RMagick!). Once you
have ImageMagick installed, just add `is_resizeable` to your model in
order to allow for image manipulation. Images are resized on demand and
cached, as opposed to pre-sized on create.

Once your model has `is_resizeable` you can pass an options hash to the
`#path` method to define how you want your resized version. The path to
the resized version will be returned, and if no version has been created
w/ the given options then it will be created as well.

Note that to get a resized version, the `:size` option is required.

### Example

    @asset.path => .../000/000/000/001/milton.jpg

    @asset.path(:size => '50x50') => .../000/000/000/001/milton.size_50x50.jpg

    @asset.path(:size => '50x50', :crop => true) => .../000/000/000/001/milton.size-50x50_crop-true.jpg

### Resizing Options

Currently the only options supported are `:size` and `:crop`.

`:size` takes a geometry string similar to other image-manipulation
plugins (based off ImageMagick's geometry strings).

`:size => '50x50'` will resize the larger dimension down to 50px and
maintain aspect ratio (you can use `:crop` for forced zoom/cropping).

`:size => '50x'` will resize the width to 50px and maintain aspect
ratio.

`:size => 'x50'` will resize the height to 50px and maintain aspect
ratio.

Then you can throw in `:crop` to get zoom/cropping functionality, so:

`:size => '50x50', :crop => true` will force a 50px x 50px output,
cropping out the remains of the larger dimension. By default it uses a
North/Center gravity. That means if the source image's height is greater
than its width then the output width will be 50px and the pixels below
50px will be cropped off the height. If the source image's width is
greater than its height then the output height will be 50px and the
pixels on either side of 50px will be cropped off the width. So it tries
to crop to keep the upper-middle of the image.

### Notes

`#path` will always return the full path to the image, in your views
you probably want to refer to the "public" path -- the portion of the
path from your `/public` folder up for embedding your images. For
now there is a helper method that gets attached to your model called
`#public_path` that simply gives you the path from `/public` on. You can
use it like:

    @asset.public_path(:size => '50x50') => 'assets/000/000/001/234/milton.jpg'

As opposed to:

    @asset.path(:size => '50x50') => '/var/www/site/public/assets/000/000/001/234/milton.jpg'

Installation
------------

###  Ruby on Rails gem plugin:

Add to your environment.rb:

    config.gem "citrusbyte-milton", :source => "http://gems.github.com", :lib => "milton"

Then run `rake gems:install` to install the gem.

    $ gem sources -a http://gems.github.com (you only have to do this once)
    $ sudo gem install citrusbyte-milton


### Ruby on Rails plugin

    script/plugin install git://github.com/citrusbyte/milton.git

### Gem

    gem install citrusbyte-milton --source http://gems.github.com

You also need to install ImageMagick if you want image resizing.

Dependencies
------------

* ActiveRecord
* Ruby on Rails (for now?)
* A filesystem (more storage solutions coming soon)

For Image manipulation (not required!)

* ImageMagick (more processors coming soon)

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
