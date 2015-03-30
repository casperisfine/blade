require "faye"
require "sprockets"

class BladeRunner
  class Server < Base
    def start
      fork do
        STDIN.reopen("/dev/null")
        STDOUT.reopen("/dev/null", "a")
        STDERR.reopen("/dev/null", "a")
        Rack::Server.start(app: app, Port: runner.config.port, server: "puma")
      end
    end

    private
      def app
        _sprockets = sprockets
        _faye = faye

        Rack::Builder.app do
          map "/" do
            run _sprockets
          end

          map "/faye" do
            run _faye
          end
        end
      end

      def sprockets
        _runner = runner

        @sprockets ||= Sprockets::Environment.new do |env|
          env.cache = Sprockets::Cache::FileStore.new(runner.tmp_path)

          env.context_class.class_eval do
            define_method(:runner) do
              _runner
            end
          end

          asset_paths.each do |path|
            env.append_path(path)
          end
        end
      end

      def faye
        @faye ||= Faye::RackAdapter.new(mount: "/", timeout: 25)
      end

      def asset_paths
        local_asset_paths + remote_asset_paths
      end

      def local_asset_paths
        %w( src assets assets/vendor ).map { |a| runner.root_path.join(a) }
      end

      def remote_asset_paths
        runner.config.asset_paths.map { |a| Pathname.new(a) }
      end
  end
end