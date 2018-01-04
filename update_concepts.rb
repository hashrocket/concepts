# encoding: UTF-8
require 'bundler'
require 'json'
require 'logger'
require 'yaml'
require 'erb'

@logger = Logger.new(File.open('/var/log/hr_concepts.log', File::WRONLY | File::APPEND), 'weekly')
@logger.info('Starting Update Concepts')

at_exit do
  if $!
    @logger.error("Uncaught Error: #{$!.message}")
  else
    @logger.info('Ending Update Concepts')
  end
end

Bundler.require                    # defaults to all groups

@url = 'https://api.github.com/graphql'
@token = File.read('graphql.token').strip

def graphql_request(payload)
  @logger.info('request')
  RestClient.post @url, payload.to_json, {'Authorization' => "bearer #{@token}"}
rescue => e
  @logger.error(e.message)
  exit(1)
end

payload = {
  "query": "query {
    organization(login: \"hashrocket\") {
      members(first:50) {
        edges {
          node {
            ... on User {
              login
              name
              repositories(first:100) {
                pageInfo {
                  endCursor
                  hasNextPage
                }
                edges {
                  node {
                    name
                    object(expression: \"master:.hrconcept\") {
                      ... on Blob {
                        text
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }"
}

response = graphql_request(payload)

@logger.info("Successful initial github query with code: #{response.code}")

graphql_response_json = JSON.parse(response.body)

member_edges = graphql_response_json["data"]["organization"]["members"]["edges"]

next_queries = []
concepts = []

member_edges.each do |member_edge|
  login = member_edge["node"]["login"]
  end_cursor = member_edge["node"]["repositories"]["pageInfo"]["endCursor"]
  has_next_page = member_edge["node"]["repositories"]["pageInfo"]["hasNextPage"]

  if has_next_page
    next_queries << [login, end_cursor]
  end

  repo_edges = member_edge["node"]["repositories"]["edges"]

  repo_edges.each do |repo_edge|
    repo_name = repo_edge["node"]["name"]
    repo_concept_config = repo_edge["node"]["object"]

    if repo_concept_config != nil
      concepts << {
        login: login,
        repo_name: repo_name,
        concept_config: repo_concept_config
      }
    end
  end
end

next_queries.each do |(login, end_cursor)|
  payload = {
    "query": "query {
      user(login: \"#{login}\") {
        repositories(first: 100, after: \"#{end_cursor}\") {
          pageInfo {
            hasNextPage
          }
          edges {
            node {
              name
              object(expression: \"master:.hrconcept\") {
                ... on Blob {
                  text
                }
              }
            }
          }
        }
      }
    }"
  }

  response = graphql_request(payload)

  @logger.info("Auxiallary request for #{login} has responded with code: #{response.code}")

  graphql_response_json = JSON.parse(response.body)
  repo_edges = graphql_response_json["data"]["user"]["repositories"]["edges"]

  repo_edges.each do |repo_edge|
    repo_name = repo_edge["node"]["name"]
    repo_concept_config = repo_edge["node"]["object"]

    if repo_concept_config != nil
      concepts << {
        login: login,
        repo_name: repo_name,
        concept_config: repo_concept_config
      }
    end
  end
end

@logger.info("We found #{concepts.count} instances of a .hrconcept")

header = ERB.new(File.read('header.html.erb')).result(binding)
concepts.each do |concept|

  begin
    concept_yaml = YAML.load(concept[:concept_config]['text'])
  rescue => e
    @logger.error("YAML for #{concept[:login]}/#{concept[:repo]} was unparseable, please edit and try again.")
    next
  end

  banner_sub_filter = if concept_yaml['banner']
                        <<~BANNER_FILTER
                        sub_filter <body> '<body>#{header}<div style=\"position: relative;\">';
                        sub_filter </body> '</div>></body>';
                        BANNER_FILTER
                      end

  `#{ENV.fetch('GOOGLE_CHROME_APP')} --headless --disable-gpu --screenshot --window-size=900,600 #{concept_yaml['url']}`

  require 'fileutils'
  FileUtils.mkdir_p("/var/www/concepts.com/images/")
  FileUtils.mv('./screenshot.png', "/var/www/concepts.com/images/#{concept_yaml['name']}.png" )
  concept[:concept_url] = "#{concept_yaml['name']}.hrcpt.online";

  nginx = <<~NGINX
  server {
    listen 80;

    server_name #{concept[:concept_url]};

    location / {
      proxy_set_header Accept-Encoding "";
      proxy_pass #{concept_yaml['url']};
      proxy_redirect off;
      proxy_read_timeout 5m;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-Proto http;
    }

    sub_filter '</head>' '<script>analytics</script></head>';
    #{banner_sub_filter}
  }
  NGINX

  require 'fileutils'
  FileUtils.mkdir_p('nginx')
  File.write("./nginx/#{concept_yaml['name']}", nginx)
end


# Uncomment to save data to use when iterateing on erb file
# File.write('concepts.data', Marshal.dump(concepts))
File.write("/var/www/concepts.com/index.html", ERB.new(File.read('index.html.erb')).result(binding))

# Should have a great index.html
# Should have a great set of nginx files
