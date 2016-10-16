module Tmuxinator
  class Config
    LOCAL_DEFAULT = "./.tmuxinator.yml".freeze
    NO_LOCAL_FILE_MSG = "Project file at ./.tmuxinator.yml doesn't exist."

    class << self
      def sample
        asset_path "sample.yml"
      end

      def default
        "#{root}/default.yml" # XXX
      end

      def default?
        exists?("default")
      end

      def installed?
        Kernel.system("type tmux > /dev/null")
      end

      def version
        `tmux -V`.split(" ")[1].to_f if installed?
      end

      def default_path_option
        version && version < 1.8 ? "default-path" : "-c"
      end

      def editor?
        !ENV["EDITOR"].nil? && !ENV["EDITOR"].empty?
      end

      def shell?
        !ENV["SHELL"].nil? && !ENV["SHELL"].empty?
      end

      def exists?(name)
        File.exist?(project(name))
      end

      def config_directory(parent)
        directory = File.expand_path("#{parent}/.tmuxinator")
      end

      # def create_directory_if_needed(dir) # XXXXXXXXXXXXXXX
      #   Dir.mkdir(dir) unless File.directory?(dir) # XXX return value
      # end

      def project_in_root(name)
        project_in(xdg, name) || project_in(home, name)
      end

      def project_in(directory, name)
        return nil if String(directory).empty?
        projects = Dir.glob("#{directory}/**/*.yml")
        projects.detect { |project| File.basename(project, ".yml") == name }
      end

      def local?
        project_in_local
      end

      def project_in_local
        [LOCAL_DEFAULT].detect { |f| File.exist?(f) }
      end

      # The directory (created if needed) in which to store new projects
      def root
        environment = ENV['TMUXINATOR_CONFIG']
        if !String(environment).empty?
          Dir.mkdir(environment) unless File.directory?(environment)
          return environment
        end
        return xdg if File.directory?(xdg)
        return home if File.directory?(home)
        # No project directory specified or exstant, default to XDG:
        Dir.mkdir(xdg)
        xdg
      end

      def home
        config_directory(ENV['HOME'])
      end

      def xdg
        config_directory(XDG['CONFIG'])
      end

      def default_project(name)
        # Only place new projects in XDG_CONFIG_HOME if it already exists
        "#{root}/#{name}.yml"
      end

      def project(name)
        project_in(ENV['TMUXINATOR_CONFIG'], name) ||
        project_in(xdg, name) ||
        project_in(home, name) ||
        project_in_local || # refactor?
        default_project(name)
      end

      def template
        asset_path "template.erb"
      end

      def wemux_template
        asset_path "wemux_template.erb"
      end

      def configs
        # Dir["#{Tmuxinator::Config.root}/**/*.yml"].sort.map do |path| # XXX make home and xdg. What if config appears twice?
        # Dir["#{home}/**/*.yml"].sort.map do |path| # XXX make home and xdg. What if config appears twice?
        # files = Dir["#{xdg}/**/*.yml"] + Dir["#{home}/**/*.yml"]
        # files = Array(Dir["#{xdg}/**/*.yml"]) + Dir["#{home}/**/*.yml"]
        files = Array(Dir["#{xdg}/**/*.yml"]) + Dir["#{home}/**/*.yml"] # why Array needed?
        # files = Dir["#{xdg}/*/*.yml", "#{home}/**/*.yml"]
        files.sort.map do |path|
          path.gsub("#{Tmuxinator::Config.root}/", "").gsub(".yml", "")
        end
      end

      def validate(options = {})
        name = options[:name]
        options[:force_attach] ||= false
        options[:force_detach] ||= false

        project_file = if name.nil?
                         raise NO_LOCAL_FILE_MSG \
                           unless Tmuxinator::Config.local?
                         project_in_local
                       else
                         raise "Project #{name} doesn't exist." \
                           unless Tmuxinator::Config.exists?(name)
                         Tmuxinator::Config.project(name)
                       end
        Tmuxinator::Project.load(project_file, options).validate!
      end

      private

      def asset_path(asset)
        "#{File.dirname(__FILE__)}/assets/#{asset}"
      end
    end
  end
end
