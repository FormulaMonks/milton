require File.dirname(__FILE__) + '/../test_helper'

class AttachmentTest < ActiveSupport::TestCase
  context "setting options" do
    setup do
      Attachment.class_eval("is_uploadable :storage_options => { :root => 'foo' }")
      Image.class_eval("is_uploadable :storage_options => { :root => 'bar' }")
    end
    
    should "not overwrite Attachment's root setting with Image's" do
      assert_equal 'foo', Attachment.milton_options[:storage_options][:root]
    end

    should "not overwrite Image's root setting with Attachment's" do
      assert_equal 'bar', Image.milton_options[:storage_options][:root]
    end
    
    teardown do
      Attachment.class_eval("is_uploadable :storage_options => { :root => '#{output_path}' }")
      Image.class_eval("is_uploadable :storage_options => { :root => '#{output_path}' }")
    end
  end
  
  context "creating attachment folder" do
    raise "Failed to create #{File.join(output_path, 'exists')}" unless FileUtils.mkdir_p(File.join(output_path, 'exists'))
    FileUtils.ln_s 'exists', File.join(output_path, 'linked')
    raise "Failed to symlink #{File.join(output_path, 'linked')}" unless File.symlink?(File.join(output_path, 'linked'))
    
    should "create root path when root path does not exist" do    
      Attachment.class_eval("is_uploadable :storage_options => { :root => '#{File.join(output_path, 'nonexistant')}' }")
      @attachment = Attachment.create :file => upload('milton.jpg')
      
      assert File.exists?(@attachment.path)
      assert File.exists?(File.join(output_path, 'nonexistant'))
      assert_match /nonexistant/, @attachment.path
    end
    
    should "work when root path already exists" do
      Attachment.class_eval("is_uploadable :storage_options => { :root => '#{File.join(output_path, 'exists')}' }")
      @attachment = Attachment.create :file => upload('milton.jpg')
      
      assert File.exists?(@attachment.path)
      assert_match /exists/, @attachment.path
    end
    
    should "work when root path is a symlink" do
      Attachment.class_eval("is_uploadable :storage_options => { :root => '#{File.join(output_path, 'linked')}' }")
      @attachment = Attachment.create :file => upload('milton.jpg')

      assert File.exists?(@attachment.path)
      assert_match /linked/, @attachment.path
    end
    
    teardown do
      Attachment.class_eval("is_uploadable :storage_options => { :root => '#{output_path}' }")
    end
  end
  
  context "being destroyed" do
    setup do
      @attachment = Attachment.create :file => upload('milton.jpg')
    end

    should "delete the underlying file from the filesystem" do
      @attachment.destroy
      assert !File.exists?(@attachment.path)
    end
    
    # the partitioning algorithm ensures that each attachment model has its own
    # folder, so we can safely delete the folder, if you write a new
    # partitioner this might change!
    should "delete the directory containing the file and all derivatives from the filesystem" do
      @attachment.destroy
      assert !File.exists?(File.dirname(@attachment.path))
    end
  end
  
  context "instantiating" do
    setup do
      @image = Image.new :file => upload('milton.jpg')
    end
  
    should "have a file= method" do
      assert @image.respond_to?(:file=)
    end
  
    should "set the filename from the uploaded file" do
      assert_equal 'milton.jpg', @image.filename
    end
    
    should "strip seperator (.) from the filename and replace them with replacement (-)" do
      @image.filename = 'foo.bar.baz.jpg'
      assert_equal 'foo-bar-baz.jpg', @image.filename
    end
  end
  
  context "path partitioning" do
    setup do
      @image = Image.new :file => upload('milton.jpg')
    end
    
    should "be stored in a partitioned folder based on its id" do
      assert_match /^.*\/0*#{@image.id}\/#{@image.filename}$/, @image.path
    end
  end
  
  context "public path helper" do
    setup do
      @image = Image.new(:file => upload('milton.jpg'))
    end
    
    should "give the path from public/ on to the filename" do
      flexmock(@image, :path => '/root/public/assets/1/milton.jpg')
      assert_equal "/assets/1/milton.jpg", @image.public_path
    end
    
    should "give the path from foo/ on to the filename" do
      flexmock(@image, :path => '/root/foo/assets/1/milton.jpg')
      assert_equal "/assets/1/milton.jpg", @image.public_path({}, 'foo')
    end
  end
end
