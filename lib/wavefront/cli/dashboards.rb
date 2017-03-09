require 'wavefront/dashboards'
require 'wavefront/cli'
require 'pathname'
require 'json'
require 'yaml'

class Wavefront::Cli::Dashboards < Wavefront::Cli
  attr_accessor :wfd

  include Wavefront::Constants
  include Wavefront::Mixins

  def run
    @wfd = Wavefront::Dashboards.new(
      options[:token], options[:endpoint], options[:debug],
      { noop: options[:noop], verbose: options[:verbose] }
    )

    list_dashboards if options[:list]
    export_dash if options[:export]
    create_dash if options[:create]
    delete_dash if options[:delete]
    undelete_dash if options[:undelete]
    history_dash if options[:history]
    clone_dash if options[:clone]
    import_dash if options[:import]
  end

  def import_dash
    begin
      wfd.import(load_file(options[:'<file>']).to_json, options[:force])
      puts 'Dashboard imported'
    rescue RestClient::BadRequest
      raise '400 error: dashboard probably exists, and force not used'
    end
  end

  def clone_dash
    begin
      wfd.clone(options[:source], options[:'<new_id>'],
                options[:'<new_name>'], options[:version])
      puts 'Dashboard cloned'
    rescue RestClient::BadRequest
      raise '400 error: either target exists or source does not'
    end
  end

  def history_dash
    begin
      resp = wfd.history(options[:'<dashboard_id>'],
                        options[:start] || nil,
                        options[:limit] || nil)
    rescue RestClient::ResourceNotFound
      raise 'Dashboard does not exist'
    end

    display_resp(resp, :human_history)
  end

  def undelete_dash
    begin
      resp = wfd.undelete(options[:'<dashboard_id>'])
      puts 'dashboard undeleted'
    rescue RestClient::ResourceNotFound
      raise 'Dashboard does not exist'
    end
  end

  def delete_dash
    begin
      resp = wfd.delete(options[:'<dashboard_id>'])
      puts 'dashboard deleted'
    rescue RestClient::ResourceNotFound
      raise 'Dashboard does not exist'
    end
  end

  def create_dash
    begin
      resp = wfd.create(options[:'<dashboard_id>'], options[:'<name>'])
      puts 'dashboard created'
    rescue RestClient::BadRequest
      raise '400 error: dashboard probably exists'
    end
  end

  def export_dash
    resp = wfd.export(options[:'<dashboard_id>'], options[:version] || nil)
    options[:dashformat] = :json if options[:dashformat] == :human
    display_resp(resp)
  end

  def list_dashboards
    resp = wfd.list({ private: options[:privatetag],
                      shared: options[:sharedtag]}, options)
    display_resp(resp, :human_list)
  end

  def display_resp(resp, human_method = nil)
    case options[:dashformat].to_sym
    when :json
      puts resp
    when :yaml
      puts resp.to_yaml
    when :human
      if human_method
        self.send(human_method, JSON.parse(resp))
      else
        raise 'human output format is not supported by this subcommand'
      end
    else
      raise 'unsupported output format'
    end
  end

  def human_history(resp)
    resp.each do |rev|
      puts ('%-4s%s (%s)' % [rev['version'],
                             Time.at(rev['update_time'].to_i / 1000),
                             rev['update_user']])

      next unless rev['change_description']
      rev['change_description'].each { |desc| puts '      ' + desc }
    end
  end

  def human_list(resp)
    #
    # Simply list the dashboards we have. If the user wants more
    #
    max_id_width = resp.map{ |s| s['url'].size }.max

    puts ("%-#{max_id_width + 1}s%s" % ['ID', 'NAME'])

    resp.each do |dash|
      next if !options[:all] && dash['isTrash']
      line = "%-#{max_id_width + 1}s%s" % [dash['url'], dash['name']]
      line.<< ' (in trash)' if dash['isTrash']
      puts line
    end
  end
end
