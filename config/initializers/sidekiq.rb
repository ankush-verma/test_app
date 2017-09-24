## Add following lines
require 'sidekiq'
require 'sidekiq/web'

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == ["test", "test"]
end
 Sidekiq.configure_server do |config|
  config.redis = { url: 'redis:// 127.0.0.1:6379' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://127.0.0.1:6379' }
end