require 'sinatra'
require 'faraday'
require 'json'
require 'haml'
require 'coffee_script'

class Codeship
  ENDPOINT = 'https://www.codeship.io/api/v1/projects/'
  DEFAULT_CACHE_LIFETIME = 30

  def initialize(api_key: nil, project: nil)
    @key, @project_id = api_key, project
  end

  def project
    if @project.nil? || cache_expired?
      @last_update = Time.now
      response = Faraday.get(ENDPOINT + @project_id.to_s + ".json?api_key=#{@key}")
      @project = JSON.parse(response.body)
    else
      @project
    end
  end

  def cache_expired?
    puts "#{Time.now.to_i - @last_update.to_i} > #{@@cache_lifetime}"
    Time.now.to_i - @last_update.to_i >= (@@cache_lifetime || DEFAULT_CACHE_LIFETIME)
  end

  def builds
    project['builds']
  end

  def builds_by_branch
    builds.group_by { |build| build['branch'] }
  end

  def branches
    builds_by_branch.keys
  end

  class << self
    def api_key=(api_key)
      @@api_key = api_key
    end

    def cache_lifetime=(lifetime)
      @@cache_lifetime = lifetime
    end

    def [](project_id)
      @@projects ||= {}
      @@projects[project_id] ||= new(api_key: @@api_key, project: project_id)
    end
  end

end

Codeship.api_key = ENV['API_KEY']
Codeship.cache_lifetime = ENV['CACHE_LIFETIME'] || 30

set :bind, '0.0.0.0'

get '/' do
  return 404 if params[:token] != ENV['TOKEN']
  @trepscore = Codeship[ENV['PROJECT_ID']]
  @branches = @trepscore.builds_by_branch
  haml :branches
end