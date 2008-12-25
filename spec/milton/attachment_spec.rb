require File.dirname(__FILE__) + '/../spec_helper'

describe Attachment do
  describe "determining file type on create" do
    it "should assign the file type if the extension matches and content_type is undefined" do
      foo = FileType.create! :name => 'Foo'
      foo.file_type_rules.create! :extension => 'foo'
      Asset.create(:file => upload('file.foo', 'application/foo')).file_type.should eql(foo)
    end
    
    it "should not assign the file type if the extension matches and content_type doesn't" do
      foo = FileType.create! :name => 'Foo'
      foo.file_type_rules.create! :extension => 'foo', :content_type => 'image/jpg'
      Asset.create(:file => upload('file.foo', 'application/foo')).file_type.should_not eql(foo)
    end
    
    it "should assign the file type if the content_type matches and the extension is undefined" do
      foo = FileType.create! :name => 'Foo'
      foo.file_type_rules.create! :content_type => 'application/foo'
      Asset.create(:file => upload('file.foo', 'application/foo')).file_type.should eql(foo)
    end

    it "should not assign the file type if the content_type matches and the extension doesn't" do
      foo = FileType.create! :name => 'Foo'
      foo.file_type_rules.create! :extension => 'bar', :content_type => 'application/foo'
      Asset.create(:file => upload('file.foo', 'application/foo')).file_type.should_not eql(foo)
    end

    it "should assign the file type if both the content_type and extension match" do
      foo = FileType.create! :name => 'Foo' 
      foo.file_type_rules.create! :extension => 'foo', :content_type => 'application/foo'
      Asset.create(:file => upload('file.foo', 'application/foo')).file_type.should eql(foo)
    end
  end
  
  describe "destroying" do
    before :each do
    end

    it "should delete the underlying file from the filesystem" do
    end
    
    it "should delete the derivative folder from the filesystem" do
    end
  end  
end
