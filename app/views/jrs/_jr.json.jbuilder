json.extract! jr, :id, :name, :original_url, :forked_url, :readme, :sha, :description, :platform, :classname, :version, :created_at, :updated_at
json.url jr_url(jr, format: :json)
