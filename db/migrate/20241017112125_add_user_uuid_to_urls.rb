class AddUserUuidToUrls < ActiveRecord::Migration[7.2]
  def change
    add_column :urls, :user_uuid, :string
  end
end
