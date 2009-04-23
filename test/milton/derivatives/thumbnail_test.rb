require File.dirname(__FILE__) + '/../../test_helper'

module Citrusbyte::Milton
  class ThumbnailTest < ActiveSupport::TestCase
    @@options = { 
      :storage_options => { :root => output_path, :chmod => 0755 }, 
      :separator       => '.', 
      :tempfile_path   => File.join(Rails.root, 'tmp', 'milton'),
      :postprocessing  => true
    }
    
    context "building the filename from options" do
      setup do
        @file = Storage::DiskFile.new('milton.jpg', 1, @@options)
      end
      
      should "raise unless a size is given" do
        assert_raise RuntimeError do
          Thumbnail.new(@file, :crop => true).path
        end
      end
    end
    
    # milton.jpg is 320x300
    context "resizing" do
      context "when postproccesing is on" do
        setup do
          @source = Storage::DiskFile.create('milton.jpg', 1, File.join(fixture_path, 'milton.jpg'), @@options)
        end

        context "and checking errors" do
          should "raise a MissingFileError if source file does not exist" do
            @source.destroy
            assert_raise Citrusbyte::Milton::MissingFileError do
              Thumbnail.new(@source, :size => '50x50').path
            end
          end
        
          should "raise if no size is specified" do
            assert_raise RuntimeError do
              Thumbnail.new(@source, :crop => true).path
            end
          end
        end
      
        # 300/320   = 0.9375
        # 50*0.9375 = 47
        context "without cropping" do
          setup do
            @thumbnail = Thumbnail.new(@source, :size => '50x50')
            @info = Image.from_path(@thumbnail.path)
          end

          should "create a resized copy of the image" do
            assert File.exists?(@thumbnail.path)
          end
          
          should "have width of 47px" do
            assert_equal 47, @info.width
          end
          
          should "have height of 50px" do
            assert_equal 50, @info.height
          end
        end    

        context "with cropping" do
          setup do
            @thumbnail = Thumbnail.new(@source, :size => '50x50', :crop => true)
            @info = Image.from_path(@thumbnail.path)
          end

          should "create a resized and cropped copy of the image" do
            assert File.exists?(@thumbnail.path)
          end
    
          should "have width of 50px" do
            assert_equal 50, @info.width
          end
    
          should "have height of 50px" do
            assert_equal 50, @info.height
          end
        end
            
        context "with named sizes" do
          setup do
            @thumbnail = Thumbnail.new(@source, :name => :small, :size => '50x50')
          end
        
          should "create a resized copy of the image" do
            assert File.exists?(@thumbnail.path)
          end
        
          should "use name as filename of image" do
            assert_equal 'milton.small.jpg', @thumbnail.filename
          end
        end
      end
      
      context "when postprocessing is off" do
        setup do
          @source = Storage::DiskFile.create('milton.jpg', 2, File.join(fixture_path, 'milton.jpg'), @@options.merge(:postprocessing => false))
          @thumbnail = Thumbnail.new(@source, :size => '50x50')
        end

        should "not create a resized copy of the image" do
          assert !File.exists?(@thumbnail.path)
        end
      end
    end
    
    context "resizing large images" do
      setup do
        @source = Storage::DiskFile.create('big-milton.jpg', 1, File.join(fixture_path, 'big-milton.jpg'), @@options)
        @thumbnail = Thumbnail.new(@source, :crop => true, :size => '40x40')
      end

      should "generate a 640px wide version when image is wider than 640px wide and generating an image smaller than 640px wide" do
        assert File.exists?(@thumbnail.path.gsub(/\.crop=true_size=40x40/, '.size=640x'))
      end

      should "generate images smaller than 640px wide from the existing 640px one" do
        # TODO: how can i test this?
        # @thumbnail.path(:crop => true, :size => '40x40')
      end
    end
  end
end