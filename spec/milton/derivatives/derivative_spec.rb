require File.dirname(__FILE__) + '/../../spec_helper'

module Citrusbyte
  module Milton
    describe Derivative do
      describe "building the filename from options" do
        before :each do
          @file = Storage::DiskFile.new('milton.jpg', :id => 1, :storage_options => { :root => output_path }, :separator => '.')
        end

        describe "options as hash" do
          it "should coalesce size into filename" do
            File.basename(Derivative.new(@file, :size => '40x40').path).should eql('milton.size=40x40.jpg')
          end

          it "should coalesce crop into filename" do
            File.basename(Derivative.new(@file, :size => '40x40', :crop => true).path).should eql('milton.crop=true_size=40x40.jpg')
          end

          it "should coalesce gravity into filename" do
            File.basename(Derivative.new(@file, :size => '40x40', :gravity => 'north').path).should eql('milton.gravity=north_size=40x40.jpg')
          end

          it "should coalese all options together" do
            File.basename(Derivative.new(@file, :size => '40x40', :gravity => 'north', :crop => true).path).should eql('milton.crop=true_gravity=north_size=40x40.jpg')
          end
        end
    
        describe "options as string" do
          it "should parse size" do
            File.basename(Derivative.new(@file, 'size=40x40').path).should eql('milton.size=40x40.jpg')
          end

          it "should parse crop" do
            File.basename(Derivative.new(@file, 'size=40x40_crop=true').path).should eql('milton.crop=true_size=40x40.jpg')
          end

          it "should parse gravity" do
            File.basename(Derivative.new(@file, 'size=40x40_gravity=north').path).should eql('milton.gravity=north_size=40x40.jpg')
          end

          it "should parse them all together" do
            File.basename(Derivative.new(@file, 'size=40x40_crop=true_gravity=north').path).should eql('milton.crop=true_gravity=north_size=40x40.jpg')
          end
        end
      end
    end
  end
end