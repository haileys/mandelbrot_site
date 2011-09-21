require "redis"
require "mandelbrot"
require "yaml"
require "fileutils"
require "devil"

CONF = YAML.load File.read("config.yml")
MIN = Complex CONF["mandelbrot"]["min"]
MAX = Complex CONF["mandelbrot"]["max"]
REDIS = Redis.new *CONF["redis"]

def bounds(coords)
  min = MIN
  max = MAX
  coords.chars do |c|
    w = max.real - min.real
    h = max.imag - min.imag
    case c.to_i
      when 3; max = Complex(min.real + w/2.0, min.imag + h/2.0)
      when 4; min = Complex(min.real + w/2.0, min.imag); max = Complex(max.real, min.imag + h/2.0)
      when 1; min = Complex(min.real, min.imag + h/2.0); max = Complex(min.real + w/2.0, max.imag)
      when 2; min = Complex(min.real + w/2.0, min.imag + h/2.0)
    end
  end
  [min, max]
end

def partition(coords, final = true)
  if final
    coords.scan(/..?/).join("/")
  else
    coords.scan(/..?/)[0..-1].join("/")
  end
end

loop do
  coords = REDIS.zrange("mandelbrot:queue", 0, 0)
  if coords
    coords = coords[0]
    REDIS.zremrangebyrank "mandelbrot:queue", 0, 0
    REDIS.sadd "mandelbrot:done", coords
  end
  
  if coords.nil?
    sleep 1
    next
  end
  
  st = Time.now.to_f
  FileUtils.mkpath "public/imgs/#{partition coords, false}"
  File.open("public/imgs/#{partition coords}.bmp", "wb") do |f|
    m = Mandelbrot.new(*bounds(coords))
    m.max_iters = 128 + 2 ** (coords.length + 2)
    f.write m.bmp(300, 300)
  end
  Devil.with_image("public/imgs/#{partition coords}.bmp") do |img|
    img.save "public/imgs/#{partition coords}.jpg"
  end
  File.delete "public/imgs/#{partition coords}.bmp"
  REDIS.publish "mandelbrot:finished:#{coords}", "ok."
  fn = Time.now.to_f
  puts sprintf("(%2.3fs) %s", fn - st, coords)
end