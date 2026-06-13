# frozen_string_literal: true

require 'spec_helper'

describe 'clamav::freshclam', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "class { 'clamav': manage_freshclam => true }"
      end

      # ------------------------------------------------------------------ #
      # Default behaviour per OS family                                     #
      # ------------------------------------------------------------------ #
      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('freshclam.conf') }
        it { is_expected.to contain_file('freshclam.conf').with_mode('0644') }
        it { is_expected.to contain_file('freshclam.conf').with_content(%r{managed by Puppet}) }
        it { is_expected.to contain_file('freshclam.conf').with_content(%r{DatabaseDirectory /var/lib/clamav}) }
        it { is_expected.to contain_file('freshclam.conf').with_content(%r{DatabaseMirror database\.clamav\.net}) }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_package('freshclam').with_name('clamav-update') }
          it { is_expected.to contain_file('freshclam.conf').with_path('/etc/freshclam.conf') }
          it { is_expected.to contain_service('freshclam').with_name('clamav-freshclam') }
          it { is_expected.to contain_file('freshclam_sysconfig').with_path('/etc/sysconfig/freshclam') }
          it { is_expected.to contain_file('freshclam_sysconfig').with_content(%r{managed by Puppet}) }
          it { is_expected.to contain_file('freshclam.conf').with_content(%r{DatabaseOwner clamupdate}) }
          it { is_expected.to contain_file('freshclam.conf').with_content(%r{NotifyClamd /etc/clamd\.d/scan\.conf}) }
        else
          it { is_expected.to contain_package('freshclam').with_name('clamav-freshclam') }
          it { is_expected.to contain_file('freshclam.conf').with_path('/etc/clamav/freshclam.conf') }
          it { is_expected.to contain_service('freshclam').with_name('clamav-freshclam') }
          it { is_expected.not_to contain_file('freshclam_sysconfig') }
          it { is_expected.to contain_file('freshclam.conf').with_content(%r{DatabaseOwner clamav}) }
          it { is_expected.to contain_file('freshclam.conf').with_content(%r{PidFile /var/run/clamav/freshclam\.pid}) }
          it { is_expected.to contain_file('freshclam.conf').with_content(%r{UpdateLogFile /var/log/clamav/freshclam\.log}) }
        end

        it { is_expected.to contain_service('freshclam').with_ensure('running') }
        it { is_expected.to contain_service('freshclam').with_enable(true) }
        it { is_expected.to contain_service('freshclam').that_subscribes_to('File[freshclam.conf]') }
        it { is_expected.to contain_package('freshclam').that_comes_before('File[freshclam.conf]') }
      end

      # ------------------------------------------------------------------ #
      # freshclam_delay (sysconfig) on RedHat                              #
      # ------------------------------------------------------------------ #
      if facts[:os]['family'] == 'RedHat'
        context 'with freshclam_delay set' do
          let(:pre_condition) do
            "class { 'clamav': manage_freshclam => true, freshclam_delay => 'disabled' }"
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('freshclam_sysconfig').with_content(%r{FRESHCLAM_DELAY=disabled}) }
        end
      end

      # ------------------------------------------------------------------ #
      # Service stopped/disabled                                            #
      # ------------------------------------------------------------------ #
      context 'with freshclam service stopped and disabled' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_freshclam         => true,
            freshclam_service_ensure => 'stopped',
            freshclam_service_enable => false,
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('freshclam').with_ensure('stopped').with_enable(false) }
      end

      # ------------------------------------------------------------------ #
      # No package when freshclam_package is undef                         #
      # ------------------------------------------------------------------ #
      context 'with freshclam_package => undef' do
        let(:pre_condition) do
          "class { 'clamav': manage_freshclam => true, freshclam_package => undef }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package('freshclam') }
        it { is_expected.to contain_file('freshclam.conf') }
      end

      # ------------------------------------------------------------------ #
      # No service when freshclam_service is undef                         #
      # ------------------------------------------------------------------ #
      context 'with freshclam_service => undef' do
        let(:pre_condition) do
          "class { 'clamav': manage_freshclam => true, freshclam_service => undef }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_service('freshclam') }
        it { is_expected.to contain_file('freshclam.conf') }
      end

      # ------------------------------------------------------------------ #
      # Custom freshclam_options                                            #
      # ------------------------------------------------------------------ #
      context 'with custom freshclam_options' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_freshclam  => true,
            freshclam_options => { 'Checks' => 12 },
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('freshclam.conf').with_content(%r{Checks 12}) }
      end

      # ------------------------------------------------------------------ #
      # Custom config file ownership                                        #
      # ------------------------------------------------------------------ #
      context 'with custom config_owner and config_group' do
        let(:pre_condition) { 'include clamav' }
        let(:params) { { config_owner: 'clamav', config_group: 'clamav', config_mode: '0640' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('freshclam.conf').with_owner('clamav').with_group('clamav').with_mode('0640') }
      end
    end
  end
end
