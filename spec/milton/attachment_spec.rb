require File.dirname(__FILE__) + '/../spec_helper'

describe Attachment do
  describe "setting options" do
    before :each do
      Attachment.class_eval("is_uploadable :file_system_path => 'foo'")
      Image.class_eval("is_uploadable :file_system_path => 'bar'")
    end
    
    it "should not overwrite Attachment's file_system_path setting with Image's" do
      Attachment.milton_options[:file_system_path].should eql('foo')
    end

    it "should not overwrite Image's file_system_path setting with Attachment's" do
      Image.milton_options[:file_system_path].should eql('bar')
    end
  end
  
  describe "creating attachment folder" do
    before :all do
      @output_path = File.join(File.dirname(__FILE__), '..', 'output')
      raise "Failed to create #{File.join(@output_path, 'exists')}" unless FileUtils.mkdir_p(File.join(@output_path, 'exists'))
      FileUtils.ln_s 'exists', File.join(@output_path, 'linked')
      raise "Failed to symlink #{File.join(@output_path, 'linked')}" unless File.symlink?(File.join(@output_path, 'linked'))
    end
    
    it "should create root path when root path does not exist" do    
      Attachment.class_eval("is_uploadable :file_system_path => '#{File.join(@output_path, 'nonexistant')}'")
      @attachment = Attachment.create :file => upload('milton.jpg')
      
      File.exists?(@attachment.path).should be_true
      File.exists?(File.join(@output_path, 'nonexistant')).should be_true
      @attachment.path.should =~ /nonexistant/
    end
    
    it "should work when root path already exists" do
      Attachment.class_eval("is_uploadable :file_system_path => '#{File.join(@output_path, 'exists')}'")
      @attachment = Attachment.create :file => upload('milton.jpg')
      
      File.exists?(@attachment.path).should be_true
      @attachment.path.should =~ /exists/
    end
    
    it "should work when root path is a symlink" do
      Attachment.class_eval("is_uploadable :file_system_path => '#{File.join(@output_path, 'linked')}'")
      @attachment = Attachment.create :file => upload('milton.jpg')
      
      File.exists?(@attachment.path).should be_true
      @attachment.path.should =~ /linked/
    end
    
    after :all do
      Attachment.class_eval("is_uploadable :file_system_path => '#{@output_path}'")
    end
  end
  
  describe "being destroyed" do
    before :each do
      @attachment = Attachment.create :file => upload('milton.jpg')
    end

    it "should delete the underlying file from the filesystem" do
      @attachment.destroy
      File.exists?(@attachment.path).should be_false
    end
    
    # the partitioning algorithm ensures that each attachment model has its own
    # folder, so we can safely delete the folder, if you write a new
    # partitioner this might change!
    it "should delete the directory containing the file and all derivatives from the filesystem" do
      @attachment.destroy
      File.exists?(File.dirname(@attachment.path)).should be_false
    end
  end
  
  describe "instantiating" do
    before :each do
      @image = Image.new :file => upload('milton.jpg')
    end
  
    it "should have a file= method" do
      @image.should respond_to(:file=)
    end
  
    it "should set the filename from the uploaded file" do
      @image.filename.should eql('milton.jpg')
    end
    
    it "should strip seperator (.) from the filename and replace them with replacement (-)" do
      @image.filename = 'foo.bar.baz.jpg'
      @image.filename.should eql('foo-bar-baz.jpg')
    end
  end
  
  describe "path partitioning" do
    before :each do
      @image = Image.new :file => upload('milton.jpg')
    end
    
    it "should be stored in a partitioned folder based on its id" do
      @image.path.should =~ /^.*\/#{Citrusbyte::Milton::AttachableFile.partition(@image.id)}\/#{@image.filename}$/
    end
  end
  
  describe "public path helper" do
    before :each do
      @image = Image.new :file => upload('milton.jpg')
    end
    
    it "should give the path from public/ on to the filename" do
      @image.stub!(:path).and_return('/root/public/assets/1/milton.jpg')
      @image.public_path.should eql("/assets/1/milton.jpg")
    end
    
    it "should give the path from foo/ on to the filename" do
      @image.stub!(:path).and_return('/root/foo/assets/1/milton.jpg')
      @image.public_path({}, 'foo').should eql("/assets/1/milton.jpg")
    end
  end
end
