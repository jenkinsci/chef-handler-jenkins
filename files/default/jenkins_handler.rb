require "chef/log"
require 'digest/md5'
require 'chef/handler'
require 'openssl/digest'
require 'json'
require 'net/http'
require 'uri'

class Chef
  class Handler
    #noinspection RubyStringKeysInHashInspection
    class Jenkins < Chef::Handler
      JAVA_DATE_FORMAT = '%a, %d %b %Y %H:%M:%S %z'

      def initialize(config)
        @config = config
        Chef::Log.warn('DRY RUN: No data will be submitted to Jenkins') if @config[:dryrun]
        raise ArgumentError, 'Jenkins URL is not specified' unless @config[:url]
      end

      def report
        Chef::Log.info "Machine name: #{run_status.node.name}"

        report_data = jenkins_report

        if @config[:dryrun]
          Chef::Log.info("DRY RUN: Would have subitted the following data: #{JSON.pretty_generate report_data}") if @config[:dryrun]
          ::File.open('/tmp/chef-handler-jenkins-dryrun.json', 'w') do |file|
            file << JSON.pretty_generate(report_data)
          end
        else
          Chef::Log.info "Submitting run data to #{@config[:url]}: #{JSON.pretty_generate report_data}"
          submit_to_jenkins(jenkins_host, report_data)
        end
      end

      def jenkins_report
        envelope.merge({updates: updated_files.collect { |r| resource_record r }
                                              .collect { |r| fingerprint_resource_record r}})
      end

      def updates
        run_status.updated_resources
      end

      def updated_files
        updates.select { |resource| resource.kind_of?(Chef::Resource::File) && ::File.file?(resource.path) }
      end

      def resource_record(resource)
        {
          path: resource.path,
          action: resource.action,
          type: resource.class.name
        }
      end

      def fingerprint_resource_record(resource)
        resource.merge(md5: fingerprint(resource[:path]))
      end

      def envelope
        {
          node: run_status.node.name,
          environment: run_status.node.environment,
          start_time: run_status.start_time.strftime(JAVA_DATE_FORMAT),
          end_time: run_status.end_time.strftime(JAVA_DATE_FORMAT)
        }
      end

      def jenkins_host
        URI::split(@config[:url])[2]
      end

      def submit_to_jenkins(host, result)
        http = Net::HTTP.new(host)

        http.request_post('/chef/report', result.to_json, {'Content-Type' => 'application/json'}) do |res|
          if res.code != '200'
            Chef::Log.warn "Jenkins did not respond OK to the Chef report. The res code was #{res.code}.
                            The body was: #{res.body}"
          else
            Chef::Log.info 'The report has been submitted to Jenkins.'
          end
        end.code
      end

      def fingerprint(path)
        md5 = OpenSSL::Digest::MD5.new

        File.open(path) do |file|
          until file.eof? do
            md5 << file.read(2**20)
          end
        end

        md5.digest.unpack('H*').first
      end

      # Submit the tracking report as a databag
      #
      # @param [Chef::RunStatus] run_status
      # @param [Hash] report
      def submit_databag(run_status, env)
        # TODO: too expensive to load them. all we want to do is to check if databag exists
        #begin
        #  Chef::DataBag.load("jenkins")
        #rescue Net::HTTPServerException => e
        #  if e.response.code=="404"
        #    bag = Chef::DataBag.new
        #    bag.name "jenkins"
        #    bag.save
        #  end
        #end

        i = Chef::DataBagItem.new
        i.data_bag("jenkins")  # set the name

        id = run_status.node.name + '_' + run_status.end_time.strftime("%Y%m%d-%H%M%S")

        i.raw_data = env
        i.save id
      end
    end
  end
end
