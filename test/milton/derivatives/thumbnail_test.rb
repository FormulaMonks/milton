require File.dirname(__FILE__) + '/../../test_helper'

module Citrusbyte::Milton
  class ThumbnailTest < ActiveSupport::TestCase
    context "building the filename from options" do
      setup do
        @file = Storage::DiskFile.new('milton.jpg', :id => 1, :storage_options => { :root => output_path }, :separator => '.')
      end

      should "raise unless a size is given" do
        assert_raise RuntimeError do
          Thumbnail.new(@file, :crop => true).path
        end
      end
    end
  end
end