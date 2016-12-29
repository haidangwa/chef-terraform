# These are helper methods that can be used in this cookbook
# the Terraform namespace
require 'tmpdir'

module Terraform
  # Helpers belonging to the Terraform namespace
  module Helpers
    @base = nil
    @version = nil

    # Transform raw output of the checksum list into a Hash[filename, checksum].
    def raw_checksums_to_hash
      @base ||= URI.parse(node['terraform']['url_base'])
      @version ||= node['terraform']['version']
      raw_checksums = File.open(
        File.join(Dir.tmpdir, checksums_file),
        'r'
      ) do |file|
        file.read
      end
      Hash[
        raw_checksums.split("\n").map do |s|
          s.split.reverse
        end
      ]
    end

    def sigfile
      "#{checksums_file}.sig"
    end

    def checksums_file
      "terraform_#{node['terraform']['version']}_SHA256SUMS"
    end

    # import the Hashicorp GPG key
    def import_gpg_key
      return if key_imported?
      keyfile = File.join(Dir.tmpdir, 'hashicorp.asc')
      GPGME::Key.import(File.open(keyfile))
    end

    def key_imported?
      !GPGME::Key.find(:public, 'security@hashicorp.com', :sign).empty?
    end

    # verify the sha256sum file's signature
    # @return: Boolean
    def sig_verified?
      @version ||= node['terraform']['version']
      checksums = File.open(File.join(Dir.tmpdir, checksums_file), 'r')
      verified = false
      crypto = GPGME::Crypto.new
      signature = GPGME::Data.new(
        File.open(
          File.join(Dir.tmpdir, "terraform_#{@version}_SHA256SUMS.sig"),
          'rb'
        )
      )
      crypto.verify(signature, signed_text: checksums) do |sig|
        verified = sig.valid? &&
                   !(sig.expired_signature? ||
                   sig.expired_key? ||
                   sig.revoked_key? ||
                   sig.bad? ||
                   sig.no_key?
                    )
      end
      verified
    end

    # See https://coderanger.net/derived-attributes/
    # for why this is the way it is
    def terraform_url
      "#{node['terraform']['url_base']}/#{node['terraform']['version']}/" \
        "#{node['terraform']['zipfile']}" % { version: node['terraform']['version'] }
    end
  end
end

::Chef::Node.send(:include, Terraform::Helpers)
::Chef::Recipe.send(:include, Terraform::Helpers)
::Chef::Provider.send(:include, Terraform::Helpers)
::Chef::Resource.send(:include, Terraform::Helpers)