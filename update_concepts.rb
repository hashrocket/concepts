# encoding: UTF-8
require 'bundler'
require 'json'
require 'logger'
require 'yaml'
require 'erb'
require 'fileutils'

Bundler.require                    # defaults to all groups

GITHUB_API_TOKEN = File.read('graphql.token').strip
ROOT_DOMAIN = ENV.fetch("ROOT_DOMAIN", "hrcpt.online")
ROOT_DOMAIN_PORT = ENV["ROOT_DOMAIN_PORT"]
ROOT_DOMAIN_URL = [ROOT_DOMAIN, ROOT_DOMAIN_PORT].compact.join(?:)
HEADER = File.read('header.html')
LOG_PATH = './log/hr_concepts.log'
NGINX_DIR = './nginx'
NGINX_DIR_TMP = './nginx_tmp'
WWW_DIR = './www/concepts.com'
CHROME_APP = ENV.fetch('GOOGLE_CHROME_APP')

if ARGV[0] == 'clean'
  puts "Removing #{LOG_PATH}"
  FileUtils.rm_f(LOG_PATH)
  puts "Removing #{NGINX_DIR}"
  FileUtils.rm_rf(NGINX_DIR)
  puts "Removing #{NGINX_DIR_TMP}"
  FileUtils.rm_rf(NGINX_DIR_TMP)
  puts "Removing #{WWW_DIR}"
  FileUtils.rm_rf(WWW_DIR)
  exit(0)
end

def logger
  @logger
end

def setup_logging
  FileUtils.mkdir_p('./log')
  FileUtils.touch(LOG_PATH)

  @logger = Logger.new(File.open(LOG_PATH, File::WRONLY | File::APPEND), 'weekly')
  @logger.info('Starting Update Concepts')
end

def setup_exit
  at_exit do
    if $!
      logger.error("Uncaught Error: #{$!.message}")
    else
      logger.info('Ending Update Concepts')
    end
  end
end

def graphql_request(payload)
  logger.info('request')
  url = 'https://api.github.com/graphql'
  RestClient.post url, payload.to_json, {'Authorization' => "bearer #{GITHUB_API_TOKEN}"}
rescue => e
  logger.error(e.message)
  exit(1)
end

def make_initial_github_request
  payload = {
    "query": "query {
    organization(login: \"hashrocket\") {
      members(first:50) {
        edges {
          node {
            ... on User {
              login
              name
              repositories(first:50) {
                pageInfo {
                  endCursor
                  hasNextPage
                }
                edges {
                  node {
                    name
                    isFork
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

  logger.info("Successful initial github query with code: #{response.code}")

  JSON.parse(response.body)
end

def retrieve_concepts_from_initial_query(graphql_response_json)
  member_edges = graphql_response_json["data"]["organization"]["members"]["edges"]

  next_queries = []

  concepts = member_edges.reduce([]) do |coll, member_edge|
    login = member_edge["node"]["login"]
    end_cursor = member_edge["node"]["repositories"]["pageInfo"]["endCursor"]
    has_next_page = member_edge["node"]["repositories"]["pageInfo"]["hasNextPage"]

    if has_next_page
      next_queries << [login, end_cursor]
    end

    repo_edges = member_edge["node"]["repositories"]["edges"]

    coll + parse_repo_edges(repo_edges, login)
  end

  return next_queries, concepts
end

def collect_users(graphql_response_json)
  member_edges = graphql_response_json["data"]["organization"]["members"]["edges"]

  member_edges.reduce({}) do |members_hash, member_edge|
    login = member_edge["node"]["login"]
    members_hash[login] = member_edge["node"]["name"]
    members_hash
  end
end

def retrieve_second_page_concepts(next_queries)
  next_queries.reduce([]) do |coll, (login, end_cursor)|
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

    logger.info("Auxiallary request for #{login} has responded with code: #{response.code}")

    graphql_response_json = JSON.parse(response.body)
    repo_edges = graphql_response_json["data"]["user"]["repositories"]["edges"]

    coll + parse_repo_edges(repo_edges, login)
  end
end

def parse_repo_edges(repo_edges, login)
  repo_edges.map do |repo_edge|
    repo_name = repo_edge["node"]["name"]
    repo_concept_config = repo_edge["node"]["object"]

    if repo_concept_config != nil && !repo_edge["node"]["isFork"]
      {
        login: login,
        repo_name: repo_name,
        concept_config: repo_concept_config
      }
    end
  end.compact
end

def get_nginx_config(concept_yaml, concept)
  banner_sub_filter = if concept_yaml['banner']
                        <<~BANNER_FILTER
                        sub_filter <body> '<body><iframe seamless=\"seamless\" style=\"width: 100%; height: 50px; border: none;\" src="http://#{ROOT_DOMAIN_URL}/header.html">#{HEADER}</iframe><div style=\"position: relative;\">';
                        sub_filter </body> '</div></body>';
                        BANNER_FILTER
                      end

  <<~NGINX
  # this is an auto-generated from #{__FILE__}
  server {
    listen #{ROOT_DOMAIN_PORT || 80};

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

    sub_filter '</head>' '<script>window.addEventListener("message", function(e) { if (window.origin !== e.origin) {window.location = e.data;}})</script></head>';
    #{banner_sub_filter}
  }
  NGINX
end

def get_concept_screenshot(concept_yaml)
  screenshot_path = "#{WWW_DIR}/images/#{concept_yaml['name']}.png"

  get_screenshot = if File.exists?(screenshot_path)
                     time_since_screenshot = Time.new - File.mtime(screenshot_path)
                     time_since_screenshot > 60 * 60 * 24 * 2
                   else
                     true
                   end

  if get_screenshot
    `#{CHROME_APP} --headless --disable-gpu --screenshot --window-size=1200,900 #{concept_yaml['url']}`
    FileUtils.mv('./screenshot.png', screenshot_path)
    File.chmod(0444, screenshot_path)
  end
end

def parse_hrconcept_yaml(yaml_text, &block)
  begin
    concept_yaml = YAML.load(yaml_text)
    block.call(concept_yaml)
  rescue Psych::SyntaxError => e
    logger.error("YAML for #{concept[:login]}/#{concept[:repo]} was unparseable, please edit and try again.")
    nil
  end
end


setup_logging
setup_exit

graphql_response_json = make_initial_github_request

users_map = collect_users(graphql_response_json)
next_queries, concepts = retrieve_concepts_from_initial_query(graphql_response_json)

concepts += retrieve_second_page_concepts(next_queries)

logger.info("We found #{concepts.count} instances of a .hrconcept")

FileUtils.mkdir_p("#{WWW_DIR}")
FileUtils.cp('header.html', "#{WWW_DIR}/" )
FileUtils.mkdir_p(NGINX_DIR)
FileUtils.mkdir_p(NGINX_DIR_TMP)
FileUtils.rm_f("#{NGINX_DIR_TMP}/*")
FileUtils.mkdir_p("#{WWW_DIR}/images/")

valid_concepts = concepts.map do |concept|
  parse_hrconcept_yaml(concept[:concept_config]['text']) do |concept_yaml|
    concept_nginx = get_nginx_config(concept_yaml, concept)
    get_concept_screenshot(concept_yaml)

    concept[:concept_url] = "#{concept_yaml['name']}.#{ROOT_DOMAIN}";

    File.write("#{NGINX_DIR_TMP}/#{concept_yaml['name']}", concept_nginx)

    concept
  end
end.compact

FileUtils.rm_f(Dir.glob("#{NGINX_DIR}/*"))  # <--------- If the .hrconcept file or repo is removed, make sure its taken down from hrconcepts
FileUtils.cp_r(Dir.glob("#{NGINX_DIR_TMP}/*"), "#{NGINX_DIR}")


concepts_json = concepts.map do |concept|

  concept_yaml = YAML.load(concept[:concept_config]['text'])
  {
    title: concept_yaml['name'],
    github_url: "https://github.com/#{concept[:login]}/#{concept[:repo_name]}",
    author: concept[:login],
    full_name: users_map[concept[:login]],
    description: concept_yaml['description'],
    screenshot_url: "images/#{concept_yaml['name']}.png",
    hrcpt_url: concept_yaml['url'],
    author_url: "http://github.com/#{concept[:author]}"
  }
end

File.write('concepts.json', concepts_json.to_json)


# Uncomment to save data to use when iterateing on erb file
# File.write('concepts.data', Marshal.dump(concepts))
File.write("#{WWW_DIR}/index.html", ERB.new(File.read('index.html.erb')).result(binding))

# Should have a great index.html
# Should have a great set of nginx files
