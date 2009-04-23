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
  
  # TODO: write actual is_resizeable tests...
end