require File.dirname(__FILE__) + '/../../test_helper'

module Milton
  class DerivativeTest < ActiveSupport::TestCase
    @@options ||= { :storage_options => { :root => output_path }, :separator => '.' }
    @@file ||= Milton::Storage::DiskFile.new('milton.jpg', 1, @@options)
    
    # TODO: move to disk_file_test
    context "path partitioning" do
      should "use the partitioned path when grabbing the original file" do
        assert_equal "#{output_path}/000/000/000/001/milton.jpg", @@file.path
      end

      should "use the partitioned path when grabbing a thubmnail" do
        assert_equal "#{output_path}/000/000/000/001/milton.foo=bar.jpg", Derivative.new(@@file, { :foo => 'bar' }, @@options).path
      end
      
      should "partition path based on id" do
        assert_equal "#{output_path}/000/123/456/789/milton.jpg", Milton::Storage::DiskFile.new('milton.jpg', 123456789, @@options).path
      end
    end
    
    context "building the filename from options" do
      context "options as hash" do
        should "coalesce size into filename" do
          assert_equal 'milton.size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40' }, @@options).path)
        end
        
        should "not output boolean false options" do
          assert_equal 'milton.jpg', File.basename(Derivative.new(@@file, { :crop => false }, @@options).path)
        end
        
        should "remove value (=true) from boolean true options" do
          assert_equal 'milton.crop.jpg', File.basename(Derivative.new(@@file, { :crop => true }, @@options).path)
        end

        should "coalesce gravity into filename" do
          assert_equal 'milton.gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40', :gravity => 'north' }, @@options).path)
        end

        should "coalesce crop into filename" do
          assert_equal 'milton.crop_size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40', :crop => true }, @@options).path)
        end

        should "coalese all options together" do
          assert_equal 'milton.crop_gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40', :gravity => 'north', :crop => true }, @@options).path)
        end
      end

      context "options as string" do
        should "parse size" do
          assert_equal 'milton.size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40', @@options).path)
        end

        should "parse boolean true option" do
          assert_equal 'milton.crop.jpg', File.basename(Derivative.new(@@file, 'crop', @@options).path)
        end

        should "parse crop before size" do
          assert_equal 'milton.crop_size=40x40.jpg', File.basename(Derivative.new(@@file, 'crop_size=40x40', @@options).path)
        end

        should "parse crop after size" do
          assert_equal 'milton.crop_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_crop', @@options).path)
        end

        should "parse gravity" do
          assert_equal 'milton.gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_gravity=north', @@options).path)
        end

        should "parse them all together" do
          assert_equal 'milton.crop=true_gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_crop=true_gravity=north', @@options).path)
        end
      end
    end
    
    context "factory" do
      should "attempt to require the processor requested by the factory if the constant is not defined" do
        assert_nothing_raised do
          Derivative.factory(:thumbnail, @@file, { :size => '40x40' }, @@options)
        end
      end
      
      should "raise MissingSourceFile error if processor could not be found" do
        assert_raise MissingSourceFile do
          Derivative.factory(:foo, @@file, { }, @@options)
        end
      end
      
      should "return derivative for given processor" do
        assert_equal 'Milton::Thumbnail', Derivative.factory(:thumbnail, @@file, { :size => '40x40' }, @@options).class.to_s
      end
    end
  end
end