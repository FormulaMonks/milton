require File.dirname(__FILE__) + '/../test_helper'

class AttachmentTest < ActiveSupport::TestCase
  context "being included into a model" do
    class NotAnAttachment < ActiveRecord::Base
    end
    
    context "NotAnAttachment" do
      should "not have milton_options" do
        assert !NotAnAttachment.respond_to?(:milton_options)
      end
      
      should "not have attachment methods" do
        assert !NotAnAttachment.respond_to?(:has_attachment_methods)
      end
    end
    
    context "Attachment" do    
      should "have milton_options on Attachment" do
        assert Attachment.respond_to?(:milton_options)
      end
      
      should "have attachment methods" do
        assert Attachment.respond_to?(:has_attachment_methods)
      end
      
      should "have a hash of options" do
        assert Attachment.milton_options.is_a?(Hash)
      end
    end
  end
  
  context "setting options" do
    context "defaults" do
      class DefaultAttachment < ActiveRecord::Base
        is_attachment
      end
            
      should "use :disk as default storage" do
        assert_equal :disk, Attachment.milton_options[:storage]
      end
      
      should "use #{Rails.root}/public/default_attachments as default disk storage root" do
        assert_equal File.join(Rails.root, 'public', 'default_attachments'), DefaultAttachment.milton_options[:storage_options][:root]
      end
      
      should "use 0755 as default mode for new disk files" do
        assert_equal 0755, DefaultAttachment.milton_options[:storage_options][:chmod]
      end

      should "raise LoadError if storage engine could not be required" do
        assert_raise LoadError do
          class BadStorageAttachment < ActiveRecord::Base
            is_attachment :storage => :foo
          end
        end
      end
      
      should "raise helpful LoadError if storage engine could not be required" do
        begin
          class BadStorageAttachment < ActiveRecord::Base
            is_attachment :storage => :foo
          end
        rescue LoadError => e
          assert_equal "No 'foo' storage found for Milton (failed to require milton/storage/foo_file)", e.message
        end
      end
    end

    context "inheritence" do
      class FooImage < Image
        is_attachment :resizeable => { :sizes => { :foo => { :size => '10x10' } } }
      end

      class BarImage < FooImage # note that BarImage < FooImage < Image
        is_attachment :resizeable => { :sizes => { } }
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
    
    context "encapsulation" do
      class FooRootImage < Image
        is_attachment :storage_options => { :root => '/foo' }
      end
    
      class BarRootImage < Image
        is_attachment :storage_options => { :root => '/bar' }
      end
    
      should "not overwrite FooRootImage's root setting with BarRootImage's" do
        assert_equal '/foo', FooRootImage.milton_options[:storage_options][:root]
      end

      should "not overwrite BarRootImage's root setting with FooRootImage's" do
        assert_equal '/bar', BarRootImage.milton_options[:storage_options][:root]
      end
    end
  end
  
  context "getting mime-type" do
    setup do
      @attachment = Attachment.new :file => upload('milton.jpg')
    end
    
    context "from freshly uploaded file" do
      should "recognize it as an image/jpg" do
        assert_equal 'image/jpg', @attachment.content_type
      end
    end
    
    context "from existing file" do
      setup do
        @attachment.save
        @attachment.reload
      end
      
      should "recognize it as an image/jpg" do
        assert_equal 'image/jpg', @attachment.content_type
      end
    end
    
    context "from file with no content_type set" do
      setup do
        @attachment.update_attribute(:content_type, nil)
        @attachment.save
        @attachment.reload
      end
      
      should "attempt to determine mime_type from file" do
        # this is implemented w/ unix file cmd so is system dependent currently...
        assert_equal 'image/jpeg', @attachment.content_type
      end
    end
  end
  
  context "creating attachment folder" do
    raise "Failed to create #{File.join(output_path, 'exists')}" unless FileUtils.mkdir_p(File.join(output_path, 'exists'))
    FileUtils.ln_s 'exists', File.join(output_path, 'linked')
    raise "Failed to symlink #{File.join(output_path, 'linked')}" unless File.symlink?(File.join(output_path, 'linked'))
    
    class NoRootAttachment < Attachment
      is_attachment :storage_options => { :root => File.join(ActiveSupport::TestCase.output_path, 'nonexistant') }
    end
    
    class RootExistsAttachment < Attachment
      is_attachment :storage_options => { :root => File.join(ActiveSupport::TestCase.output_path, 'exists') }
    end
    
    class SymlinkAttachment < Attachment
      is_attachment :storage_options => { :root => File.join(ActiveSupport::TestCase.output_path, 'linked') }
    end
    
    should "create root path when root path does not exist" do    
      @attachment = NoRootAttachment.create :file => upload('milton.jpg')
      assert File.exists?(@attachment.path)
      assert File.exists?(File.join(output_path, 'nonexistant'))
      assert_match /nonexistant/, @attachment.path
    end
    
    should "work when root path already exists" do
      @attachment = RootExistsAttachment.create :file => upload('milton.jpg')
      assert File.exists?(@attachment.path)
      assert_match /exists/, @attachment.path
    end
    
    should "work when root path is a symlink" do
      @attachment = SymlinkAttachment.create :file => upload('milton.jpg')
      assert File.exists?(@attachment.path)
      assert_match /linked/, @attachment.path
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
  
  context "handling uploads" do    
    context "filename column" do
      should "raise an exception if there is no filename column" do
        assert_raise RuntimeError do
          class NotUploadable < ActiveRecord::Base # see schema.rb, there is a not_uploadables table
            is_attachment
          end
        end
      end

      should "not raise an exception if the underlying table doesn't exist" do
        assert_nothing_raised do
          class NoTable < ActiveRecord::Base
            is_attachment
          end
        end
      end
    end

    context "class extensions" do
      context "class methods" do
        should "add before_file_saved callback" do
          assert Attachment.respond_to?(:before_file_saved)
        end

        should "add after_file_saved callback" do
          assert Attachment.respond_to?(:after_file_saved)
        end
      end
    end

    context "handling file upload" do
      context "saving upload" do
        setup do
          @attachment = Attachment.new :file => upload('milton.jpg')
        end

        should "save the upload to the filesystem on save" do
          @attachment.save
          assert File.exists?(@attachment.path)
        end

        should "have the same filesize as original file when large enough not to be a StringIO" do
          # FIXME: this doesn't actually upload as a StringIO, figure out how to
          # force that
          @attachment.save
          assert_equal File.size(File.join(File.dirname(__FILE__), '..', 'fixtures', 'milton.jpg')), File.size(@attachment.path)
        end

        should "have the same filesize as original file when small enough to be a StringIO" do
          assert_equal File.size(File.join(File.dirname(__FILE__), '..', 'fixtures', 'mini-milton.jpg')), File.size(Attachment.create(:file => upload('mini-milton.jpg')).path)
        end
      end

      context "stored full filename" do
        setup do
          @attachment = Attachment.create! :file => upload('milton.jpg')
        end

        should "use set root" do
          assert_match /^#{@attachment.milton_options[:storage_options][:root]}.*$/, @attachment.path
        end

        should "use uploaded filename" do
          assert_match /^.*#{@attachment.filename}$/, @attachment.path
        end
      end

      context "sanitizing filename" do
        setup do
          @attachment = Attachment.create! :file => upload('unsanitary .milton.jpg')
        end

        should "strip the space and . and replace them with -" do
          assert_match /^.*\/unsanitary--milton.jpg$/, @attachment.path
        end

        should "exist with sanitized filename" do
          assert File.exists?(@attachment.path)
        end
      end

      context "saving attachment after upload" do
        setup do
          @attachment = Attachment.create! :file => upload('unsanitary .milton.jpg')
        end

        should "save the file again" do
          assert_nothing_raised do
            Attachment.find(@attachment.id).save!
          end
        end
      end
    end
  end
  
  context "updating an existing attachment" do
    setup do
      @attachment = Attachment.create! :file => upload('milton.jpg')
      @original_path = @attachment.path
      @attachment.update_attributes! :file => upload('big-milton.jpg')
    end
    
    should "store the path to the updated upload" do
      assert_equal 'big-milton.jpg', File.basename(@attachment.path)
    end
    
    should "save the updated upload" do
      assert File.exists?(@attachment.path)
    end
  end
end
