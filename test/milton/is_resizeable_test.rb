require File.dirname(__FILE__) + '/../test_helper'

class IsResizeableTest < ActiveSupport::TestCase
  # milton.jpg is 320x300
  context "resizing" do
    setup do
      @image = Image.create :file => upload('milton.jpg')
    end
    
    should "create a resized copy of the image" do
      assert File.exists?(@image.path(:size => '50x50'))
    end

    context "checking errors" do
      should "raise a MissingFileError if source file does not exist" do
        @image.send(:attached_file).destroy
        assert_raise Citrusbyte::Milton::MissingFileError do
          @image.path(:size => '50x50')
        end
      end
    end

    context "when cropped" do
      setup do
        @info = Citrusbyte::Milton::Image.from_path(@image.reload.path(:size => '50x50', :crop => true))
      end
      
      should "have width of 50px" do
        assert_equal 50, @info.width
      end

      should "have height of 50px" do
        assert_equal 50, @info.height
      end
    end
    
    # 300/320   = 0.9375
    # 50*0.9375 = 47
    context "when not cropped" do
      setup do
        @info = Citrusbyte::Milton::Image.from_path(@image.reload.path(:size => '50x50'))
      end

      should "have width of 47px" do
        assert_equal 47, @info.width
      end

      should "have height of 50px" do
        assert_equal 50, @info.height
      end
    end    
  end

  context "smarter thumbnails" do
    setup do
      @image = Image.create :file => upload('big-milton.jpg')
    end
    
    should "generate 640px wide version when image is wider than 640px wide and generating an image smaller than 640px wide" do
      path = @image.path(:crop => true, :size => '40x40')
      assert File.exists?(path.gsub(/\.crop=true_size=40x40/, '.size=640x'))
    end
    
    should "generate images smaller than 640px wide from the existing 640px one" do
      # TODO: how can i test this?
      @image.path(:crop => true, :size => '40x40')
    end
  end
  
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
end