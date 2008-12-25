require File.dirname(__FILE__) + '/../spec_helper'

describe Attachment do
  describe "being destroyed" do
    before :each do
      @attachment = Attachment.create :file => upload('milton.jpg')
      @derivative_path = File.dirname(@attachment.path) + '/milton'
    end

    it "should delete the underlying file from the filesystem" do
      @attachment.destroy
      File.exists?(@attachment.path).should be_false
    end
    
    it "should have a derivative path before being destroyed" do
      File.exists?(@derivative_path).should be_true
    end
    
    it "should delete the derivative folder from the filesystem" do
      @attachment.destroy
      File.exists?(@derivative_path).should be_false
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
end
