class AddShaToJrs < ActiveRecord::Migration[5.0]
  def change
    add_column :jrs, :sha, :text
  end
end
