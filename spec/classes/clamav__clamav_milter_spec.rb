# frozen_string_literal: true

require 'spec_helper'

describe 'clamav::clamav_milter', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "class { 'clamav': manage_clamav_milter => true }"
      end

      # ------------------------------------------------------------------ #
      # Default behaviour per OS family                                     #
      # ------------------------------------------------------------------ #
      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('clamav_milter').with_name('clamav-milter') }
        it { is_expected.to contain_package('clamav_milter').with_ensure('installed') }
        it { is_expected.to contain_file('clamav-milter.conf').with_mode('0644') }
        it { is_expected.to contain_file('clamav-milter.conf').with_owner('root') }
        it { is_expected.to contain_file('clamav-milter.conf').with_content(%r{managed by Puppet}) }
        it { is_expected.to contain_file('clamav-milter.conf').with_content(%r{MilterSocket inet:8890@localhost}) }
        it { is_expected.to contain_service('clamav_milter').with_name('clamav-milter') }
        it { is_expected.to contain_service('clamav_milter').with_ensure('running') }
        it { is_expected.to contain_service('clamav_milter').with_enable(true) }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_file('clamav-milter.conf').with_path('/etc/mail/clamav-milter.conf') }
          it { is_expected.to contain_file('clamav-milter.conf').with_content(%r{User clamilt}) }
          it { is_expected.to contain_file('clamav-milter.conf').with_content(%r{ClamdSocket tcp:127\.0\.0\.1}) }
        else
          it { is_expected.to contain_file('clamav-milter.conf').with_path('/etc/clamav/clamav-milter.conf') }
          it { is_expected.to contain_file('clamav-milter.conf').with_content(%r{User clamav}) }
          it { is_expected.to contain_file('clamav-milter.conf').with_content(%r{ClamdSocket unix:/var/run/clamav/clamd\.ctl}) }
        end

        it { is_expected.to contain_package('clamav_milter').that_comes_before('File[clamav-milter.conf]') }
        it { is_expected.to contain_service('clamav_milter').that_subscribes_to('File[clamav-milter.conf]') }
        it { is_expected.to contain_service('clamav_milter').that_subscribes_to('Package[clamav_milter]') }
      end

      # ------------------------------------------------------------------ #
      # Service overrides                                                   #
      # ------------------------------------------------------------------ #
      context 'with milter service stopped and disabled' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamav_milter:         true,
            clamav_milter_service_ensure: 'stopped',
            clamav_milter_service_enable: false,
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('clamav_milter').with_ensure('stopped').with_enable(false) }
      end

      # ------------------------------------------------------------------ #
      # Custom options                                                      #
      # ------------------------------------------------------------------ #
      context 'with custom clamav_milter_options' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamav_milter:    true,
            clamav_milter_options:   { 'MilterSocket' => 'inet:8891@localhost' },
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamav-milter.conf').with_content(%r{MilterSocket inet:8891@localhost}) }
      end

      # ------------------------------------------------------------------ #
      # sort_options parameter                                              #
      # ------------------------------------------------------------------ #
      context 'with sort_options => false' do
        let(:pre_condition) do
          "class { 'clamav': manage_clamav_milter => true }"
        end
        let(:params) { { sort_options: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamav-milter.conf') }
      end
    end
  end
end
