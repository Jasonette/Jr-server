json.extract! jr, :id, :name, :readme, :sha, :description, :platform, :classname, :version, :created_at, :updated_at
json.source jr.url
json.url jr_url(jr, format: :json)
