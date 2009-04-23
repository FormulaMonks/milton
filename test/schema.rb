ActiveRecord::Schema.define :version => 0 do
  create_table :attachments, :force => true do |t|
    t.string :filename
  end

  create_table :images, :force => true do |t|
    t.string :filename
    t.string :content_type
  end
  
  create_table :not_uploadables, :force => true do |t|
  end
end
