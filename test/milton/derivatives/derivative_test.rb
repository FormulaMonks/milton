require File.dirname(__FILE__) + '/../../test_helper'


module Citrusbyte::Milton
  class DerivativeTest < ActiveSupport::TestCase
    @@file ||= Citrusbyte::Milton::Storage::DiskFile.new('milton.jpg', 1, :storage_options => { :root => output_path }, :separator => '.')
        
    context "building the filename from options" do
      context "options as hash" do
        should "coalesce size into filename" do
          assert_equal 'milton.size=40x40.jpg', File.basename(Derivative.new(@@file, :size => '40x40').path)
        end

        should "coalesce crop into filename" do
          assert_equal 'milton.crop=true_size=40x40.jpg', File.basename(Derivative.new(@@file, :size => '40x40', :crop => true).path)
        end

        should "coalesce gravity into filename" do
          assert_equal 'milton.gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, :size => '40x40', :gravity => 'north').path)
        end

        should "coalese all options together" do
          assert_equal 'milton.crop=true_gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, :size => '40x40', :gravity => 'north', :crop => true).path)
        end
      end

      context "options as string" do
        should "parse size" do
          assert_equal 'milton.size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40').path)
        end

        should "parse crop" do
          assert_equal 'milton.crop=true_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_crop=true').path)
        end

        should "parse gravity" do
          assert_equal 'milton.gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_gravity=north').path)
        end

        should "parse them all together" do
          assert_equal 'milton.crop=true_gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_crop=true_gravity=north').path)
        end
      end
    end
  end
end