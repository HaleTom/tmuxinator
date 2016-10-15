require "spec_helper"

describe Tmuxinator::Config do
  describe "#root" do
    context 'environment variable $TMUXINATOR_CONFIG set' do
      it "is $TMUXINATOR_CONFIG" do
        allow(ENV).to receive(:[]).with('TMUXINATOR_CONFIG').and_return 'expected'
        allow(File).to receive(:directory?).and_return true
        expect(Tmuxinator::Config.root).to eq 'expected'
      end
    end

    context "only ~/.tmuxinator exists" do
      it "is ~/.tmuxinator" do
        allow(File).to receive(:directory?).with(Tmuxinator::Config.xdg).and_return false
        allow(File).to receive(:directory?).with(Tmuxinator::Config.home).and_return true
        expect(Tmuxinator::Config.root).to eq Tmuxinator::Config.home
      end
    end
  end

    context "only $XDG_CONFIG_HOME/.tmuxinator exists" do
      it "is $XDG_CONFIG_HOME/.tmuxinator" do
        allow(File).to receive(:directory?).with(Tmuxinator::Config.xdg).and_return true
        allow(File).to receive(:directory?).with(Tmuxinator::Config.home).and_return false
        expect(Tmuxinator::Config.root).to eq Tmuxinator::Config.xdg
      end
    end

    context "both $XDG_CONFIG_HOME/.tmuxinator and ~/.tmuxinator" do
      it "should raise" do
        allow(File).to receive(:directory?).with(Tmuxinator::Config.xdg).and_return true
        allow(File).to receive(:directory?).with(Tmuxinator::Config.home).and_return true
        expect(Tmuxinator::Config.root).to eq Tmuxinator::Config.xdg
        # expect(Tmuxinator::Config.root).to eq 'expected'
        # expect do
        #   Tmuxinator::Config.root
        # end.to raise_error RuntimeError, %r{configuration}
      end
    end

  describe "#home" do
    it "is $XDG_CONFIG_HOME/.tmuxinator" do
      expect(Tmuxinator::Config.home).to eq "#{ENV['HOME']}/.tmuxinator"
    end
  end

  describe "#xdg" do
    it "is $XDG_CONFIG_HOME/.tmuxinator" do
      expect(Tmuxinator::Config.xdg).to eq "#{XDG['CONFIG_HOME']}/.tmuxinator"
    end
  end

  describe "#sample" do
    it "gets the path of the sample project" do
      expect(Tmuxinator::Config.sample).to include("sample.yml")
    end
  end

  describe "#default" do
    it "gets the path of the default config" do
      expect(Tmuxinator::Config.default).to include("default.yml")
    end
  end

  describe "#default_path_option" do
    context ">= 1.8" do
      before do
        allow(Tmuxinator::Config).to receive(:version).and_return(1.8)
      end

      it "returns -c" do
        expect(Tmuxinator::Config.default_path_option).to eq "-c"
      end
    end

    context "< 1.8" do
      before do
        allow(Tmuxinator::Config).to receive(:version).and_return(1.7)
      end

      it "returns default-path" do
        expect(Tmuxinator::Config.default_path_option).to eq "default-path"
      end
    end
  end

  describe "#default?" do
    let(:root) { Tmuxinator::Config.root }
    let(:local_default) { Tmuxinator::Config::LOCAL_DEFAULT }
    let(:proj_default) { Tmuxinator::Config.default }

    context "when the file exists" do
      before do
        allow(File).to receive(:exist?).with(local_default) { false }
        allow(File).to receive(:exist?).with(proj_default) { true }
      end

      it "returns true" do
        expect(Tmuxinator::Config.default?).to be_truthy
      end
    end

    context "when the file doesn't exist" do
      before do
        allow(File).to receive(:exist?).with(local_default) { false }
        allow(File).to receive(:exist?).with(proj_default) { false }
      end

      it "returns true" do
        expect(Tmuxinator::Config.default?).to be_falsey
      end
    end
  end

  describe "#configs" do
    before do
      # allow(Dir).to receive_messages(:[] => ["home.yml", "test2.yml"])
      allow(Dir).to receive(:[]).with(array_including(Tmuxinator::Config.xdg)) { ["xdg.yml", "both.yml"] }
      allow(Dir).to receive(:[]).with(array_including(Tmuxinator::Config.home)) { ["home.yml", "both.yml"] }
         # Dir["#{home}/**/*.yml"] + Dir["#{home}/**/*.yml"]
      # allow(Dir).to receive_messages(:[] => ["home.yml", "test2.yml"])
        files = Dir["#{home}/**/*.yml"] + Dir["#{home}/**/*.yml"]
    end

    it "gets a sorted list of all projects" do
      expect(Tmuxinator::Config.configs).to eq ["both", "both", "home", "xdg"]
    end

    it "lists only projects in $TMUXINATOR_CONFIG when set"
  end

  describe "#installed?" do
    context "tmux is installed" do
      before do
        allow(Kernel).to receive(:system) { true }
      end

      it "returns true" do
        expect(Tmuxinator::Config.installed?).to be_truthy
      end
    end

    context "tmux is not installed" do
      before do
        allow(Kernel).to receive(:system) { false }
      end

      it "returns true" do
        expect(Tmuxinator::Config.installed?).to be_falsey
      end
    end
  end

  describe "#editor?" do
    context "$EDITOR is set" do
      before do
        allow(ENV).to receive(:[]).with("EDITOR") { "vim" }
      end

      it "returns true" do
        expect(Tmuxinator::Config.editor?).to be_truthy
      end
    end

    context "$EDITOR is not set" do
      before do
        allow(ENV).to receive(:[]).with("EDITOR") { nil }
      end

      it "returns false" do
        expect(Tmuxinator::Config.editor?).to be_falsey
      end
    end
  end

  describe "#shell?" do
    context "$SHELL is set" do
      before do
        allow(ENV).to receive(:[]).with("SHELL") { "vim" }
      end

      it "returns true" do
        expect(Tmuxinator::Config.shell?).to be_truthy
      end
    end

    context "$SHELL is not set" do
      before do
        allow(ENV).to receive(:[]).with("SHELL") { nil }
      end

      it "returns false" do
        expect(Tmuxinator::Config.shell?).to be_falsey
      end
    end
  end

  describe "#exists?" do
    before do
      allow(File).to receive_messages(exist?: true)
      allow(Tmuxinator::Config).to receive_messages(project: "")
    end

    it "checks if the given project exists" do
      expect(Tmuxinator::Config.exists?("test")).to be_truthy
    end
  end

  describe "#project_in_root" do
    let(:root) { Tmuxinator::Config.root }
    let(:base) { "#{root}/sample.yml" }

    before do
      path = File.expand_path("../../../fixtures/", __FILE__)
      allow(Tmuxinator::Config).to receive_messages(root: path)
    end

    context "with project yml" do
      it "gets the project as path to the yml file" do
        expect(Tmuxinator::Config.project_in_root("sample")).to eq base
      end
    end

    context "without project yml" do
      it "gets the project as path to the yml file" do
        expect(Tmuxinator::Config.project_in_root("new-project")).to be_nil
      end
    end
  end

  describe "#local?" do
    it "checks if the given project exists" do
      path = Tmuxinator::Config::LOCAL_DEFAULT
      expect(File).to receive(:exist?).with(path) { true }
      expect(Tmuxinator::Config.local?).to be_truthy
    end
  end

  describe "#project_in_local" do
    let(:default) { Tmuxinator::Config::LOCAL_DEFAULT }

    context "with a project yml" do
      it "gets the project as path to the yml file" do
        expect(File).to receive(:exist?).with(default) { true }
        expect(Tmuxinator::Config.project_in_local).to eq default
      end
    end

    context "without project yml" do
      it "gets the project as path to the yml file" do
        expect(Tmuxinator::Config.project_in_local).to be_nil
      end
    end
  end

  describe "#project" do
    let(:root) { Tmuxinator::Config.root }
    let(:path) { File.expand_path("../../../fixtures/", __FILE__) }
    let(:default) { Tmuxinator::Config::LOCAL_DEFAULT }

    context "with project yml in the root directory" do
      before do
        allow(Tmuxinator::Config).to receive_messages(root: path)
      end

      it "gets the project as path to the yml file" do
        expect(Tmuxinator::Config.project("sample")).to eq "#{root}/sample.yml"
      end
    end

    context "with a local project, but no project in root" do
      it "gets the project as path to the yml file" do
        expect(File).to receive(:exist?).with(default) { true }
        expect(Tmuxinator::Config.project("sample")).to eq "./.tmuxinator.yml"
      end
    end

    context "without project yml" do
      let(:expected) { "#{root}/new-project.yml" }
      it "gets the project as path to the yml file" do
        expect(Tmuxinator::Config.project("new-project")).to eq expected
      end
    end
  end

  describe "#validate" do
    let(:path) { File.expand_path("../../../fixtures", __FILE__) }
    let(:default) { Tmuxinator::Config::LOCAL_DEFAULT }

    context "when a project name is provided" do
      it "should raise if the project file can't be found" do
        expect do
          Tmuxinator::Config.validate(name: "sample")
        end.to raise_error RuntimeError, %r{Project.+doesn't.exist}
      end

      it "should load and validate the project" do
        expect(Tmuxinator::Config).to receive_messages(root: path)
        expect(Tmuxinator::Config.validate(name: "sample")).to \
          be_a Tmuxinator::Project
      end
    end

    context "when no project name is provided" do
      it "should raise if the local project file doesn't exist" do
        expect(File).to receive(:exist?).with(default) { false }
        expect do
          Tmuxinator::Config.validate
        end.to raise_error RuntimeError, %r{Project.+doesn't.exist}
      end

      it "should load and validate the project" do
        content = File.read(File.join(path, "sample.yml"))

        expect(File).to receive(:exist?).with(default).at_least(:once) { true }
        expect(File).to receive(:read).with(default).and_return(content)

        expect(Tmuxinator::Config.validate).to be_a Tmuxinator::Project
      end
    end
  end
end
