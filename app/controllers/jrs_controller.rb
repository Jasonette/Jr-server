class JrsController < ApplicationController
  before_action :set_jr, only: [:show, :edit, :update, :destroy]

  # GET /jrs
  # GET /jrs.json
  def index
    @jrs = Jr.all
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
    if m.length == 3
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

=begin
    if res.has_key? "version"
      # the version must be integer
      if res["version"].is_a? Numeric
        # the version must be greater than the last one
        if senior and (res["version"] <= senior["version"])
          reasons.push "the 'version' must be greater than the last version: #{senior['version']}"
        end
      else
        reasons.push "'version' should be an integer."
      end
    else
      reasons.push "'version' field should exist." 
    end
=end

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
    puts jr_params[:name]
    gh = github(jr_params[:url])
    if gh
      json_url = "https://raw.githubusercontent.com/#{gh[:user]}/#{gh[:repo]}/master/jr.json?#{Time.now.to_i}"
      response = HTTParty.get(json_url, headers: {"Cache-Control" => "no-cache, no-store, max-age=0, must-revalidate"})

      puts "RESPONSE = #{response.inspect}"

      git_url = "#{jr_params[:url]}.git"


      res = JSON.parse(response)

			@jr = Jr.find_by(url: jr_params[:url])

      reasons = validate(res, @jr)
      if reasons.count > 0
        # invalid
        respond_to do |format|
          format.html { render json: {errors: reasons}, status: :unprocessable_entity }
          format.json { render json: {errors: reasons}, status: :unprocessable_entity }
        end
      else
        # valid
        if @jr
          version = @jr["version"] + 1
=begin

          # Existing entry. Need to:
          # 1. "git clone" JasonExtension registry repo locally
          # 2. "git pull" user repo
          # 3. "git add ."
          # 4. "git commit -am "updating to version #{version}"
          # 5. "git push origin master"
          if res["platform"].downcase == 'ios'
            org = "JasonExtension-iOS"
          elsif res["platform"].downcase == 'android'
            org = "JasonExtension-Android"
          else
            # shouldn't happen
            org = nil
          end
          
          if org

            name = "#{gh[:user]}_#{gh[:repo]}"
            registry_git_url = "https://github.com/#{org}/#{name}.git"

            # 0. Check if the directory already exists, and if so, delete it first.
            if File.exists? "/tmp/#{name}"
              FileUtils.remove_dir "/tmp/#{name}"
            end

            # 1. clone
            g = Git.clone(registry_git_url, name, :path => '/tmp')

            g.chdir do
              # 2. pull
              g.pull git_url

              g.config('user.name', 'Jr')
              g.config('user.email', 'jr@jasonette.com')

              # 3. add
              g.add

              if g.status.changed.count > 0
                # 4. commit
                g.commit_all "Updating to version #{version}"
                # 5. push
                g.push
              end
            end
            @jr.update_attributes(name: res["name"], platform: res["platform"].downcase, description: res["description"], classname: res["classname"], version: version)
          end
=end
          @jr.update_attributes(name: res["name"], platform: res["platform"].downcase, description: res["description"], classname: res["classname"], version: version)

        else

          # New entry. Fork
          client = Octokit::Client.new :access_token => ENV["GH_TOKEN"]
          user = client.user
          puts user.login

          # fork the repo
          repo = Octokit::Repository.from_url jr_params[:url]
          forked = client.fork repo, :organization => "JasonExtension-iOS"
          puts "Forked = #{forked.inspect}"

          # rename the repo to avoid redundancy
          # JasonExtension-iOS/JasonDemoAction becomes JasonExtension-iOS/gliechtenstein_JasonDemoAction 
          repo = Octokit::Repository.from_url forked[:html_url]
          edited = client.edit repo, :name => "#{forked['parent']['owner']['login']}_#{forked["name"]}"
          puts "Edited = #{edited.inspect}"

          @jr = Jr.new(url: jr_params[:url], name: res["name"], platform: res["platform"].downcase, description: res["description"], classname: res["classname"], version: 1) 
          @jr.save
        end

        respond_to do |format|
          format.html { redirect_to jrs_url, notice: 'Jr was successfully created.' }
          format.json { render :show, status: :created, location: @jr }
        end
      end
    else
      respond_to do |format|
        format.html { render json: {errors: ["the url must be a valid github repo url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
        format.json { render json: {errors: ["the url must be a valid github repo url. Example: 'https://github.com/gliechtenstein/demoaction'"]}, status: :unprocessable_entity }
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
      params.require(:jr).permit(:name, :url, :description, :platform, :classname, :version)
    end
end
