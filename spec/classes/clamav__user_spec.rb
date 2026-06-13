# frozen_string_literal: true

require 'spec_helper'

describe 'clamav::user', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "class { 'clamav': manage_user => true }"
      end

      context 'with defaults (manage_user => true)' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_group('clamav_group') }
        it { is_expected.to contain_user('clamav_user') }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_group('clamav_group').with_name('clamscan') }
          it { is_expected.to contain_user('clamav_user').with_name('clamscan') }
          it { is_expected.to contain_user('clamav_user').with_shell('/sbin/nologin') }
        else
          it { is_expected.to contain_group('clamav_group').with_name('clamav') }
          it { is_expected.to contain_user('clamav_user').with_name('clamav') }
          it { is_expected.to contain_user('clamav_user').with_shell('/usr/sbin/nologin') }
        end

        it { is_expected.to contain_group('clamav_group').with_system(true) }
        it { is_expected.to contain_user('clamav_user').with_system(true) }
        # group must be created before user
        it { is_expected.to contain_group('clamav_group').that_comes_before('User[clamav_user]') }
      end

      context 'with group unset' do
        let(:pre_condition) do
          "class { 'clamav': manage_user => true, group => undef }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_group('clamav_group') }
        it { is_expected.to contain_user('clamav_user') }
      end

      context 'with user unset' do
        let(:pre_condition) do
          "class { 'clamav': manage_user => true, user => undef }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_group('clamav_group') }
        it { is_expected.not_to contain_user('clamav_user') }
      end

      context 'with custom user and group' do
        let(:pre_condition) do
          "class { 'clamav':
            manage_user => true,
            user        => 'myclamav',
            group       => 'myclamav',
            uid         => 501,
            gid         => 501,
            home        => '/var/lib/clamav',
            shell       => '/sbin/nologin',
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_user('clamav_user').with_name('myclamav').with_uid(501) }
        it { is_expected.to contain_group('clamav_group').with_name('myclamav').with_gid(501) }
      end
    end
  end
end
