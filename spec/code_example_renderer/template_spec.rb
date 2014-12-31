require 'spec_helper'

describe Hologram::CodeExampleRenderer::Template do
  describe '#template' do
    subject { described_class.new(template_name).template }

    context 'when template_name is nil' do
      let(:template_name) { nil }
      it { is_expected.to be_nil }
    end

    context 'when template_name is not nil' do
      let(:template_name) { 'bar' }

      let(:custom_template_filename) { 'custom/bar.html.erb' }
      let(:default_template_filename) { 'cwd/../../template/code_example_templates/bar.html.erb' }

      before do
        allow(File).to receive(:dirname) { 'cwd/' }
        allow(File).to receive(:read).with(custom_template_filename) { 'custom template' }
        allow(File).to receive(:read).with(default_template_filename) { 'default template' }
      end

      context 'when path_to_custom_example_templates is defined' do
        before do
          described_class.path_to_custom_example_templates = 'custom/'
          allow(File).to receive(:file?).with(custom_template_filename) { has_custom_template? }
        end

        after do
          described_class.path_to_custom_example_templates = nil
        end

        context 'when a custom template exists' do
          let(:has_custom_template?) { true }
          it { is_expected.to eq 'custom template' }
        end

        context 'when a custom template does not exist' do
          let(:has_custom_template?) { false }
          it { is_expected.to eq 'default template' }
        end
      end

      context 'when a path_to_custom_example_templates is not defined' do
        it { is_expected.to eq 'default template' }
      end
    end
  end
end
