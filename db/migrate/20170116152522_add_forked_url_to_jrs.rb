class AddForkedUrlToJrs < ActiveRecord::Migration[5.0]
  def change
    add_column :jrs, :forked_url, :string
  end
end
