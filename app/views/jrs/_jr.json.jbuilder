json.extract! jr, :id, :name, :url, :readme, :sha, :description, :platform, :classname, :version, :created_at, :updated_at
json.url jr_url(jr, format: :json)
