require File.dirname(__FILE__) + '/../spec_helper'

describe Citrusbyte::Milton::IsUploadable do
  class NotUploadable < ActiveRecord::Base
  end
  
  class NoTable < ActiveRecord::Base
  end
  
  describe "filename column" do
    it 'should not raise an exception if there is a filename column' do
      lambda { Attachment.class_eval("is_uploadable") }.should_not raise_error
    end

    it "should raise an exception if there is no filename column" do
      lambda { NotUploadable.class_eval("is_uploadable") }.should raise_error
    end
    
    it 'should not raise an exception if the underlying table doesn\'t exist' do
      lambda { NoTable.class_eval('is_uploadable') }.should_not raise_error
    end
  end
  
  describe "setting :file_system_path" do
    it "should allow options to be accessed" do
      Attachment.milton_options.should be_kind_of(Hash)
    end
    
    it "should be able to overwrite file_system_path from is_uploadable call" do
      Attachment.class_eval("is_uploadable(:file_system_path => 'foo')")
      Attachment.milton_options[:file_system_path].should eql('foo')
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
    describe "saving upload" do
      before :each do
        @attachment = Attachment.new :file => upload('milton.jpg')
      end
      
      it "should save the upload to the filesystem on save" do
        @attachment.save
        File.exists?(@attachment.path).should be_true
      end
      
      it "should have the same filesize as original file when large enough not to be a StringIO" do
        # FIXME: this doesn't actually upload as a StringIO, figure out how to
        # force that
        @attachment.save
        File.size(@attachment.path).should be_eql(File.size(File.join(File.dirname(__FILE__), '..', 'fixtures', 'milton.jpg')))
      end
      
      it "should have the same filesize as original file when small enough to be a StringIO" do
        File.size(Attachment.create(:file => upload('mini-milton.jpg')).path).should be_eql(File.size(File.join(File.dirname(__FILE__), '..', 'fixtures', 'mini-milton.jpg')))
      end
    end
    
    describe "stored full filename" do
      before :each do
        @attachment = Attachment.create! :file => upload('milton.jpg')
      end

      it "should use set file_system_path" do
        @attachment.path.should =~ /^#{@attachment.milton_options[:file_system_path]}.*$/
      end
      
      it "should use uploaded filename" do
        @attachment.path.should =~ /^.*#{@attachment.filename}$/
      end
    end
    
    describe "sanitizing filename" do
      before :each do
        @attachment = Attachment.create! :file => upload('unsanitary .milton.jpg')
      end
      
      it "should strip the space and . and replace them with -" do
        @attachment.path.should =~ /^.*\/unsanitary--milton.jpg$/
      end
      
      it "should exist with sanitized filename" do
        File.exists?(@attachment.path).should be_true
      end
    end
    
    describe "saving attachment after upload" do
      before :each do
        @attachment = Attachment.create! :file => upload('unsanitary .milton.jpg')
      end
      
      it "should save the file again" do
        lambda {
          Attachment.find(@attachment.id).save!
        }.should_not raise_error
      end
    end
  end
end