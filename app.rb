require 'sinatra'
require 'faraday'
require 'json'
require 'haml'
require 'coffee_script'

class Codeship
  ENDPOINT = 'https://www.codeship.io/api/v1/projects/'

  def initialize(api_key: nil, project: nil)
    @key, @project_id = api_key, project
  end

  def project
    response = Faraday.get(ENDPOINT + @project_id.to_s + ".json?api_key=#{@key}")
    JSON.parse(response.body)
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

    def [](project_id)
      @@projects ||= {}
      @@projects[project_id] ||= new(api_key: @@api_key, project: project_id)
    end
  end

end

Codeship.api_key = ENV['API_KEY']

set :bind, '0.0.0.0'

get '/' do
  return 404 if params[:token] != ENV['TOKEN']
  @trepscore = Codeship[ENV['PROJECT_ID']]
  @branches = @trepscore.builds_by_branch
  haml :branches
end