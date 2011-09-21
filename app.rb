require "sinatra"
require "redis"
require "yaml"

CONF = YAML.load File.read("config.yml")
REDIS = Redis.new *CONF["redis"]

helpers do
  def partition(coords)
    coords.scan(/..?/).join("/")
  end
end

get "/" do
  erb :index
end

get "/res/:coords.jpg" do
  coords = params[:coords]
  halt 404 unless coords =~ /\A[1-4]+\z/
  if File.exist?("public/imgs/#{partition coords}.jpg")
    redirect "imgs/#{partition coords}.jpg" and return
  end
  unless REDIS.sismember "mandelbrot:done", coords
    REDIS.zadd "mandelbrot:queue", coords.length, coords
    REDIS.publish "mandelbrot:notify", "new"
  end
  [404, File.open("public/404.png")]
end