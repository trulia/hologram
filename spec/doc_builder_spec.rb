require 'spec_helper'

describe Hologram::DocBuilder do
  subject(:builder) { Hologram::DocBuilder.new }

  context '#init' do
    around do |example|
      Hologram::DisplayMessage.quiet!
      example.run
      Hologram::DisplayMessage.show!
    end

    context 'when passed an invalid config' do
      before do
        File.open('bad_config.yml', 'w'){ |io| io << '%' }
      end

      after do
        FileUtils.rm('bad_config.yml')
      end

      it 'exits the process' do
        expect { builder.init(['bad_config.yml']) }.to raise_error SystemExit
      end
    end

    context 'when passed a config file' do
      let(:style_files) { Dir[File.expand_path('../fixtures/styleguide/**/*.*', __FILE__)] }
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

      before do
        builder.init([config_copy_path])
      end

      it 'builds a styleguide' do
        processed_files = Dir[File.join('.', '**/*.*')]
        processed_files.each_with_index do |file, index|
          expect(FileUtils.cmp(file, style_files[index])).to be_true
        end
      end
    end

    context 'when passed "init" as arg' do
      around do |example|
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            example.run
          end
        end
      end

      before do
        builder.init(['init'])
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
          builder.init(['init'])
          expect(IO.read('hologram_config.yml')).to eql('foo')
        end
      end
    end
  end
end
