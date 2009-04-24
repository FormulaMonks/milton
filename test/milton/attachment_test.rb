require File.dirname(__FILE__) + '/../test_helper'

class AttachmentTest < ActiveSupport::TestCase
  context "setting options" do
    class FooRootImage < Image
      is_image :storage_options => { :root => '/foo' }
    end
    
    class BarRootImage < Image
      is_image :storage_options => { :root => '/bar' }
    end
    
    should "not overwrite FooRootImage's root setting with BarRootImage's" do
      assert_equal '/foo', FooRootImage.milton_options[:storage_options][:root]
    end

    should "not overwrite BarRootImage's root setting with FooRootImage's" do
      assert_equal '/bar', BarRootImage.milton_options[:storage_options][:root]
    end
  end
  
  context "inheriting options" do
    class FooImage < Image
      is_image :resizeable => { :sizes => { :foo => { :size => '10x10' } } }
    end
    
    class BarImage < FooImage
      is_image :resizeable => { :sizes => { } }
    end
    
    should "inherit settings from Image" do
      assert_equal Image.milton_options[:storage_options][:root], FooImage.milton_options[:storage_options][:root]
    end
    
    should "overwrite settings from Image when redefined in FooImage" do
      assert_equal({ :foo => { :size => '10x10' } }, FooImage.milton_options[:resizeable][:sizes])
    end
    
    should "overwrite settings from FooImage when redefined in BarImage" do
      assert_equal({}, BarImage.milton_options[:resizeable][:sizes])
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
