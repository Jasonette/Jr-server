class CreateJrs < ActiveRecord::Migration[5.0]
  def change
    create_table :jrs do |t|
      t.string :name
      t.string :url
      t.string :description
      t.string :platform
      t.string :classname
      t.integer :version

      t.timestamps
    end
    add_index :jrs, :name, unique: true
    add_index :jrs, :url, unique: true
    add_index :jrs, :classname, unique: true
  end
end
