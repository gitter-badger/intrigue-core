require 'rubygems'
require 'json'
require 'rest_client'

class IntrigueApi

    def initialize(uri="http://localhost:7777/v1",key="")
      @intrigue_basedir = File.dirname(__FILE__)
      @server_uri = uri
      @server_key = key
    end

    # List all tasks
    def list
      tasks_hash = JSON.parse(RestClient.get("#{@server_uri}/tasks.json"))
    end

    # Show detailed about a task
    def info(task_name)

      begin
        task_info = JSON.parse(RestClient.get("#{@server_uri}/tasks/#{task_name}.json"))
      rescue RestClient::InternalServerError => e
        raise "Invalid Task Called"
      end

    end

    # start_and_background - start and background a task
    #
    # entity_hash = {
    #  :type => "String"
    #  :attributes => { :name => "intrigue.io"}
    # }
    #
    # options_list = [
    #   {:name => "resolver", :value => "8.8.8.8" }
    # ]
    def start_and_background(task_name,entity_hash,options_list=nil)

      payload = {
        :task => task_name,
        :options => options_list,
        :entity => entity_hash
      }

      ### Send to the server
      task_id = RestClient.post "#{@server_uri}/task_runs",
                    payload.to_json, :content_type => "application/json"

    task_id
    end

    # start Start a task and wait for the result
    def start(task_name,entity_hash,options_list=nil)

      # Construct the request
      task_id = start_and_background(task_name,entity_hash,options_list)

      if task_id == "" # technically a nil is returned , but becomes an empty string
        puts "[-] Task not started. Unknown Error. Exiting"
        return
      end

      ### XXX - wait to collect the response
      complete = false
      until complete
        sleep 1
        begin
          uri = "#{@server_uri}/task_runs/#{task_id}/complete"
          complete = true if(RestClient.get(uri) == "true")
        rescue URI::InvalidURIError => e
          puts "[-] Invalid URI: #{uri}"
          return
        end
      end

      ### Get the response
      begin
        response = JSON.parse(RestClient.get "#{@server_uri}/task_runs/#{task_id}.json")
      rescue JSON::ParserError => e
        response = nil
      end
    response
    end

    def get_log(task_id)
      log = RestClient.get "#{@server_uri}/task_runs/#{task_id}/log"
    end

    def get_result(task_id)
      begin
        result = JSON.parse(RestClient.get "#{@server_uri}/task_runs/#{task_id}.json")
      rescue JSON::ParserError => e
        response = nil
      end
    result
    end


end


###
### SAMPLE USAGE
###

=begin
x =  Intrigue.new

  #
  # Create an entity hash, must have a :type key
  # and (in the case of most tasks)  a :attributes key
  # with a hash containing a :name key (as shown below)
  #
  entity = {
    :type => "String",
    :attributes => { :name => "intrigue.io"}
  }

  #
  # Create a list of options (this can be empty)
  #
  options_list = [
    { :name => "resolver", :value => "8.8.8.8" }
  ]

x.start "example", entity_hash, options_list
id  = x.start "search_bing", entity_hash, options_list
puts x.get_log id
puts x.get_result id

=end
