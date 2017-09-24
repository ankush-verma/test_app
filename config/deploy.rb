 # config valid only for current version of Capistrano

set :application, 'test'
set :repo_url, 'git@github.com:ankush-verma/test_app.git'


set :user,            'deploy'
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :keep_releases, 3

# Don't change these unless you know what you're doing
set :pty,             false
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
set :rvm_ruby_version, '2.4.0'
set :rvm_ruby_version, "ruby-2.4.0@#{fetch(:application)}"
#set :rvm_custom_path, '/usr/share/rvm'  # only needed if not detected

set :linked_files, fetch(:linked_files, []).push('config/database.yml','config/application.yml','config/puma.rb','config/secrets.yml')
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')
set :sidekiq_default_hooks, true
set :sidekiq_pid, File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') 
set :sidekiq_env, fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
set :sidekiq_log, File.join(shared_path, 'log', 'sidekiq.log')
set :sidekiq_options, nil
set :sidekiq_require, nil
set :sidekiq_tag, nil
set :sidekiq_config, nil # if you have a config/sidekiq.yml, do not forget to set this. 
set :sidekiq_queue, nil
set :sidekiq_timeout, 10
set :sidekiq_role, :app
set :sidekiq_processes, 1
set :sidekiq_options_per_process, nil
set :sidekiq_concurrency, nil
set :sidekiq_service_name, "sidekiq_#{fetch(:application)}_#{fetch(:sidekiq_env)}"

namespace :puma do
    desc 'Create Directories for Puma Pids and Socket'
    task :make_dirs do
        on roles(:app) do
            execute "mkdir #{shared_path}/tmp/sockets -p"
            execute "mkdir #{shared_path}/tmp/pids -p"
        end
    end

    before :start, :make_dirs
end

namespace :deploy do
    desc "Make sure local git is in sync with remote."
    task :check_revision do
        on roles(:app) do
            unless `git rev-parse HEAD` == `git rev-parse origin/#{fetch(:branch)}`
                puts "WARNING: HEAD is not the same as origin/#{fetch(:branch)}"
                puts "Run `git push` to sync changes."
                exit
            end
        end
    end

    desc 'Initial Deploy'
    task :initial do
        on roles(:app) do
            before 'deploy:restart', 'puma:start'
            invoke 'deploy'
        end
    end

    desc 'Restart application'
    task :restart do
        on roles(:app), in: :sequence, wait: 5 do
            invoke 'puma:restart'
        end
    end

    desc 'stop application'
    task :stop do
        on roles(:app), in: :sequence, wait: 5 do
            invoke 'puma:stop'
        end
    end

    after 'deploy:restart', 'sidekiq:start'


    before :starting,     :check_revision
    after  :finishing,    :compile_assets
    after  :finishing,    :cleanup
    after  :finishing,    :stop
    after  :finishing,    :restart

end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma