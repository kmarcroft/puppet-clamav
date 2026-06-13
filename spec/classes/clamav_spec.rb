# frozen_string_literal: true

require 'spec_helper'

describe 'clamav', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      # ------------------------------------------------------------------ #
      # Default behaviour                                                   #
      # ------------------------------------------------------------------ #
      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('clamav::install') }
        it { is_expected.not_to contain_class('clamav::user') }
        it { is_expected.not_to contain_class('clamav::clamd') }
        it { is_expected.not_to contain_class('clamav::freshclam') }
        it { is_expected.not_to contain_class('clamav::clamav_milter') }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_class('epel') }
        else
          it { is_expected.not_to contain_class('epel') }
        end
      end

      # ------------------------------------------------------------------ #
      # manage_repo                                                         #
      # ------------------------------------------------------------------ #
      context 'with manage_repo => false' do
        let(:params) { { manage_repo: false } }

        it { is_expected.not_to contain_class('epel') }
      end

      context 'with manage_repo => true' do
        let(:params) { { manage_repo: true } }

        it { is_expected.to contain_class('epel') }
      end

      # ------------------------------------------------------------------ #
      # manage_user                                                         #
      # ------------------------------------------------------------------ #
      context 'with manage_user => true' do
        let(:params) { { manage_user: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('clamav::user') }
        # user class must precede install
        it { is_expected.to contain_class('clamav::user').that_comes_before('Class[clamav::install]') }
      end

      # ------------------------------------------------------------------ #
      # manage_clamd                                                        #
      # ------------------------------------------------------------------ #
      context 'with manage_clamd => true' do
        let(:params) { { manage_clamd: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('clamav::clamd') }
        it { is_expected.to contain_class('clamav::install').that_comes_before('Class[clamav::clamd]') }
      end

      # ------------------------------------------------------------------ #
      # manage_on_access                                                    #
      # ------------------------------------------------------------------ #
      context 'with manage_clamd => true and manage_on_access => true' do
        let(:params) { { manage_clamd: true, manage_on_access: true, on_access_paths: ['/home'] } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('clamav::clamd') }
      end

      # ------------------------------------------------------------------ #
      # manage_freshclam                                                    #
      # ------------------------------------------------------------------ #
      context 'with manage_freshclam => true' do
        let(:params) { { manage_freshclam: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('clamav::freshclam') }
        it { is_expected.to contain_class('clamav::install').that_comes_before('Class[clamav::freshclam]') }
      end

      # ------------------------------------------------------------------ #
      # manage_clamav_milter                                                #
      # ------------------------------------------------------------------ #
      context 'with manage_clamav_milter => true' do
        let(:params) { { manage_clamav_milter: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('clamav::clamav_milter') }
        it { is_expected.to contain_class('clamav::install').that_comes_before('Class[clamav::clamav_milter]') }
      end

      # ------------------------------------------------------------------ #
      # All components together                                             #
      # ------------------------------------------------------------------ #
      context 'with all components enabled' do
        let(:params) do
          {
            manage_user:          true,
            manage_clamd:         true,
            manage_freshclam:     true,
            manage_clamav_milter: true,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('clamav::user') }
        it { is_expected.to contain_class('clamav::install') }
        it { is_expected.to contain_class('clamav::clamd') }
        it { is_expected.to contain_class('clamav::freshclam') }
        it { is_expected.to contain_class('clamav::clamav_milter') }
      end

      # ------------------------------------------------------------------ #
      # clamav_package override                                             #
      # ------------------------------------------------------------------ #
      context 'with a custom clamav_package' do
        let(:params) { { clamav_package: 'clamav-custom' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('clamav').with_name('clamav-custom') }
      end

      # ------------------------------------------------------------------ #
      # clamd_options merge                                                 #
      # ------------------------------------------------------------------ #
      context 'with manage_clamd => true and custom clamd_options' do
        let(:params) do
          {
            manage_clamd:  true,
            clamd_options: { 'MaxThreads' => 24 },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('clamd.conf').with_content(%r{MaxThreads 24}) }
      end

      # ------------------------------------------------------------------ #
      # Parameter type validation                                           #
      # ------------------------------------------------------------------ #
      context 'with invalid manage_clamd type' do
        let(:params) { { manage_clamd: 'yes' } }

        it { is_expected.to compile.and_raise_error(%r{}) }
      end
    end
  end
end
