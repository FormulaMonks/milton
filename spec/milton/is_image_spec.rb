require File.dirname(__FILE__) + '/../spec_helper'

describe Citrusbyte::Milton::IsImage do
  # before do
  #   @bad_columns = ['one', 'two', 'filename']
  #   @good_columns = @bad_columns.dup.push('content_type')
  #   UploadableTestModel.stub!(:column_names).and_return(@good_columns)
  # end
  # 
  # it "should make model acts_as_uploadable" do
  #   UploadableTestModel.should_receive(:acts_as_uploadable).once
  #   UploadableTestModel.class_eval("acts_as_image")
  # end
  # 
  # it "should make model acts_as_resizeable" do
  #   UploadableTestModel.should_receive(:acts_as_resizeable).once
  #   UploadableTestModel.class_eval("acts_as_image")
  # end
  # 
  # it "should destroy files after model instance destroy" do
  #   UploadableTestModel.should_receive(:after_destroy).with(:destroy_file, anything).once
  #   UploadableTestModel.class_eval("acts_as_image")
  # end
  # 
  # it "should destroy thumbnails after model instance destroy" do
  #   UploadableTestModel.should_receive(:after_destroy).with(anything, :destroy_thumbnails).once
  #   UploadableTestModel.class_eval("acts_as_image")
  # end
end