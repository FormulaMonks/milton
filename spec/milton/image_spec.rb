require File.dirname(__FILE__) + '/../spec_helper'

# FIXME: unify these settings and make them more easily settable, and document
# them
Image.uploadable_options[:storage_directory] = File.join(RAILS_ROOT, 'spec', 'assets')
Image.uploadable_options[:file_system_path]  = File.join(RAILS_ROOT, 'spec', 'assets')
Image.attachment_options[:file_system_path]  = File.join(RAILS_ROOT, 'spec', 'assets')

describe Image do
  describe "attachment_pow behavior" do    
    describe "instantiating" do
      before :each do
        @image = Image.new :file => upload('stache.jpg')
      end
    
      it "should have a file= method" do
        @image.should respond_to(:file=)
      end
    
      it "should set the filename from the uploaded file" do
        @image.filename.should eql('stache.jpg')
      end
      
      it "should strip SEPERATOR (.) from the filename and replace them with REPLACEMENT (-)" do
        @image.filename = 'foo.bar.baz.jpg'
        @image.filename.should eql('foo-bar-baz.jpg')
      end
    end
          
    describe "on image" do
      before :each do
        @image = Image.new
        @image.stub!(:filename).and_return('foo.jpg')
        @image.stub!(:id).and_return(1)
      end

      describe "building the filename from options" do
        it "should coalesce size into filename" do
          @image.filename_for(:size => '40x40').should eql('foo.size=40x40.jpg')
        end

        it "should coalesce crop into filename" do
          @image.filename_for(:crop => true).should eql('foo.crop=true.jpg')
        end

        it "should coalesce gravity into filename" do
          @image.filename_for(:gravity => 'north').should eql('foo.gravity=north.jpg')
        end

        it "should coalese all options together" do
          @image.filename_for(:gravity => 'north', :size => '40x40', :crop => true).should eql('foo.crop=true_gravity=north_size=40x40.jpg')
        end
      end

      describe "extracting options from filename (part of attachment_pow specs)" do        
        it "should parse size" do
          Image.options_from('size=40x40').should == { :size => '40x40' }
        end

        it "should parse crop" do
          Image.options_from('crop=true').should == { :crop => 'true' }
        end

        it "should parse gravity" do
          Image.options_from('gravity=north').should == { :gravity => 'north' }
        end

        it "should parse them all together" do
          Image.options_from('size=40x40_crop=true_gravity=north').should == { :size => '40x40', :crop => 'true', :gravity => 'north' }
        end
      end
    
      # iknow.jpg is 968x774px
      describe "reading dimensions" do
        before :each do
          @image = Image.create :file => upload('iknow.png', 'image/png')
        end
        
        it "should read width" do
          @image.width.should eql(968)
        end
        
        it "should read height" do
          @image.height.should eql(774)
        end
        
        it "should give width for larger dimension" do
          @image.larger_dimension.should eql(968)
        end
      end
    
      describe "smarter thumbnails" do
        before :each do
          @image = Image.create :file => upload('iknow.png', 'image/png')
        end
        
        it "should generate 640px wide version when image is wider than 640px wide and generating an image smaller than 640px wide" do
          @image.thumbnail(:crop => true, :size => '40x40')
          File.exists?(File.join(@image.send(:derivative_path), @image.filename_for(:size => '640x'))).should be_true
        end
        
        it "should generate images smaller than 640px wide from the existing 640px one" do
          # TODO: how can i test this?
          @image.thumbnail(:crop => true, :size => '40x40')
        end
      end
    
      describe "fetching thumbnails" do
        before :each do
          @image = Image.create :file => upload('stache.jpg')
        end
        
        it "should use the partitioned path when grabbing the original file" do
          @image.full_filename.should =~ /\/\d+\/\d+\/stache.jpg$/
        end

        it "should use the partitioned path and derivative path when grabbing a thubmnail" do
          @image.full_filename(:size => '10x10', :crop => true).should =~ /\/#{@image.path}\/stache\/stache.crop=true_size=10x10.jpg$/
        end
        
        it "should append source filename to thumbnail path" do
          @image.full_filename(:size => '10x10').should =~ /\/#{@image.path}\/stache\/stache.size=10x10.jpg$/
        end

        describe "destroying thumbnails" do
          before :each do
            FileUtils.stub!(:rm_rf).and_return(true)
            File.stub!(:exists?).and_return(true)
          end

          it "should use the partitioned path and derivative path when destroying all thumbnails" do
            FileUtils.should_receive(:rm_rf).with(File.join(RAILS_ROOT, 'spec', 'assets', @image.path, 'stache'))
            @image.send(:destroy_derivatives)
          end
        end
      end    
    end
  end
end
