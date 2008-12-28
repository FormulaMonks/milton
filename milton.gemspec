Gem::Specification.new do |s|
  s.name        = "milton"
  s.version     = "0.1.5"
  s.date        = "2008-12-27"
  s.summary     = "Asset handling Rails plugin that makes few assumptions and is highly extensible."
  s.email       = "ben.alavi@citrusbyte.com"
  s.homepage    = "http://labs.citrusbyte.com/milton"
  s.description = ""
  s.has_rdoc    = true
  s.authors     = [ "Ben Alavi" ]
  s.files       = [
    "INSTALL",
    "MIT-LICENSE",
    "README",
    "init.rb",
    "lib/milton.rb",
    "lib/milton/attachment.rb",
    "lib/milton/is_image.rb",
    "lib/milton/is_resizeable.rb",
    "lib/milton/is_uploadable.rb",
    "spec/schema.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/fixtures/big-milton.jpg",
    "spec/fixtures/milton.jpg",
    "spec/fixtures/mini-milton.jpg",
    "spec/fixtures/unsanitary .milton.jpg",
    "spec/milton/attachment_spec.rb",
    "spec/milton/is_image_spec.rb",
    "spec/milton/is_resizeable_spec.rb",
    "spec/milton/is_uploadable_spec.rb",
    "spec/milton/milton_spec.rb"
  ]
end