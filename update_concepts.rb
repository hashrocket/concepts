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
WWW_DIR = ENV['WWW_DIR'] || './www/concepts.com'
CHROME_APP = ENV.fetch('GOOGLE_CHROME_APP')
USER = ENV['CONCEPTS_USER'] || Etc.getlogin

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

def titleize(value)
  value.split(/[-_]/).map {|x| x.capitalize}.join(" ")
end

def slugify(value)
  value.downcase.gsub(/\s/, ?-)
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
      members(first: 50) {
        edges {
          node {
            ... on User {
              login
              name
              repositories(first:25) {
                pageInfo {
                  endCursor
                  hasNextPage
                }
                edges {
                  node {
                    createdAt
                    description
                    name
                    isFork
                    object(expression: \"master:.hrconcept\") {
                      ... on Blob {
                        text
                      }
                    }
                    languages(first:10) {
                      nodes {
                        name
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
              endCursor
              hasNextPage
            }
            edges {
              node {
                createdAt
                description
                name
                isFork
                object(expression: \"master:.hrconcept\") {
                  ... on Blob {
                    text
                  }
                }
                languages(first:10) {
                  nodes {
                    name
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
    repo_edges = graphql_response_json.dig("data", "user", "repositories", "edges")

    next_cursor = graphql_response_json.dig("data", "user", "repositories", "pageInfo", "endCursor")
    next_page = graphql_response_json.dig("data", "user", "repositories", "pageInfo", "hasNextPage")

    if next_page
      next_coll = retrieve_second_page_concepts([[login, next_cursor]])
    end

    coll + (next_coll || []) + parse_repo_edges(repo_edges || [], login)
  end
end

def parse_repo_edges(repo_edges, login)
  repo_edges.map do |repo_edge|
    repo_name = repo_edge["node"]["name"]
    repo_concept_config = repo_edge["node"]["object"]
    repo_created_at = repo_edge["node"]["createdAt"]
    repo_description = repo_edge["node"]["description"]

    languages = repo_edge['node']['languages']['nodes'].map{|lang| lang['name']}

    if repo_concept_config != nil && !repo_edge["node"]["isFork"]
      {
        login: login,
        repo_name: repo_name,
        description: repo_description,
        concept_config: repo_concept_config,
        languages: languages,
        created_at: repo_created_at
      }
    end
  end.compact
end

def get_nginx_config(concept)
  banner_sub_filter = if concept[:banner]
                        <<~BANNER_FILTER
                        sub_filter <body> '<body><iframe seamless=\"seamless\" style=\"width: 100%; height: 45px; border: none;\" src="http://#{ROOT_DOMAIN_URL}/#{concept[:slug]}-header.html"></iframe><div style=\"position: relative;\">';
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
      proxy_pass #{concept[:original_url]};
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

WHITE_IMAGE_OF_SPECIFIC_SIZE = "89283a7c5a1284bd6353384b5e86ea2fa282bbf8"

def get_concept_screenshot(slug, original_url)
  screenshot_path = "#{WWW_DIR}/images/#{slug}.png"

  FileUtils.rm(Dir.glob("#{WWW_DIR}/images/#{slug}.*.png"))

  get_screenshot = if File.exists?(screenshot_path)
                     time_since_screenshot = Time.new - File.mtime(screenshot_path)
                     (time_since_screenshot > 60 * 60 * 24 * 2) || `git hash-object #{screenshot_path}`.strip == WHITE_IMAGE_OF_SPECIFIC_SIZE
                   else
                     true
                   end

  if get_screenshot
    logger.info("Getting screenshot #{screenshot_path}")

    if File.exists?(screenshot_path)
      FileUtils.mv(screenshot_path, "#{screenshot_path}.bk")
    end

    command = "sudo -u #{USER} node screenshot.js #{original_url} #{screenshot_path}"
    `#{command}`

    unless File.exists?(screenshot_path)
      if File.exists?("#{screenshot_path}.bk")
        FileUtils.mv("#{screenshot_path}.bk", screenshot_path)
      else
        logger.error("The screenshot path does not exist: #{screenshot_path}\nMaybe check that puppeteer is installed with npm")
      end
    else
      FileUtils.rm_f("#{screenshot_path}.bk")
    end

    File.chmod(0444, screenshot_path)
  end

  cache_buster_path = "images/#{slug}.#{Time.now.to_i}.png"

  FileUtils.cp(screenshot_path, "#{WWW_DIR}/#{cache_buster_path}")

  cache_buster_path
end

def parse_hrconcept_yaml(yaml_text, &block)
  begin
    concept_yaml = YAML.load(yaml_text)
    if concept_yaml
      block.call(concept_yaml)
    else
      block.call({})
    end
  rescue Psych::SyntaxError => e
    logger.error("YAML for #{concept[:login]}/#{concept[:repo]} was unparseable, please edit and try again.")
    nil
  end
end

# *********** START EXECUTION ********** #
setup_logging
setup_exit

graphql_response_json = make_initial_github_request

users_map = collect_users(graphql_response_json)
next_queries, concepts = retrieve_concepts_from_initial_query(graphql_response_json)

concepts += retrieve_second_page_concepts(next_queries)

logger.info("We found #{concepts.count} instances of a .hrconcept")

FileUtils.mkdir_p("#{WWW_DIR}")
FileUtils.cp('header.html', "#{WWW_DIR}/" )
FileUtils.cp('hashrocket.svg', "#{WWW_DIR}/" )
FileUtils.cp('github.svg', "#{WWW_DIR}/" )
FileUtils.mkdir_p(NGINX_DIR)
FileUtils.mkdir_p(NGINX_DIR_TMP)
FileUtils.rm_f("#{NGINX_DIR_TMP}/*")
FileUtils.mkdir_p("#{WWW_DIR}/images/")

valid_concepts = concepts.map do |concept|
  parse_hrconcept_yaml(concept[:concept_config]['text']) do |concept_yaml|
    concept[:title] = titleize(concept_yaml['name'] || concept[:repo_name])
    concept[:slug] = slugify(concept_yaml['name'] || concept[:repo_name])

    concept[:github_url] = "https://github.com/#{concept[:login]}/#{concept[:repo_name]}"
    concept[:concept_url] = "#{concept[:slug]}.#{ROOT_DOMAIN}"
    concept[:concept_link_url] = concept_yaml['url'] ? "http://#{concept[:concept_url]}" : concept[:github_url]
    concept[:original_url] = concept_yaml['url'] || concept[:github_url]
    concept[:description] = (concept_yaml['description'] || concept.fetch(:description, '')).strip

    override_languages = concept_yaml['technologies'] || []
    concept[:languages] = override_languages.length > 0 ? override_languages : concept[:languages]
    concept[:languages] = concept[:languages].reject {|lang| lang =~ /html|css/i}
    concept[:banner] = concept_yaml.fetch('banner', "true").to_s == "true"

    screenshot_url = get_concept_screenshot(concept[:slug], concept[:original_url])
    concept[:screenshot_url] = screenshot_url
    concept_nginx = get_nginx_config(concept)

    File.write("#{NGINX_DIR_TMP}/#{concept[:slug]}", concept_nginx)
    File.write("#{WWW_DIR}/#{concept[:slug]}-header.html", ERB.new(HEADER).result(binding))

    concept
  end
end.compact

FileUtils.rm_f(Dir.glob("#{NGINX_DIR}/*"))  # <--------- If the .hrconcept file or repo is removed, make sure its taken down from hrconcepts
FileUtils.cp_r(Dir.glob("#{NGINX_DIR_TMP}/*"), "#{NGINX_DIR}")
FileUtils.cp('default.nginx', "#{NGINX_DIR}")

concepts_json = concepts.map do |concept|
  {
    title: concept[:title],
    author: concept[:login],
    created_at: concept[:created_at],
    full_name: users_map[concept[:login]],
    description: concept[:description],
    languages: concept[:languages].uniq {|x| x.downcase},
    screenshot_url: concept[:screenshot_url],
    hrcpt_url: concept[:concept_link_url],
    author_url: "http://github.com/#{concept[:login]}",
    github_url: concept[:github_url]
  }
end

File.write('concepts.json', {data: concepts_json}.to_json)
FileUtils.cp('concepts.json', "#{WWW_DIR}/" )

# Uncomment to save data to use when iterateing on erb file
# File.write('concepts.data', Marshal.dump(concepts))
