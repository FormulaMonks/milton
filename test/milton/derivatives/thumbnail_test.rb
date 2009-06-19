require File.dirname(__FILE__) + '/../../test_helper'
require 'milton/derivatives/thumbnail'

module Milton
  class ThumbnailTest < ActiveSupport::TestCase
    @@options ||= { 
      :storage_options => { :root => output_path, :chmod => 0755 }, 
      :separator       => '.', 
      :tempfile_path   => File.join(Rails.root, 'tmp', 'milton')
    }
    
    context "building the filename from options" do
      setup do
        @file = Storage::DiskFile.new('milton.jpg', 1, @@options)
      end
      
      should "raise unless a size is given" do
        assert_raise RuntimeError do
          Thumbnail.process(@file, { :crop => true }, @@options)
        end
      end
    end
    
    # milton.jpg is 320x300
    context "resizing" do
      setup do
        @source = Storage::DiskFile.create('milton.jpg', 1, File.join(fixture_path, 'milton.jpg'), @@options)
      end

      context "and checking errors" do
        should "raise a MissingFileError if source cannot be recognized as an image" do
          File.open(@source.path, 'w') { |io| io.puts 'foo' }
          assert_raise Milton::MissingFileError do
            Thumbnail.process(@source, { :size => '50x50' }, @@options)
          end
        end
      
        should "raise if no size is specified" do
          assert_raise RuntimeError do
            Thumbnail.process(@source, { :crop => true }, @@options)
          end
        end        
      end

      # 300/320   = 0.9375
      # 50*0.9375 = 47
      context "without cropping" do
        setup do
          @thumbnail = Thumbnail.process(@source, { :size => '50x50' }, @@options)
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
          @thumbnail = Thumbnail.process(@source, { :size => '50x50', :crop => true }, @@options)
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
    end
    
    context "resizing large images" do
      setup do
        @source = Storage::DiskFile.create('big-milton.jpg', 1, File.join(fixture_path, 'big-milton.jpg'), @@options)
        @thumbnail = Thumbnail.process(@source, { :crop => true, :size => '40x40' }, @@options)
      end

      pending_test "generate a 640px wide version when image is wider than 640px wide and generating an image smaller than 640px wide" do
        assert File.exists?(@thumbnail.path.gsub(/\.crop=true_size=40x40/, '.size=640x'))
      end

      pending_test "generate images smaller than 640px wide from the existing 640px one" do
        # TODO: how can i test this?
        # @thumbnail.path(:crop => true, :size => '40x40')
      end
    end
    
    context "using S3" do
      setup do
        @source = Storage::S3File.create('milton.jpg', 1, File.join(fixture_path, 'milton.jpg'), @@options.merge(:storage_options => {
          :access_key_id => '123', :secret_access_key => 'abc', :bucket => 'milton'
        }))
        @thumbnail = Thumbnail.process(@source, { :size => '50x50' }, @@options)
      end
      
      should "generate thumbnail" do
        assert S3File.exists?(@thumbnail.path)
      end
    end
  end
end