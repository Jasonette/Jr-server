json.extract! jr, :id, :name, :original_url, :forked_url, :readme, :sha, :description, :platform, :classname, :v, :created_at, :updated_at
json.url jr_url(jr, format: :json)
json.versions do
  json.array!(jr.versions) do |version|
    if version.reify
      json.sha version.reify.sha
      json.v version.reify.v
    else
      json.sha nil
      json.v nil
    end
  end
end
