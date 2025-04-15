# Puma configuration for Redmine MCP Server

# Environment
environment ENV.fetch('RACK_ENV', 'development')

# Address and Port
port ENV.fetch('PORT', 4000)
bind ENV.fetch('BIND', 'tcp://0.0.0.0:4000')

# Worker configuration
workers ENV.fetch('WEB_CONCURRENCY', 2)
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

# Preloading the application
preload_app!

# Logging
stdout_redirect(
  ENV.fetch('STDOUT_PATH', '/dev/stdout'),
  ENV.fetch('STDERR_PATH', '/dev/stderr'),
  true
)

# Additional configuration
plugin :tmp_restart
