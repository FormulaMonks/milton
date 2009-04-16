require File.dirname(__FILE__) + '/../../spec_helper'

module Citrusbyte
  module Milton
    describe Thumbnail do
      describe "building the filename from options" do
        before :each do
          @file = Storage::DiskFile.new('milton.jpg', :file_system_path => output_path, :separator => '.')
        end

        it "should raise unless a size is given" do
          lambda {
            File.basename(Thumbnail.new(@file, :crop => true))
          }.should raise_error
        end
      end
    end
  end
end
