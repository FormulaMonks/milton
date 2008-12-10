require File.dirname(__FILE__) + '/../spec_helper'

describe Citrusbyte::Milton::IsResizeable do
  # before do
  #   @bad_columns = ['one', 'two', 'filename']
  #   @good_columns = @bad_columns.dup.push('content_type')
  #   UploadableTestModel.stub!(:column_names).and_return(@good_columns)
  # end
  # 
  # describe "content_type column" do
  #   it "should raise an exception if there is no content_type column" do
  #     UploadableTestModel.stub!(:column_names).and_return(@bad_columns)
  #     lambda {
  #       UploadableTestModel.class_eval("acts_as_resizeable")
  #     }.should raise_error
  #   end
  # 
  #   it 'should not raise an exception if there is a content_type column' do
  #     UploadableTestModel.stub!(:column_names).and_return(@good_columns)
  #     lambda {
  #       UploadableTestModel.class_eval("acts_as_resizeable")
  #     }.should_not raise_error
  #   end
  # end
  # 
  # describe "options" do
  #   before do
  #     UploadableTestModel.class_eval("acts_as_resizeable")
  #   end
  #   
  #   def options
  #     UploadableTestModel.resizeable_options
  #   end
  #   
  #   it "should allow options to be accessed in resizeable_options" do
  #     UploadableTestModel.resizeable_options.should be_kind_of(Hash)
  #   end
  #   
  #   it "should set an initial size of an empty hash" do
  #     options[:size].size.should eql(0)
  #   end
  #   
  #   it "should set the initial file path to root public then table name" do
  #     options[:file_system_path].should eql(File.join(RAILS_ROOT, "public", UploadableTestModel.table_name)[1..-1])
  #   end
  # end
  # 
  # describe "additional class methods" do
  #   it "should have a get_size_from_parameter method" do
  #     UploadableTestModel.should respond_to(:get_size_from_parameter)
  #   end
  #   
  #   it "should have get_size_from_parameter convert a fixnum to a 2 element size array" do
  #     UploadableTestModel.get_size_from_parameter(50).should eql([50, 50])
  #   end
  #   
  #   it "should have get_size_from_parameter leave an array alone" do
  #     UploadableTestModel.get_size_from_parameter([50]).should eql([50])
  #   end
  #   
  #   it "should have get_size_from_parameter convert a string to size dimensions" do
  #     UploadableTestModel.get_size_from_parameter("50x20").should eql([50, 20])
  #   end
  # end
end