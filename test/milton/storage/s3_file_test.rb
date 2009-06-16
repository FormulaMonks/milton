require File.dirname(__FILE__) + '/../../test_helper'
require 'right_aws'
require 'milton/storage/s3_file'

module Milton
  class S3FileTest < ActiveSupport::TestCase
    setup do
      @file = Storage::S3File.new('milton.jpg', 1, :storage_options => {
        :bucket      => 'milton',
        :permissions => 'private',
        :protocol    => 'https'
      })  
    end

    context "storing a file" do
      should "store the file with the given permissions, using id and filename as key" do
        flexmock(@file).should_receive(:bucket).and_return(@bucket = flexmock("Fake S3 Bucket"))
        @bucket.should_receive(:put).with('1/milton.jpg', any(), any(), 'private').once.and_return(true)
        
        @file.store(fixture_file('mini-milton.jpg'))
      end
  
      should "store the file using the given protocol" do
        flexmock(RightAws::S3).should_receive(:new).once.with(any(), any(), { :protocol => 'https', :port => 443, :logger => Rails.logger }).and_return(@s3 = flexmock("Fake S3"))
        flexmock(@s3, :bucket => flexmock("Fake S3 Bucket", :put => true))
        
        @file.store(fixture_file('mini-milton.jpg'))
      end
    end

    context "retrieving a stored file" do
      should "retrive the file in the given bucket w/ id and filename" do
        assert_equal "http://milton.s3.amazonaws.com/1/milton.jpg", @file.path
      end
    end

    context "destroying a file" do
      should "delete the file w/ id and filename" do
        flexmock(@file, :bucket => @bucket = flexmock("Fake S3 Bucket"))
        flexmock(@bucket).should_receive(:key).with('1/milton.jpg').once.and_return(@key = flexmock("Fake S3 Key"))
        flexmock(@key).should_receive(:delete).once.and_return(true)
        
        @file.destroy
      end
    end
  end
end
