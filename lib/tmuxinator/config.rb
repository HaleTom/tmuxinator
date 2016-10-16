module Tmuxinator
  class Config
    DIRECTORY_NAME_DEFAULT = ".tmuxinator".freeze
    LOCAL_DEFAULT = "./.tmuxinator.yml".freeze
    NO_LOCAL_FILE_MSG = "Project file at ./.tmuxinator.yml doesn't exist."

    class << self
      # The directory (created if needed) in which to store new projects
      def directory
        environment = ENV['TMUXINATOR_CONFIG']
        if !environment.nil? && !environment.empty?
          Dir.mkdir(environment) unless File.directory?(environment)
          return environment
        end
        return xdg if File.directory?(xdg)
        return home if File.directory?(home)
        # No project directory specified or existant, default to XDG:
        Dir.mkdir(xdg)
        xdg
      end

      def home
        config_directory(ENV['HOME'])
      end

      def xdg
        config_directory(XDG['CONFIG'])
      end

      def config_directory(parent)
        File.expand_path("#{parent}/#{DIRECTORY_NAME_DEFAULT}")
      end

      def sample
        asset_path "sample.yml"
      end

      def default
        "#{directory}/default.yml"
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

      # The first project found matching 'name'
      def global_project(name)
        project_in(xdg, name) || project_in(home, name)
      end

      # The first pathname of the project named 'name' found while
      # recursively searching 'directory'
      def project_in(directory, name)
        return nil if String(directory).empty?
        projects = Dir.glob("#{directory}/**/*.yml")
        projects.detect { |project| File.basename(project, ".yml") == name }
      end

      def local?
        local_project
      end

      def local_project
        [LOCAL_DEFAULT].detect { |f| File.exist?(f) }
      end

      def default_project(name)
        "#{directory}/#{name}.yml"
      end

      # Pathname of project file
      def project(name)
        project_in(ENV['TMUXINATOR_CONFIG'], name) ||
        project_in(xdg, name) ||
        project_in(home, name) ||
        local_project || # refactor?
        default_project(name)
      end

      def template
        asset_path "template.erb"
      end

      def wemux_template
        asset_path "wemux_template.erb"
      end

      # Sorted list of all projects, including duplicates
      def configs
        configs = []
        directories.each do |directory|
          configs += Array(Dir["#{directory}/**/*.yml"]).collect do |project|
            project.gsub("#{directory}/", "").gsub(".yml", "")
          end
        end
        configs.sort
      end

      # Directories searched for project files
      def directories
        environment = ENV['TMUXINATOR_CONFIG']
        if !environment.nil? && !environment.empty?
          [environment]
        else
          [xdg, home]
        end
      end

      def validate(options = {})
        name = options[:name]
        options[:force_attach] ||= false
        options[:force_detach] ||= false

        project_file = if name.nil?
                         raise NO_LOCAL_FILE_MSG \
                           unless Tmuxinator::Config.local?
                         local_project
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
