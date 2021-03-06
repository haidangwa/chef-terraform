control 'Hashicorp gpg key' do
  title "Import Hashicorp's public gpg key"
  impact 0.8

  describe gpg_key('HashiCorp Security') do
    it { should be_imported }
  end

  describe gpg_signature(input('terraform_version')) do
    it { should be_valid }
  end
end
