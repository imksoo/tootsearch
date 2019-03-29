# main.rb
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader'
require 'elasticsearch'
require 'dotenv/load'

set :bind, '0.0.0.0'

get '/api/v1/search' do
  content_type :json, :charset => 'utf-8'
  headers 'Access-Control-Allow-Origin' => 'https://wd-shiroma.github.io'

  client = Elasticsearch::Client.new(hosts: [
    {
      host: ENV["ES_HOST"],
      port: ENV["ES_PORT"]
    }
  ])
  sort = params.fetch('sort', '_score:desc')
  from = [params.fetch('from', 0).to_i, 0].max
  size = [params.fetch('size', 50).to_i, 100].min
  query = params.fetch('q', 'mastodon')

  # 2018/5/8 https://mstdn.jp/@tys/100020090139658680
  query += ' -account.acct:@tys@mstdn.jp'
  # 2019/3/19 https://garakuta.online/@ebi/101768398314539865 
  query += ' -account.acct:@ebi@garakuta.online'
  # 2019/3/24 https://garakuta.online/@admin/101801466271694359
  query += ' -account.acct:@garakuta.online'
  # 2019/3/30 https://mstdn.taiyaki.online/@Yellow/101827870211401011
  query += ' -account.acct:@Yellow@mstdn.taiyaki.online'

  result = client.search sort: sort, from: from, size: size,
    body: {
      query: {
        query_string: {
          query: query,
          default_field: "content",
          default_operator: "and"
        }
      }
    }

  json result
end

get '/healthcheck' do
  'OK ' + `hostname`.strip
end

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end
