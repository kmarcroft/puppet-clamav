# frozen_string_literal: true

require 'spec_helper'

describe 'clamav::clamonacc', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "class { 'clamav': manage_clamd => true, manage_on_access => true }"
      end

      # ------------------------------------------------------------------ #
      # Default behaviour                                                   #
      # ------------------------------------------------------------------ #
      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/systemd/system/clamonacc.service') }
        it { is_expected.to contain_service('clamonacc').with_ensure('running').with_enable(true) }

        it {
          is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
            .with_owner('root')
            .with_group('root')
            .with_mode('0644')
        }

        it {
          is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
            .with_content(%r{managed by Puppet})
        }

        # --fdpass must appear on ExecStart by default (clamd runs as non-root)
        it {
          is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
            .with_content(%r{ExecStart=.* --fdpass})
        }

        # --foreground is required for Type=simple systemd units
        it {
          is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
            .with_content(%r{--foreground})
        }

        if facts[:os]['family'] == 'RedHat'
          it {
            is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
              .with_content(%r{--config-file=/etc/clamd\.d/scan\.conf})
          }
          it {
            is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
              .with_content(%r{After=clamd@scan\.service})
          }
          it {
            is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
              .with_content(%r{Requires=clamd@scan\.service})
          }
        else
          it {
            is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
              .with_content(%r{--config-file=/etc/clamav/clamd\.conf})
          }
          it {
            is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
              .with_content(%r{After=clamav-daemon\.service})
          }
          it {
            is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
              .with_content(%r{Requires=clamav-daemon\.service})
          }
        end

        # The unit file should subscribe the service so it restarts on change
        it {
          is_expected.to contain_service('clamonacc')
            .that_subscribes_to('File[/etc/systemd/system/clamonacc.service]')
        }
      end

      # ------------------------------------------------------------------ #
      # fdpass => false                                                     #
      # ------------------------------------------------------------------ #
      context 'with fdpass => false' do
        let(:pre_condition) do
          "class { 'clamav': manage_clamd => true, manage_on_access => true, clamonacc_fdpass => false }"
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/etc/systemd/system/clamonacc.service')
            .without_content(%r{ExecStart=.* --fdpass})
        }
      end

      # ------------------------------------------------------------------ #
      # Service state overrides                                             #
      # ------------------------------------------------------------------ #
      context 'with service stopped and disabled' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_clamd              => true,
            manage_on_access          => true,
            clamonacc_service_ensure  => 'stopped',
            clamonacc_service_enable  => false,
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('clamonacc').with_ensure('stopped').with_enable(false) }
      end

      # ------------------------------------------------------------------ #
      # Ordering                                                            #
      # ------------------------------------------------------------------ #
      context 'ordering: clamd before clamonacc' do
        it {
          is_expected.to contain_class('clamav::clamd')
            .that_comes_before('Class[clamav::clamonacc]')
        }
      end
    end
  end
end
