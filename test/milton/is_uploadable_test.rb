require File.dirname(__FILE__) + '/../test_helper'

class Citrusbyte::Milton::IsUploadableTest < ActiveSupport::TestCase
  class NotUploadable < ActiveRecord::Base
  end
  
  class NoTable < ActiveRecord::Base
  end
    
  context "filename column" do
    should "not raise an exception if there is a filename column" do
      assert_nothing_raised do
        Attachment.class_eval("is_uploadable")
      end
    end

    should "raise an exception if there is no filename column" do
      assert_raise RuntimeError do
        NotUploadable.class_eval("is_uploadable")
      end
    end
    
    should "not raise an exception if the underlying table doesn't exist" do
      assert_nothing_raised do
        NoTable.class_eval('is_uploadable')
      end
    end
  end
  
  context "setting options" do
    should "allow options to be accessed" do
      assert Attachment.milton_options.is_a?(Hash)
    end
    
    context "defaults" do
      should "use :disk as default storage" do
      assert_equal :disk, Attachment.milton_options[:storage]
      end
    end
    
    context "overwriting" do
      should "be able to overwrite options from is_uploadable call" do
        Attachment.class_eval("is_uploadable(:storage => :foo)")
      assert_equal :foo, Attachment.milton_options[:storage]
      end
      
      teardown do
        Attachment.class_eval("is_uploadable :storage => :disk")
      end
    end
  end
  
  context "class extensions" do
    context "class methods" do
      should "add before_file_saved callback" do
        assert Attachment.respond_to?(:before_file_saved)
      end
      
      should "add after_file_saved callback" do
        assert Attachment.respond_to?(:after_file_saved)
      end
    end
  end
    
  context "handling file upload" do
    context "saving upload" do
      setup do
        @attachment = Attachment.new :file => upload('milton.jpg')
      end
      
      should "save the upload to the filesystem on save" do
        @attachment.save
        assert File.exists?(@attachment.path)
      end
      
      should "have the same filesize as original file when large enough not to be a StringIO" do
        # FIXME: this doesn't actually upload as a StringIO, figure out how to
        # force that
        @attachment.save
        assert_equal File.size(File.join(File.dirname(__FILE__), '..', 'fixtures', 'milton.jpg')), File.size(@attachment.path)
      end
      
      should "have the same filesize as original file when small enough to be a StringIO" do
        assert_equal File.size(File.join(File.dirname(__FILE__), '..', 'fixtures', 'mini-milton.jpg')), File.size(Attachment.create(:file => upload('mini-milton.jpg')).path)
      end
    end
    
    context "stored full filename" do
      setup do
        @attachment = Attachment.create! :file => upload('milton.jpg')
      end

      should "use set root" do
        assert_match /^#{@attachment.milton_options[:storage_options][:root]}.*$/, @attachment.path
      end
      
      should "use uploaded filename" do
        assert_match /^.*#{@attachment.filename}$/, @attachment.path
      end
    end
    
    context "sanitizing filename" do
      setup do
        @attachment = Attachment.create! :file => upload('unsanitary .milton.jpg')
      end
      
      should "strip the space and . and replace them with -" do
        assert_match /^.*\/unsanitary--milton.jpg$/, @attachment.path
      end
      
      should "exist with sanitized filename" do
        assert File.exists?(@attachment.path)
      end
    end
    
    context "saving attachment after upload" do
      setup do
        @attachment = Attachment.create! :file => upload('unsanitary .milton.jpg')
      end
      
      should "save the file again" do
        assert_nothing_raised do
          Attachment.find(@attachment.id).save!
        end
      end
    end
  end
end