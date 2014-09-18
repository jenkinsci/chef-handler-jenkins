require 'rspec'
require 'date'
require 'webmock/rspec'
require_relative '../files/default/jenkins_handler'

RSpec.configure do |config|
  config.mock_framework = :rspec
end

WebMock.disable_net_connect!(allow_localhost: true)

describe Chef::Handler::Jenkins do
  context 'no config url provided' do
    subject { Chef::Handler::Jenkins.new {} }

    it 'should fail with an exception' do
      expect { subject }.to raise_exception
    end
  end

  context 'dry run' do
    subject { Chef::Handler::Jenkins.new(url: 'http://www.example.com/', dryrun: true) }

    before(:example) do
      allow(subject).to receive(:run_status) do
        double('run_status', {node: double(name: 'my.test.node')})
      end

      allow(subject).to receive(:jenkins_report) do
        { test_data: 'this is a test report' }
      end
    end

    it 'should not submit data to jenkins' do
      expect(subject).to_not receive(:submit_to_jenkins)

      subject.report
    end

    it 'should create a file' do
      subject.report
      expect(::File.file? '/tmp/chef-handler-jenkins-dryrun.json').to be(true)
    end
  end

  context 'not a dry run' do
    subject { Chef::Handler::Jenkins.new(url: 'http://www.example.com/', dryrun: false) }

    before do
      @test_resource = double(path: 'spec/data/abc', action: :create)
      @test_resource_record = { path: 'spec/data/abc' }
    end

    context 'file resources' do
      before(:example) do
        allow(subject).to receive(:run_status) do
          abc_resource = Chef::Resource::File.new 'spec/data/abc'
          allow(abc_resource).to receive(:action).and_return :create

          def_resource = Chef::Resource::File.new 'spec/data/def'
          allow(def_resource).to receive(:action).and_return :create

          not_a_file_resource = double()

          double('run_status', updated_resources: [abc_resource, def_resource, not_a_file_resource],
                 node: double('node', name: 'my.test.node', environment: 'test.environment'),
                 start_time: DateTime.new(2014,04,1,12,0,0),
                 end_time: DateTime.new(2014,04,1,13,0,0))
        end
      end

      it 'should have updated resources' do
        expect(subject.run_status.updated_resources.length).to be(3)
      end

      it 'should filter resources for files' do
        expect(subject.updated_files.length).to be(2)
      end

      it 'should generate an envelope' do
        expect(subject.envelope).to include(node: 'my.test.node', environment: 'test.environment',
                                                    start_time: 'Tue, 01 Apr 2014 12:00:00 +0000',
                                                    end_time: 'Tue, 01 Apr 2014 13:00:00 +0000')
      end

      it 'should make a jenkins report' do
        expect(subject.jenkins_report).to eq({
          node: 'my.test.node',
          environment: 'test.environment',
          start_time: 'Tue, 01 Apr 2014 12:00:00 +0000',
          end_time: 'Tue, 01 Apr 2014 13:00:00 +0000',
          updates: [
            {
              path: 'spec/data/abc',
              action: :create,
              md5: '900150983cd24fb0d6963f7d28e17f72',
              type: 'File'
            },
            {
              path: 'spec/data/def',
              action: :create,
              md5: '614dd0e977becb4c6f7fa99e64549b12',
              type: 'File'
            }
          ]
        })
      end

      it 'should successfully submit to jenkins' do
        stub_request(:post, 'http://www.example.com/chef/report').to_return({status: 200})

        expect(subject.submit_to_jenkins('www.example.com', {})).to eq('200')
      end

      it 'should gracefully fail when submitting to jenkins' do
        stub_request(:post, 'http://www.example.com/chef/report').to_return({status: 403})

        expect(subject.submit_to_jenkins('www.example.com', {})).to eq('403')
      end
    end

    it 'should generate a resource_record' do
      expect(subject.resource_record(@test_resource)).to include(path: 'spec/data/abc', action: :create)
      expect(subject.resource_record(@test_resource)).to include(:type)
    end

    it 'should make a fingerprint' do
      expect(subject.fingerprint('spec/data/abc')).to eq('900150983cd24fb0d6963f7d28e17f72')
      expect(subject.fingerprint('spec/data/def')).to eq('614dd0e977becb4c6f7fa99e64549b12')
    end

    it 'should fingerprint a resource record' do
      expect(subject.fingerprint_resource_record(@test_resource_record)).to include(md5: '900150983cd24fb0d6963f7d28e17f72')
    end

    it 'should extract the host from the uri' do
      expect(subject.jenkins_host).to eq('www.example.com')
    end
  end
end
