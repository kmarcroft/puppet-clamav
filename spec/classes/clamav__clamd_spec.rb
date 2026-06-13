# frozen_string_literal: true

require 'spec_helper'

describe 'clamav::clamd', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "class { 'clamav': manage_clamd => true }"
      end

      # ------------------------------------------------------------------ #
      # Default behaviour per OS family                                     #
      # ------------------------------------------------------------------ #
      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_package('clamd').with_name('clamd') }
          it { is_expected.to contain_file('clamd.conf').with_path('/etc/clamd.d/scan.conf') }
          it { is_expected.to contain_service('clamd').with_name('clamd@scan') }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{LocalSocket /var/run/clamd\.scan/clamd\.sock}) }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{User clamscan}) }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{DatabaseDirectory /var/lib/clamav}) }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{LogSyslog true}) }
        else
          it { is_expected.to contain_package('clamd').with_name('clamav-daemon') }
          it { is_expected.to contain_file('clamd.conf').with_path('/etc/clamav/clamd.conf') }
          it { is_expected.to contain_service('clamd').with_name('clamav-daemon') }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{LocalSocket /var/run/clamav/clamd\.ctl}) }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{User clamav}) }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{LogFile /var/log/clamav/clamav\.log}) }
          it { is_expected.to contain_file('clamd.conf').with_content(%r{LogRotate true}) }
        end

        it { is_expected.to contain_package('clamd').with_ensure('installed') }
        it { is_expected.to contain_file('clamd.conf').with_mode('0644') }
        it { is_expected.to contain_file('clamd.conf').with_owner('root') }
        it { is_expected.to contain_file('clamd.conf').with_group('root') }
        it { is_expected.to contain_service('clamd').with_ensure('running') }
        it { is_expected.to contain_service('clamd').with_enable(true) }

        # package must precede config file
        it { is_expected.to contain_package('clamd').that_comes_before('File[clamd.conf]') }
        # config file must notify service
        it { is_expected.to contain_service('clamd').that_subscribes_to('File[clamd.conf]') }
        it { is_expected.to contain_service('clamd').that_subscribes_to('Package[clamd]') }
      end

      # ------------------------------------------------------------------ #
      # Service state overrides                                             #
      # ------------------------------------------------------------------ #
      context 'with clamd service stopped and disabled' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamd         => true,
            clamd_service_ensure => 'stopped',
            clamd_service_enable => false,
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('clamd').with_ensure('stopped').with_enable(false) }
      end

      # ------------------------------------------------------------------ #
      # Custom package version                                              #
      # ------------------------------------------------------------------ #
      context 'with a specific clamd_version' do
        let(:pre_condition) do
          "class { 'clamav': manage_clamd => true, clamd_version => '0.103.0' }"
        end

        it { is_expected.to contain_package('clamd').with_ensure('0.103.0') }
      end

      # ------------------------------------------------------------------ #
      # Custom clamd_options                                                #
      # ------------------------------------------------------------------ #
      context 'with custom clamd_options' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamd  => true,
            clamd_options => {
              'MaxThreads'  => 32,
              'ExcludePath' => ['^/proc/', '^/sys/'],
              'DetectPUA'   => true,
            },
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{MaxThreads 32}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{ExcludePath \^/proc/}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{ExcludePath \^/sys/}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{DetectPUA true}) }
      end

      # ------------------------------------------------------------------ #
      # sort_options parameter                                              #
      # ------------------------------------------------------------------ #
      context 'with sort_options => false' do
        let(:pre_condition) { 'include clamav' }
        let(:params) { { sort_options: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamd.conf') }
      end

      # ------------------------------------------------------------------ #
      # Config file header                                                  #
      # ------------------------------------------------------------------ #
      context 'config file contains managed-by-puppet header' do
        it { is_expected.to contain_file('clamd.conf').with_content(%r{managed by Puppet}) }
      end

      # ------------------------------------------------------------------ #
      # On-access scanning                                                  #
      # ------------------------------------------------------------------ #
      context 'with manage_on_access => true and on_access_paths set' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamd     => true,
            manage_on_access => true,
            on_access_paths  => ['/home', '/tmp'],
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessIncludePath /home}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessIncludePath /tmp}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessPrevention false}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessExcludeRootUID true}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessMaxFileSize 5M}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessExcludePath /proc}) }
      end

      context 'with manage_on_access => true and on_access_paths explicitly empty' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamd     => true,
            manage_on_access => true,
            on_access_paths  => [],
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file('clamd.conf').with_content(%r{OnAccessIncludePath}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessPrevention false}) }
      end

      context 'with manage_on_access => true using whole-system default path' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamd     => true,
            manage_on_access => true,
            on_access_paths  => ['/'],
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessIncludePath /\b}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessExcludePath /proc}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessExcludePath /snap}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessDisableDDD true}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessPrevention false}) }
      end

      context 'with manage_on_access => true and OnAccessPrevention overridden' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamd      => true,
            manage_on_access  => true,
            on_access_paths   => ['/srv'],
            on_access_options => { 'OnAccessPrevention' => true },
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessPrevention true}) }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{OnAccessIncludePath /srv}) }
      end
    end
  end
end
