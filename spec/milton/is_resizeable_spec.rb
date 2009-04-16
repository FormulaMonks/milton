require File.dirname(__FILE__) + '/../spec_helper'

describe Citrusbyte::Milton::IsResizeable do
  # milton.jpg is 320x300
  describe "resizing" do
    before :each do
      @image = Image.create :file => upload('milton.jpg')
    end
    
    it "should create a resized copy of the image" do
      File.exists?(@image.path(:size => '50x50')).should be_true
    end

    describe "checking errors" do
      it "should raise a MissingFileError if source file does not exist" do
        FileUtils.rm(@image.path)
        lambda {
          @image.path(:size => '50x50')
        }.should raise_error(Citrusbyte::Milton::MissingFileError)
      end
    end

    describe "when cropped" do
      before :each do
        @info = Citrusbyte::Milton::Image.from_path(@image.reload.path(:size => '50x50', :crop => true))
      end
      
      it "should have width of 50px" do
        @info.width.should eql(50)
      end

      it "should have height of 50px" do
        @info.height.should eql(50)
      end
    end
    
    # 300/320   = 0.9375
    # 50*0.9375 = 47
    describe "when not cropped" do
      before :each do
        @info = Citrusbyte::Milton::Image.from_path(@image.reload.path(:size => '50x50'))
      end

      it "should have width of 47px" do
        @info.width.should eql(47)
      end

      it "should have height of 50px" do
        @info.height.should eql(50)
      end
    end    
  end

  describe "smarter thumbnails" do
    before :each do
      @image = Image.create :file => upload('big-milton.jpg')
    end
    
    it "should generate 640px wide version when image is wider than 640px wide and generating an image smaller than 640px wide" do
      path = @image.path(:crop => true, :size => '40x40')
      File.exists?(path.gsub(/\.crop=true_size=40x40/, '.size=640x')).should be_true
    end
    
    it "should generate images smaller than 640px wide from the existing 640px one" do
      # TODO: how can i test this?
      @image.path(:crop => true, :size => '40x40')
    end
  end
  
  describe "fetching thumbnails" do
    before :each do
      @image = Image.create :file => upload('milton.jpg')
    end
    
    it "should use the partitioned path when grabbing the original file" do
      @image.path.should =~ /\/0*#{@image.id}\/milton.jpg$/
    end

    it "should use the partitioned path when grabbing a thubmnail" do
      @image.path(:size => '10x10', :crop => true).should =~ /\/0*#{@image.id}\/milton.crop=true_size=10x10.jpg$/
    end
  end
  
  describe "getting mime-type" do
    before :each do
      @image = Image.new :file => upload('milton.jpg')
    end
    
    describe "from freshly uploaded file" do
      it "should recognize it as an image/jpg" do
        @image.content_type.should eql('image/jpg')
      end
    end
    
    describe "from existing file" do
      before :each do
        @image.save
        @image.reload
      end
      
      it "should recognize it as an image/jpg" do
        @image.content_type.should eql('image/jpg')
      end
    end
  end
end