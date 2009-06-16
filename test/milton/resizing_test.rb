require File.dirname(__FILE__) + '/../test_helper'

class ResizingTest < ActiveSupport::TestCase  
  context "processing thumbnails on create" do
    context "with recipes" do
      class ImageWithRecipes < Image
        is_attachment(
          :storage_options => { :root => ActiveSupport::TestCase.output_path },
          :recipes => {
            :foo => [{ :thumbnail => { :size => '50x50', :crop => true } }],
            :bar => [{ :thumbnail => { :size => '10x10' } }],
            :baz => [{ :thumbnail => { :size => '50x50' } }, { :thumbnail => { :size => '25x25', :crop => true } }],
          }
        )
      end
      
      setup do
        @image = ImageWithRecipes.create! :file => upload('milton.jpg')
      end
      
      should "recognize options from :foo recipe" do
        assert_equal 'milton.crop_size=50x50.jpg', File.basename(@image.path(:foo))
      end
      
      should "create :foo thumbnail" do
        assert File.exists?(@image.path(:foo))
      end
      
      should "create :bar thumbnail" do
        assert File.exists?(@image.path(:bar))
      end
      
      should "run :baz recipes in order" do
        assert_equal 'milton.size=50x50.crop_size=25x25.jpg', File.basename(@image.path(:baz))
      end
    end
        
    context "without sizes" do      
      setup do
        @image = Image.create! :file => upload('milton.jpg')
      end
      
      should "not create a 50x50 thumbnail" do
        assert !File.exists?(@image.path(:thumbnail => { :size => '50x50' }))
      end
      
      should "happily return path to non-existant 50x50 thumbnail" do
        assert_equal 'milton.size=50x50.jpg', File.basename(@image.path(:thumbnail => { :size => '50x50' }))
      end
    end
    
    context "with postprocessing" do
      class ImageWithPostprocessing < Image
        is_attachment :storage_options => { :root => ActiveSupport::TestCase.output_path }, :postprocessing => true
      end
      
      setup do
        @image = ImageWithPostprocessing.create! :file => upload('milton.jpg')
      end
      
      should "create a 50x50 thumbnail" do
        assert File.exists?(@image.path(:thumbnail => { :size => '50x50' }))
      end
      
      should "create a cropped 50x50 thumbnail" do
        assert File.exists?(@image.path(:thumbnail => { :size => '50x50', :crop => true }))
      end
    end
  end
end