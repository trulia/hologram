require 'spec_helper'
require 'hologram/cli'

describe Hologram::CLI do
  context '#run' do
    context 'when arg is "init"' do
      subject(:cli) { Hologram::CLI.new('init') }

      it 'setups the dir' do
        Hologram::DocBuilder.should_receive(:setup_dir)
        cli.run
      end
    end

    context 'when arg is empty' do
      subject(:cli) { Hologram::CLI.new('') }
      subject(:builder) { double(Hologram::DocBuilder, is_valid?: true, build: true) }

      it 'builds the documentation' do
        Hologram::DocBuilder.should_receive(:from_yaml).and_return(builder)
        cli.run
      end
    end

    context 'when a config file is passed' do
      subject(:cli) { Hologram::CLI.new('test.yml') }
      subject(:builder) { double(Hologram::DocBuilder, is_valid?: true, build: true) }

      it 'builds the documentation' do
        Hologram::DocBuilder.should_receive(:from_yaml).with('test.yml').and_return(builder)
        cli.run
      end
    end
  end
end
