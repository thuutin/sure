# Enable YJIT only when explicitly requested. It can improve throughput,
# but it also increases memory usage on smaller hosts.
if ENV["ENABLE_YJIT"] == "true" && defined?(RubyVM::YJIT.enable)
  Rails.application.config.after_initialize do
    RubyVM::YJIT.enable
  end
end
