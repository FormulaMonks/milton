require File.dirname(__FILE__) + '/../spec_helper'

describe Attachment do
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
