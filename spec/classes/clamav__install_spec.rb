# frozen_string_literal: true

require 'spec_helper'

describe 'clamav::install', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) { 'include clamav' }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('clamav').with_ensure('installed') }
        it { is_expected.to contain_package('clamav').with_name('clamav') }
      end

      context 'with a specific clamav_version' do
        let(:pre_condition) do
          "class { 'clamav': clamav_version => '1.0.0' }"
        end

        it { is_expected.to contain_package('clamav').with_ensure('1.0.0') }
      end

      context 'with a custom clamav_package name' do
        let(:pre_condition) do
          "class { 'clamav': clamav_package => 'clamav-server' }"
        end

        it { is_expected.to contain_package('clamav').with_name('clamav-server') }
      end
    end
  end
end
