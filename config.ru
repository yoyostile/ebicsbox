require_relative './config/bootstrap'

if ENV['RACK_ENV'] == 'production'
  if ENV['SENTRY_DSN']
    require 'raven'
    use Raven::Rack
  end

  # Log all requests in apache log file format
  use Rack::CommonLogger
end


# Load database connection validator middleware
require_relative './box/middleware/connection_validator'
use Box::Middleware::ConnectionValidator, DB

# Load authentication middleware
use Box.configuration.auth_provider

# Enable CORS to enable access to our API from frontend apps and our swagger documentation
require 'rack/cors'
use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
  end
end

# Deliver assets
use Rack::Static, urls: [
  "/swagger-ui-standalone-preset.js",
  "/swagger-ui-bundle.js",
  "/swagger-ui-standalone-preset.js",
  "/swagger-ui.css",
  "/swagger-ui.js",
  '/doc/swagger-v1.json',
  '/doc/swagger-v2.json'], root: "public/swagger"

# Deliver html/json documentation template
map '/docs' do
  run lambda { |env|
    [
      200,
      {
        'Content-Type'  => 'text/html',
        'Cache-Control' => 'public, max-age=86400'
      },
      File.open('public/swagger/index.html', File::RDONLY)
    ]
  }
end

# Finally, load application and all its endpoints
require_relative './box/apis/base'
run Box::Apis::Base
