class AddReadmeToJrs < ActiveRecord::Migration[5.0]
  def change
    add_column :jrs, :readme, :text
  end
end
