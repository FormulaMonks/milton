ActiveRecord::Schema.define :version => 0 do
  create_table :attachments, :force => true do |t|
    t.string :filename
    t.string :path
  end

  create_table :images, :force => true do |t|
    t.string :filename
    t.string :path
    t.string :content_type
  end
end
