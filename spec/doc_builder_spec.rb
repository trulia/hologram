require 'spec_helper'

describe Hologram::DocBuilder do
  subject(:builder) { Hologram::DocBuilder }

  around do |example|
    Hologram::DisplayMessage.quiet!
    example.run
    Hologram::DisplayMessage.show!
  end

  context '.from_yaml' do
    subject(:builder) { Hologram::DocBuilder }
    let(:spec_root)   { File.expand_path('../', __FILE__) }
    let(:tmpdir)      { @tmpdir }

    around do |example|
      Dir.mktmpdir do |tmpdir|
        @tmpdir = tmpdir
        current_dir = Dir.pwd

        begin
          Dir.chdir(tmpdir)
          example.run
        ensure
          Dir.chdir(current_dir)
        end
      end
    end

    context 'when passed a valid config file' do
      let(:config_path) { File.join(spec_root, 'fixtures/source/config.yml') }
      let(:config_copy_path) { File.join(spec_root, 'fixtures/source/config.yml.copy') }

      before do
        FileUtils.cp(config_path, config_copy_path)
        File.open(config_copy_path, 'a'){ |io| io << "destination: #{tmpdir}" }
      end
      after do
        FileUtils.rm(config_copy_path)
      end

      it 'returns a DocBuilder instance' do
        expect(subject.from_yaml(config_copy_path)).to be_a Hologram::DocBuilder
      end
    end

    context 'when passed an invalid config' do
      before do
        File.open('bad_config.yml', 'w'){ |io| io << '%' }
      end

      after do
        FileUtils.rm('bad_config.yml')
      end

      it 'exits the process' do
        expect { subject.from_yaml('bad_config.yml') }.to raise_error SyntaxError
      end
    end

    context 'when source option is an array' do
      let(:config_path) { File.join(spec_root, 'fixtures/source/config_multi_source.yml') }
      let(:config_copy_path) { File.join(spec_root, 'fixtures/source/config_multi_source.yml.copy') }

      before do
        FileUtils.cp(config_path, config_copy_path)
        File.open(config_copy_path, 'a'){ |io| io << "destination: #{tmpdir}" }
      end
      after do
        FileUtils.rm(config_copy_path)
      end

      it 'returns a DocBuilder instance' do
        expect(subject.from_yaml(config_copy_path)).to be_a Hologram::DocBuilder
      end
    end

    context 'when dependencies is left blank' do
      let(:yaml) { "dependencies:\n" }

      before do
        File.open('fixable_bad_config.yml', 'w'){ |io| io << yaml }
      end

      after do
        FileUtils.rm('fixable_bad_config.yml')
      end

      it 'deletes the empty config variable' do
        builder = subject.from_yaml('fixable_bad_config.yml')
        expect(builder).to be_a Hologram::DocBuilder
        expect(builder.dependencies).to eql []
      end
    end
  end

  context '.setup_dir' do
    subject(:builder) { Hologram::DocBuilder }

    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          example.run
        end
      end
    end

    before do
      builder.setup_dir
    end

    it 'creates a config file' do
      expect(File.exists?('hologram_config.yml')).to be_true
    end

    it 'creates default assets' do
      Dir.chdir('doc_assets') do
        ['_header.html', '_footer.html'].each do |asset|
          expect(File.exists?(asset)).to be_true
        end
      end
    end

    context 'when a hologram_config.yml already exists' do
      it 'does nothing' do
        open('hologram_config.yml', 'w') {|io|io << 'foo'}
        builder.setup_dir
        expect(IO.read('hologram_config.yml')).to eql('foo')
      end
    end
  end

  context '#is_valid?' do

    let(:config) do
      {
        'source' => 'spec/fixtures/source/components',
        'documentation_assets' => 'spec/fixtures/source/templates',
        'base_path' => 'spec/fixtures/source/'
      }
    end

    let(:builder) { Hologram::DocBuilder.new(config) }

    around do |example|
      Dir.mktmpdir do |tmpdir|
        config['destination'] = tmpdir
        example.run
      end
    end

    context 'when config vars are present and directories exists' do
      it 'returns true' do
        expect(builder.is_valid?).to be_true
      end
    end

    ['source', 'destination', 'documentation_assets'].each do |config_var|
      context "when the required #{config_var} parameter is missing" do
        before do
          config.delete(config_var)
        end

        it 'returns false' do
          expect(builder.is_valid?).to be_false
        end

        it 'populates errors' do
          builder.is_valid?
          expect(builder.errors.size).to eql 1
        end
      end
    end

    context 'when the source directory does not exist' do
      before do
        config['source'] = './foo'
      end

      it 'returns false' do
        expect(builder.is_valid?).to be_false
      end

      it 'populates errors' do
        builder.is_valid?
        expect(builder.errors.size).to eql 1
      end
    end

    context 'when source is an array' do
      let(:config) do
        {
          'source' => ['spec/fixtures/source/components', 'spec/fixtures/source/templates'],
          'documentation_assets' => 'spec/fixtures/source/templates',
          'base_path' => 'spec/fixtures/source/'
        }
      end

      it 'returns true' do
        expect(builder.is_valid?).to be_true
      end
    end
  end

  context '#build' do
    let(:style_files) { Dir[File.expand_path('../fixtures/styleguide/**/*.*', __FILE__)] }
    let(:processed_files) { Dir[File.join(builder.destination, '.', '**/*.*')] }
    let(:config_path) { File.join(Dir.pwd, 'spec/fixtures/source/config.yml') }
    let(:config_copy_path) { File.join(Dir.pwd, 'spec/fixtures/source/config.yml.copy') }
    let(:builder) { Hologram::DocBuilder.from_yaml(config_copy_path) }

    around do |example|
      Dir.mktmpdir do |tmpdir|
        FileUtils.cp(config_path, config_copy_path)
        File.open(config_copy_path, 'a'){ |io| io << "destination: #{tmpdir}" }
        current_dir = Dir.pwd
        Dir.chdir('spec/fixtures/source')

        example.run

        Dir.chdir(current_dir)
        FileUtils.rm(config_copy_path)
      end
    end

    it 'builds a styleguide' do
      builder.build
      style_files.each_with_index do |file, index|
        expect(FileUtils.cmp(file, processed_files[index])).to be_true
      end
    end
  end
end
