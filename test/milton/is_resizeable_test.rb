require File.dirname(__FILE__) + '/../test_helper'

class IsResizeableTest < ActiveSupport::TestCase  
  # TODO: move to derivative_test
  context "fetching thumbnails" do
    setup do
      @image = Image.create :file => upload('milton.jpg')
    end
    
    should "use the partitioned path when grabbing the original file" do
      assert_match /\/0*#{@image.id}\/milton.jpg$/, @image.path
    end

    should "use the partitioned path when grabbing a thubmnail" do
      assert_match /\/0*#{@image.id}\/milton.crop=true_size=10x10.jpg$/, @image.path(:size => '10x10', :crop => true)
    end
  end
  
  # TODO: move to attachment_test
  context "getting mime-type" do
    setup do
      @image = Image.new :file => upload('milton.jpg')
    end
    
    context "from freshly uploaded file" do
      should "recognize it as an image/jpg" do
        assert_equal 'image/jpg', @image.content_type
      end
    end
    
    context "from existing file" do
      setup do
        @image.save
        @image.reload
      end
      
      should "recognize it as an image/jpg" do
        assert_equal 'image/jpg', @image.content_type
      end
    end
  end
  
  context "setting options" do
    class ResizeableFoo < ActiveRecord::Base
      is_resizeable :storage_options => { :root => '/foo' }, :resizeable => { :sizes => { :foo => { :size => '50x50', :crop => true } } }
    end
    
    should "have storage root set" do
      assert_equal '/foo', ResizeableFoo.milton_options[:storage_options][:root]
    end
    
    should "have sizes set" do
      assert_equal({ :foo => { :size => '50x50', :crop => true } }, ResizeableFoo.milton_options[:resizeable][:sizes])
    end
  end
  
  context "processing thumbnails" do    
    context "with sizes" do
      class ImageWithSizes < Image
        is_image :storage_options => { :root => output_path }, :resizeable => { :sizes => {
          :foo => { :size => '50x50', :crop => true },
          :bar => { :size => '10x10' },
        } }
      end
      
      setup do
        @image = ImageWithSizes.create! :file => upload('milton.jpg')
      end
      
      should "create :foo thumbnail" do
        assert File.exists?(@image.path(:name => :foo))
      end
      
      should "create :bar thumbnail" do
        assert File.exists?(@image.path(:name => :bar))
      end
    end
    
    context "without sizes" do
      setup do
        @image = Image.create! :file => upload('milton.jpg')
      end
            
      should "not create :foo thumbnail" do
        assert !File.exists?(@image.path(:name => :foo))
      end
      
      should "happily return path to non-existant :foo thumbnail" do
        assert_equal 'milton.foo.jpg', File.basename(@image.path(:name => :foo))
      end
    end
  end
end