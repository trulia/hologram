require 'spec_helper'
require 'tempfile'

describe Hologram::DisplayMessage do
  subject(:display) { Hologram::DisplayMessage }

  #Rails kernerl helper
  def capture(stream)
    stream = stream.to_s
    captured_stream = Tempfile.new(stream)
    stream_io = eval("$#{stream}")
    origin_stream = stream_io.dup
    stream_io.reopen(captured_stream)

    yield

    stream_io.rewind
    return captured_stream.read
  ensure
    captured_stream.unlink
    stream_io.reopen(origin_stream)
  end

  context '.quiet!' do
    around do |example|
      display.quiet!
      example.run
      display.show!
    end

    it 'sets quiet to true' do
      display.quiet!
      expect(display.quiet?).to be_true
    end
  end

  context '.puts' do
    let(:message) { capture(:stdout) { display.puts('foo') } }

    it 'puts to console' do
      expect(message).to eql "foo\n"
    end

    context 'when quiet' do
      around do |example|
        display.quiet!
        example.run
        display.show!
      end

      it 'does nothing' do
        expect(message).to be_empty
      end
    end
  end

  context '.error' do
    around do |example|
      display.quiet!
      example.run
      display.show!
    end

    it 'displays an error in red' do
      expect(display).to receive(:puts).with("\e[32m(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}\e[0m\e[31m\u{FE35} \u{253B}\u{2501}\u{253B} \e[0m\e[31m Build not complete.\e[0m")
      expect(display).to receive(:puts).with(" foo")

      begin
        display.error('foo')
      rescue SystemExit
      end
    end

    it 'exits' do
      expect{ display.error('foo') }.to raise_error SystemExit
    end
  end

  context '.warning' do
    it 'displays a warning message in yellow' do
      expect(display).to receive(:puts).with("\e[33mWarning: foo\e[0m")
      display.warning('foo')
    end
  end

  context '.colorize' do
    it 'returns a colorized string' do
      expect(display.colorize(31, 'foo')).to eql "\e[31mfoo\e[0m"
    end
  end

  context '.red' do
    it 'returns a red colorized string' do
      expect(display.red('foo')).to eql display.colorize(31, 'foo')
    end
  end

  context '.green' do
    it 'returns a green colorized string' do
      expect(display.green('foo')).to eql display.colorize(32, 'foo')
    end
  end

  context '.yellow' do
    it 'returns a yellow colorized string' do
      expect(display.yellow('foo')).to eql display.colorize(33, 'foo')
    end
  end

  context '.pink' do
    it 'returns a pink colorized string' do
      expect(display.pink('foo')).to eql display.colorize(35, 'foo')
    end
  end
end
