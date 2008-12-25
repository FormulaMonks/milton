require File.dirname(__FILE__) + '/../spec_helper'

describe Image do
  describe "attachment_pow behavior" do    
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
      
      it "should strip SEPERATOR (.) from the filename and replace them with REPLACEMENT (-)" do
        @image.filename = 'foo.bar.baz.jpg'
        @image.filename.should eql('foo-bar-baz.jpg')
      end
    end
  end
end
