Gem::Specification.new do |s|
  s.name              = 'milton'
  s.rubyforge_project = 'milton'
  s.summary           = "Rails file and upload handling plugin built for extensibility. Supports Amazon S3 and resizes images."
  s.description       = "Rails file and upload handling plugin built for extensibility. Supports Amazon S3 and resizes images."
  s.version           = '0.3.5'
  s.author            = "Ben Alavi"
  s.email             = "ben.alavi@citrusbyte.com"
  s.homepage          = "http://labs.citrusbyte.com/projects/milton"
  s.files             = [
    		'README.markdown',
		'MIT-LICENSE',
		'Rakefile',
		'init.rb',
		'lib/milton/attachment.rb',
		'lib/milton/core/file.rb',
		'lib/milton/core/tempfile.rb',
		'lib/milton/derivatives/derivative.rb',
		'lib/milton/derivatives/thumbnail/crop_calculator.rb',
		'lib/milton/derivatives/thumbnail/image.rb',
		'lib/milton/derivatives/thumbnail.rb',
		'lib/milton/storage/disk_file.rb',
		'lib/milton/storage/s3_file.rb',
		'lib/milton/storage/stored_file.rb',
		'lib/milton/uploading.rb',
		'lib/milton.rb',
		'test/fixtures/big-milton.jpg',
		'test/fixtures/milton.jpg',
		'test/fixtures/mini-milton.jpg',
		'test/fixtures/unsanitary .milton.jpg',
		'test/milton/attachment_test.rb',
		'test/milton/milton_test.rb',
		'test/milton/resizing_test.rb',
		'test/s3_helper.rb',
		'test/schema.rb',
		'test/test_helper.rb'
  ]
end
