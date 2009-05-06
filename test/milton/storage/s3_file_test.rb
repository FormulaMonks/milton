require File.dirname(__FILE__) + '/../../test_helper'
require 'right_aws'
require 'milton/storage/s3_file'

module Citrusbyte
  module Milton
    class S3FileTest < ActiveSupport::TestCase
      setup do
        @key    = flexmock(RightAws::S3::Key,
          :exists? => true,
          :delete  => true
        )
        @bucket = flexmock(RightAws::S3::Bucket,
          :put => true,
          :key => @key
        )
        @file   = Storage::S3File.new('milton.jpg', 1, :storage_options => {
          :bucket      => 'milton',
          :permissions => 'private',
          :protocol    => 'https'
        })
    
        flexmock(@file).should_receive(:bucket).and_return(@bucket)
      end
  
      context "storing a file" do
        pending_test "store the file with the given permissions" do
        end
    
        pending_test "store the file using the given protocol" do
        end
    
        pending_test "combine the id and filename as the pathname of the file" do
        end
      end
  
      context "retrieving a stored file" do
        pending_test "retrive the file in the given bucket w/ id and filename" do
        end
      end
  
      context "destroying a file" do
        pending_test "delete the file w/ id and filename" do
        end
      end
    end
  end
end