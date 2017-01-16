class UpdateUrlToOriginalUrl < ActiveRecord::Migration[5.0]
  def change
    rename_column :jrs, :url, :original_url
  end
end
