require File.dirname(__FILE__) + '/../../test_helper'


module Citrusbyte::Milton
  class DerivativeTest < ActiveSupport::TestCase
    @@options ||= { :storage_options => { :root => output_path }, :separator => '.' }
    @@file ||= Citrusbyte::Milton::Storage::DiskFile.new('milton.jpg', 1, @@options)
        
    context "building the filename from options" do
      context "options as hash" do
        should "coalesce size into filename" do
          assert_equal 'milton.size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40' }, @@options).path)
        end

        should "coalesce crop into filename" do
          assert_equal 'milton.crop=true_size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40', :crop => true }, @@options).path)
        end

        should "coalesce gravity into filename" do
          assert_equal 'milton.gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40', :gravity => 'north' }, @@options).path)
        end

        should "coalese all options together" do
          assert_equal 'milton.crop=true_gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, { :size => '40x40', :gravity => 'north', :crop => true }, @@options).path)
        end
      end

      context "options as string" do
        should "parse size" do
          assert_equal 'milton.size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40', @@options).path)
        end

        should "parse crop" do
          assert_equal 'milton.crop=true_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_crop=true', @@options).path)
        end

        should "parse gravity" do
          assert_equal 'milton.gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_gravity=north', @@options).path)
        end

        should "parse them all together" do
          assert_equal 'milton.crop=true_gravity=north_size=40x40.jpg', File.basename(Derivative.new(@@file, 'size=40x40_crop=true_gravity=north', @@options).path)
        end
      end
    end
  end
end