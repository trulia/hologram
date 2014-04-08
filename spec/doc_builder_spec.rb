require 'spec_helper'

describe Hologram::DocBuilder do
  subject(:builder) { Hologram::DocBuilder }

  context '.from_yaml' do
    subject(:builder) { Hologram::DocBuilder }

    context 'when passed a valid config file' do
      let(:config_path) { File.join(Dir.pwd, 'spec/fixtures/source/config.yml') }
      let(:config_copy_path) { File.join(Dir.pwd, 'spec/fixtures/source/config.yml.copy') }

      around do |example|
        Dir.mktmpdir do |tmpdir|
          FileUtils.cp(config_path, config_copy_path)
          File.open(config_copy_path, 'a'){ |io| io << "destination: #{tmpdir}" }
          current_dir = Dir.pwd
          Dir.chdir(tmpdir)

          example.run

          Dir.chdir(current_dir)
          FileUtils.rm(config_copy_path)
        end
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
        expect { subject.from_yaml('bad_config.yml') }.to raise_error SystemExit
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

  context '.validate_config' do
    let(:config) { { 'source' => 'foo', 'destination' => 'foo', 'documentation_assets' => 'foo' } }

    context 'when valid' do
      it 'raises nothing' do
        expect {
          subject.validate_config(config)
        }.to_not raise_error SystemExit
      end
    end

    context 'when missing source' do
      let(:invalid_config) { config.delete('source'); config }

      it 'exits' do
        expect {
          subject.validate_config(invalid_config)
        }.to raise_error SystemExit
      end
    end

    context 'when missing documentation_asset' do
      let(:invalid_config) { config.delete('documentation_assets'); config }

      it 'exits' do
        expect {
          subject.validate_config(invalid_config)
        }.to raise_error SystemExit
      end
    end

    context 'when missing destination' do
      let(:invalid_config) { config.delete('destination'); config }

      it 'exits' do
        expect {
          subject.validate_config(invalid_config)
        }.to raise_error SystemExit
      end
    end
  end

  context '.get_markdown_renderer' do
    subject(:builder) { Hologram::DocBuilder }

    around do |example|
      current_dir = Dir.pwd
      Dir.chdir('spec/fixtures/renderer')

      example.run

      Dir.chdir(current_dir)
    end

    context 'by default' do
      let(:markdown) { builder.get_markdown_renderer }

      it 'returns the standard hologram markdown renderer' do
        markdown.renderer.should be_a HologramMarkdownRenderer
      end
    end

    context 'when passed a valid custom renderer' do
      let(:markdown) { builder.get_markdown_renderer('valid_renderer.rb') }

      it 'returns the custom renderer' do
        expect(markdown.renderer).to be_a ValidRenderer
      end
    end

    context 'when passed an invalid custom renderer' do
      context 'expecting a class named as the upper camel cased version of the file name' do
        it 'exits' do
          expect {
            builder.get_markdown_renderer('invalid_renderer.rb')
          }.to raise_error SystemExit
        end
      end

      context 'expecting a filename.rb' do
        it 'exits' do
          expect {
            builder.get_markdown_renderer('foo')
          }.to raise_error SystemExit
        end
      end
    end
  end

  context '#build' do
    let(:style_files) { Dir[File.expand_path('../fixtures/styleguide/**/*.*', __FILE__)] }
    let(:config_path) { File.join(Dir.pwd, 'spec/fixtures/source/config.yml') }
    let(:config_copy_path) { File.join(Dir.pwd, 'spec/fixtures/source/config.yml.copy') }
    let(:builder) { Hologram::DocBuilder.from_yaml(config_copy_path) }

    around do |example|
      Hologram::DisplayMessage.quiet!
      Dir.mktmpdir do |tmpdir|
        FileUtils.cp(config_path, config_copy_path)
        File.open(config_copy_path, 'a'){ |io| io << "destination: #{tmpdir}" }
        current_dir = Dir.pwd
        Dir.chdir(tmpdir)

        example.run

        Dir.chdir(current_dir)
        FileUtils.rm(config_copy_path)
      end
      Hologram::DisplayMessage.show!
    end

    it 'builds a styleguide' do
      builder.build
      processed_files = Dir[File.join('.', '**/*.*')]
      processed_files.each_with_index do |file, index|
        expect(FileUtils.cmp(file, style_files[index])).to be_true
      end
    end
  end
end
