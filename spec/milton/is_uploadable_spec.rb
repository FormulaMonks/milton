require File.dirname(__FILE__) + '/../spec_helper'

describe Citrusbyte::Milton::IsUploadable do
  class NotUploadable < ActiveRecord::Base
  end
  
  describe "filename column" do
    it "should raise an exception if there is no filename column" do
      lambda { NotUploadable.class_eval("is_uploadable") }.should raise_error
    end

    it 'should not raise an exception if there is a filename column' do
      lambda { Attachment.class_eval("is_uploadable") }.should_not raise_error
    end
  end
  
  describe "setting :file_system_path" do
    it "should allow options to be accessed in uploadable_options" do
      Attachment.uploadable_options.should be_kind_of(Hash)
    end
    
    it "should set the initial file path to root public then table name" do
      Attachment.uploadable_options[:file_system_path].should eql(File.join(RAILS_ROOT, "public", Attachment.table_name)[1..-1])
    end
    
    it "should be able to overwrite file_system_path from is_uploadable call" do
      Attachment.class_eval("is_uploadable(:file_system_path => 'foo')")
      Attachment.uploadable_options[:file_system_path].should eql('foo')
    end

    it "should strip leading / from file_system_path" do
      Attachment.class_eval("is_uploadable(:file_system_path => '/foo')")
      Attachment.uploadable_options[:file_system_path].should eql('foo')
    end
  end
    
  describe "class extensions" do
    describe "class methods" do
      it "should add before_file_saved callback" do
        Attachment.should respond_to(:before_file_saved)
      end
      
      it "should add after_file_saved callback" do
        Attachment.should respond_to(:after_file_saved)
      end
    end
  end
    
  describe "handling file upload" do
    before :each do
      Attachment.is_uploadable(:file_system_path => File.join(File.dirname(__FILE__), '..', 'output'))
    end
    
    describe "saving upload" do
      before :each do
        @attachment = Attachment.new :file => upload('milton.jpg')
      end
      
      it "should save the upload to the filesystem on save" do
        @attachment.save
        File.exists?(@attachment.full_filename).should be_true
      end
    end
    
    describe "stored full filename" do
      before :each do
        @attachment = Attachment.create! :file => upload('milton.jpg')
      end

      it "should be in format root/table_name/partition/filename" do
        @attachment.full_filename.should =~ /^#{Attachment.uploadable_options[:file_system_path]}\/#{@attachment.path}\/#{@attachment.filename}$/
      end
    end
  end
end