require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/atlas/config")
require Vagrant.source_root.join("plugins/pushes/atlas/push")

describe VagrantPlugins::AtlasPush::Push do
  include_context "unit"

  let(:bin) { VagrantPlugins::AtlasPush::Push::UPLOADER_BIN }

  let(:env) do
    double("env",
      root_path: File.expand_path("..", __FILE__)
    )
  end

  let(:config) do
    VagrantPlugins::AtlasPush::Config.new.tap do |c|
      c.finalize!
    end
  end

  subject { described_class.new(env, config) }

  before do
    # Stub this right away to avoid real execs
    allow(Vagrant::Util::SafeExec).to receive(:exec)
  end

  describe "#push" do
    it "pushes with the uploader" do
      allow(subject).to receive(:uploader_path).and_return("foo")

      expect(subject).to receive(:execute).with("foo")

      subject.push
    end

    it "raises an exception if the uploader couldn't be found" do
      expect(subject).to receive(:uploader_path).and_return(nil)

      expect { subject.push }.to raise_error(
        VagrantPlugins::AtlasPush::Errors::UploaderNotFound)
    end
  end

  describe "#execute" do
    let(:app) { "foo/bar" }

    before do
      config.app = app
    end

    it "sends the basic flags" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", app, env.root_path.to_s)

      subject.execute("foo")
    end

    it "doesn't send VCS if disabled" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", app, env.root_path.to_s)

      config.vcs = false
      subject.execute("foo")
    end

    it "sends includes" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", "-include", "foo", "-include",
             "bar", app, env.root_path.to_s)

      config.includes = ["foo", "bar"]
      subject.execute("foo")
    end

    it "sends excludes" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", "-exclude", "foo", "-exclude",
             "bar", app, env.root_path.to_s)

      config.excludes = ["foo", "bar"]
      subject.execute("foo")
    end

    it "sends custom server address" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", "-address", "foo", app, env.root_path.to_s)

      config.address = "foo"
      subject.execute("foo")
    end

    it "sends custom token" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", "-token", "atlas_token", app, env.root_path.to_s)

      config.token = "atlas_token"
      subject.execute("foo")
    end
  end

  describe "#uploader_path" do
    it "should return the configured path if set" do
      config.uploader_path = "foo"
      expect(subject.uploader_path).to eq("foo")
    end

    it "should look up the uploader via PATH if not set" do
      allow(Vagrant).to receive(:in_installer?).and_return(false)

      expect(Vagrant::Util::Which).to receive(:which).
        with(described_class.const_get(:UPLOADER_BIN)).
        and_return("bar")

      expect(subject.uploader_path).to eq("bar")
    end

    it "should look up the uploader in the embedded dir if installer" do
      dir = temporary_dir

      allow(Vagrant).to receive(:in_installer?).and_return(true)
      allow(Vagrant).to receive(:installer_embedded_dir).and_return(dir.to_s)

      bin_path = dir.join("bin", bin)
      bin_path.dirname.mkpath
      bin_path.open("w+") { |f| f.write("hi") }

      expect(subject.uploader_path).to eq(bin_path.to_s)
    end

    it "should look up the uploader in the PATH if not in the installer" do
      dir = temporary_dir

      allow(Vagrant).to receive(:in_installer?).and_return(true)
      allow(Vagrant).to receive(:installer_embedded_dir).and_return(dir.to_s)

      expect(Vagrant::Util::Which).to receive(:which).
        with(described_class.const_get(:UPLOADER_BIN)).
        and_return("bar")

      expect(subject.uploader_path).to eq("bar")
    end

    it "should return nil if its not found anywhere" do
      allow(Vagrant).to receive(:in_installer?).and_return(false)
      allow(Vagrant::Util::Which).to receive(:which).and_return(nil)

      expect(subject.uploader_path).to be_nil
    end
  end
end
