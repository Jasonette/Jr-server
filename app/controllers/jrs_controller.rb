class JrsController < ApplicationController
  before_action :set_jr, only: [:show, :edit, :update, :destroy]

  # GET /jrs
  # GET /jrs.json
  def index
    @jrs = Jr.order(updated_at: :desc).limit(10)
  end

  # GET /jrs/1
  # GET /jrs/1.json
  def show
  end

  # GET /jrs/new
  def new
    @jr = Jr.new
  end

  # GET /jrs/1/edit
  def edit
  end

  def parse
  end

  def github(url)
    m = /github\.com\/([^\/]+)\/([^\/]+)/.match(url)
    if m and m.length == 3
      return {user: m[1], repo: m[2]}
    else
      return nil
    end
  end

  # return the array containing all the reasons why it's not valid
  # empty return value means it's valid
  def validate(res, senior)
    # need to check that all mandatory fields exist
    #   1. name
    #   2. classname
    #   3. platform
    #   4. version

    reasons = []

    if res.has_key? "name"
      if res["name"].match(/^[[:upper:]]+$/)
        reasons.push "'name' field must be lowercase only"
      end
    else
      reasons.push "'name' field should exist." 
    end

    if res.has_key? "classname"
      # is it the same classname?
      # if not, is there a jr with the same classname?
      if senior and senior["classname"] != res["classname"]
        if Jr.find_by(classname: res["classname"])
          # classname already exists! error!
          reasons.push "the classname '#{res['classname']}' is already taken!"
        end
      end
    else
      reasons.push "'classname' field should exist." 
    end

    if res.has_key? "platform"
      if not (["ios", "android"].include? res["platform"].downcase)
        reasons.push "platform must be either 'ios' or 'android'"
      end
    else
      reasons.push "'platform' field should exist." 
    end

    if res.has_key? "version"
      # the version must be integer
      begin
        new_version = Semantic::Version.new res["version"].to_s
        if senior
          old_version = Semantic::Version.new senior["version"].to_s
          if new_version <= old_version
            reasons.push "the 'version' must be greater than the last version: #{senior['version']}"
          end
        end
      rescue
        reasons.push "Please use semantic versioning (Example: '1.0.1'). See http://semver.org/ for more details."
      end
    else
      reasons.push "'version' field should exist." 
    end

    # return reasons array
    return reasons
  end

	def search
		@jrs = Jr.search(params[:query])
		render :index
	end

  # POST /jrs
  # POST /jrs.json
  def create
    gh = github(jr_params[:original_url])
    if not gh
      respond_to do |format|
        format.html { render json: {errors: ["the url must be a valid github repo url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
        format.json { render json: {errors: ["the url must be a valid github repo url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
      end
    elsif gh and gh[:user].downcase == "jasonextension"
      respond_to do |format|
        format.html { render json: {errors: ["cannot register that url. Use your own github url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
        format.json { render json: {errors: ["cannot register that url. Use your own github url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
      end
    else

      repo_info_url = "https://api.github.com/repos/#{gh[:user]}/#{gh[:repo]}"
      repo_info = HTTParty.get(repo_info_url, headers: {"User-Agent" => "Jr", "Cache-Control" => "no-cache, no-store, max-age=0, must-revalidate"})
      puts "repo_info =  #{repo_info.inspect}"
      if not repo_info.has_key? "id"
        reasons = ["The repository doesn't exist"]
      elsif repo_info.has_key? "parent"
        reasons = ["The repository must be independent and not a fork of another repository"]
      else
        org = "JasonExtension"
        name = "#{gh[:user]}_#{gh[:repo]}"
        git_url = "https://github.com/#{gh[:user]}/#{gh[:repo]}.git"
        registry_git_url = "https://github.com/#{org}/#{name}.git"

        # 1. if file exists, delete it first
        if File.exists? "/tmp/#{name}"
          FileUtils.remove_dir "/tmp/#{name}"
        end

        # 2. clone
        g = Git.clone(git_url, name, :path => '/tmp')

        if File.exist?("/tmp/#{name}/jr.json")
          file = File.read("/tmp/#{name}/jr.json")
          res = JSON.parse(file)
          readme_filename = Dir.entries("/tmp/#{name}").find { |f| f.downcase == 'readme.md' }
          readme = ""
          if readme_filename
            readme = File.read("/tmp/#{name}/#{readme_filename}")
          end

          @jr = Jr.find_by(original_url: jr_params[:original_url])

          reasons = validate(res, @jr)
        else
          reasons = ["The repository needs to contain a 'jr.json' file in the root folder."]
        end
      end

      if reasons.count > 0
        # invalid
        respond_to do |format|
          format.html { render json: {jr: res, errors: reasons}, status: :unprocessable_entity }
          format.json { render json: {jr: res, errors: reasons}, status: :unprocessable_entity }
        end
      else
        # valid
        client = Octokit::Client.new :access_token => ENV["GH_TOKEN"]
        user = client.user

        # get sha by fetching the master
        ref_url = "https://api.github.com/repos/#{gh[:user]}/#{gh[:repo]}/git/refs"
        refs = HTTParty.get(ref_url, headers: {"User-Agent" => "Jr", "Cache-Control" => "no-cache, no-store, max-age=0, must-revalidate"})

        m = refs.select{ |ref| ref["ref"] == "refs/heads/master" }
        if m.count > 0
          master = m[0]
          sha = master["object"]["sha"]
          version = res["version"].to_s

          forked_url = "https://github.com/JasonExtension/#{gh[:user]}_#{gh[:repo]}"

          if @jr
            # if already exists, update ref
            repo = Octokit::Repository.from_url forked_url
            client.update_ref repo, "heads/master", sha

            @jr.update_attributes(name: res["name"], platform: res["platform"].downcase, description: res["description"], classname: res["classname"], version: version, sha: sha, readme: readme)
            respond_to do |format|
              format.html { redirect_to jrs_url, notice: 'Jr was successfully updated.' }
              format.json { render :show, status: :updated, location: @jr }
            end
          else
            # if new, fork
            repo = Octokit::Repository.from_url jr_params[:original_url]
            forked = client.fork repo, :organization => "JasonExtension"
            puts "forked = #{forked.inspect}"

            # rename the repo to avoid redundancy
            # JasonExtension/JasonDemoAction becomes JasonExtension/gliechtenstein_JasonDemoAction 
            repo = Octokit::Repository.from_url forked[:html_url]
            begin
              edited = client.edit repo, :name => "#{forked['parent']['owner']['login']}_#{forked["name"]}"

              @jr = Jr.new(original_url: jr_params[:original_url], forked_url: forked_url, name: res["name"], platform: res["platform"].downcase, description: res["description"], classname: res["classname"], version: res["version"], sha: sha, readme: readme)
              @jr.save
              respond_to do |format|
                format.html { redirect_to jrs_url, notice: 'Jr was successfully created.' }
                format.json { render :show, status: :created, location: @jr }
              end
            rescue
              respond_to do |format|
                format.html { render json: {action: "retry", errors: ["Please retry"]}, status: :unprocessable_entity }
                format.html { render json: {action: "retry", errors: ["Please retry"]}, status: :unprocessable_entity }
              end
            end
          end
        else
          respond_to do |format|
            format.html { render json: {errors: ["something went wrong. the url must be a valid github repo url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
            format.json { render json: {errors: ["something went wrong. the url must be a valid github repo url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
          end
        end
      end
    end

  end

  # PATCH/PUT /jrs/1
  # PATCH/PUT /jrs/1.json
  def update
    respond_to do |format|
      if @jr.update(jr_params)
        format.html { redirect_to @jr, notice: 'Jr was successfully updated.' }
        format.json { render :show, status: :ok, location: @jr }
      else
        format.html { render :edit }
        format.json { render json: @jr.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jrs/1
  # DELETE /jrs/1.json
  def destroy
    @jr.destroy
    respond_to do |format|
      format.html { redirect_to jrs_url, notice: 'Jr was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_jr
      @jr = Jr.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def jr_params
      params.require(:jr).permit(:name, :original_url, :forked_url, :description, :platform, :classname, :version)
    end
end
