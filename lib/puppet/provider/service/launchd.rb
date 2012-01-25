require 'facter/util/plist'
Puppet::Type.type(:service).provide :launchd, :parent => :base do
  desc <<-EOT
    This provider manages jobs with `launchd`, which is the default service
    framework for Mac OS X (and may be available for use on other platforms).

    For `launchd` documentation, see:

    * <http://developer.apple.com/macosx/launchd.html>
    * <http://launchd.macosforge.org/>

    This provider reads plists out of the following directories:

    * `/System/Library/LaunchDaemons`
    * `/System/Library/LaunchAgents`
    * `/Library/LaunchDaemons`
    * `/Library/LaunchAgents`

    ...and builds up a list of services based upon each plist's "Label" entry.

    This provider supports:

    * ensure => running/stopped,
    * enable => true/false
    * status
    * restart

    Here is how the Puppet states correspond to `launchd` states:

    * stopped --- job unloaded
    * started --- job loaded
    * enabled --- 'Disable' removed from job plist file
    * disabled --- 'Disable' added to job plist file

    Note that this allows you to do something `launchctl` can't do, which is to
    be in a state of "stopped/enabled" or "running/disabled".

  EOT

  include Puppet::Util::Warnings

  commands :launchctl => "/bin/launchctl"
  commands :sw_vers   => "/usr/bin/sw_vers"
  commands :plutil    => "/usr/bin/plutil"

  defaultfor :operatingsystem => :darwin
  confine :operatingsystem    => :darwin

  has_feature :enableable
  mk_resource_methods

  Launchd_Paths = [ "/Library/LaunchAgents",
                    "/Library/LaunchDaemons",
                    "/System/Library/LaunchAgents",
                    "/System/Library/LaunchDaemons"]

  Launchd_Overrides = "/var/db/launchd.db/com.apple.launchd/overrides.plist"
  
  # Caching is enabled through the following three methods. Self.prefetch will
  # call self.instances to create an instance for each service. Self.flush will
  # clear out our cache when we're done.
  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  # Self.instances will return an array with each element being a hash
  # containing the name, provider, path, and status of each service on the
  # system.
  def self.instances
    jobs = self.jobsearch
    @job_list ||= self.job_list
    jobs.keys.collect do |job|
      job_status = @job_list.has_key?(job) ? :running : :stopped
      new(:name => job, :provider => :launchd, :path => jobs[job], :status => job_status)
    end
  end

  # Sets a class instance variable with a hash of all launchd plist files that
  # are found on the system. The key of the hash is the job id and the value
  # is the path to the file. If a label is passed, we return the job id and
  # path for that specific job.
  def self.jobsearch(label=nil)
    @label_to_path_map ||= {}
    if @label_to_path_map.empty?
      Launchd_Paths.each do |path|
        Dir.glob(File.join(path,'*')).each do |filepath|
          next if ! File.file?(filepath)
          job = read_plist(filepath)
          if job.has_key?("Label") and job["Label"] == label
            return { label => filepath }
          else
            @label_to_path_map[job["Label"]] = filepath
          end
        end
      end
    end

    if label
      if @label_to_path_map.has_key? label
        return { label => @label_to_path_map[label] }
      else
        raise Puppet::Error.new("Unable to find launchd plist for job: #{label}")
      end
    else
      @label_to_path_map
    end
  end

  # This status method lists out all currently running services.
  # This hash is returned at the end of the method.
  def self.job_list
    @job_list = Hash.new
    begin
      output = launchctl :list
      raise Puppet::Error.new("launchctl list failed to return any data.") if output.nil?
      output.split("\n").each do |line|
        @job_list[line.split(/\s/).last] = :running
      end
    rescue Puppet::ExecutionFailure
      raise Puppet::Error.new("Unable to determine status of #{resource[:name]}")
    end
    @job_list
  end

  # Launchd implemented plist overrides in version 10.6.
  # This method checks the major_version of OS X and returns true if 
  # it is 10.6 or greater. This allows us to implement different plist
  # behavior for versions >= 10.6
  def has_macosx_plist_overrides?
    @product_version ||= self.class.get_macosx_version_major
    return true unless /^10\.[0-5]/.match(@product_version)
    return false
  end

  # Read a plist, whether its format is XML or in Apple's "binary1"
  # format.
  def self.read_plist(path)
    Plist::parse_xml(plutil('-convert', 'xml1', '-o', '/dev/stdout', path))
  end

  # Clean out the @property_hash variable containing the cached list of services
  def flush
    @property_hash.clear
  end

  def exists?
    Puppet.debug("Puppet::Provider::Launchd:Ensure for #{@property_hash[:name]}: #{@property_hash[:ensure]}")
    @property_hash[:ensure] != :absent
  end

  def self.get_macosx_version_major
    return @macosx_version_major if @macosx_version_major
    begin
      # Make sure we've loaded all of the facts
      Facter.loadfacts
      if Facter.value(:macosx_productversion_major)
        product_version_major = Facter.value(:macosx_productversion_major)
      else
        # TODO: remove this code chunk once we require Facter 1.5.5 or higher.
        warnonce("DEPRECATION WARNING: Future versions of the launchd provider will require Facter 1.5.5 or newer.")
        product_version = Facter.value(:macosx_productversion)
        fail("Could not determine OS X version from Facter") if product_version.nil?
        product_version_major = product_version.scan(/(\d+)\.(\d+)./).join(".")
      end
      fail("#{product_version_major} is not supported by the launchd provider") if %w{10.0 10.1 10.2 10.3}.include?(product_version_major)
      @macosx_version_major = product_version_major
      return @macosx_version_major
    rescue Puppet::ExecutionFailure => detail
      fail("Could not determine OS X version: #{detail}")
    end
  end


  # finds the path for a given label and returns the path and parsed plist
  # as an array of [path, plist]. Note plist is really a Hash here.
  def plist_from_label(label)
    job = self.class.jobsearch(label)
    job_path = job[label]
    if FileTest.file?(job_path)
      job_plist = self.class.read_plist(job_path)
    else
      raise Puppet::Error.new("Unable to parse launchd plist at path: #{job_path}")
    end
    [job_path, job_plist]
  end

  # start the service. To get to a state of running/enabled, we need to
  # conditionally enable at load, then disable by modifying the plist file
  # directly.
  def start
    job_path, job_plist = plist_from_label(resource[:name])
    did_enable_job = false
    cmds = []
    cmds << :launchctl << :load
    if self.enabled? == :false  # launchctl won't load disabled jobs
      cmds << "-w"
      did_enable_job = true
    end
    cmds << job_path
    begin
      execute(cmds)
    rescue Puppet::ExecutionFailure
      raise Puppet::Error.new("Unable to start service: #{resource[:name]} at path: #{job_path}")
    end
    # As load -w clears the Disabled flag, we need to add it in after
    self.disable if did_enable_job and resource[:enable] == :false
  end


  def stop
    job_path, job_plist = plist_from_label(resource[:name])
    did_disable_job = false
    cmds = []
    cmds << :launchctl << :unload
    if self.enabled? == :true # keepalive jobs can't be stopped without disabling
      cmds << "-w"
      did_disable_job = true
    end
    cmds << job_path
    begin
      execute(cmds)
    rescue Puppet::ExecutionFailure
      raise Puppet::Error.new("Unable to stop service: #{resource[:name]} at path: #{job_path}")
    end
    # As unload -w sets the Disabled flag, we need to add it in after
    self.enable if did_disable_job and resource[:enable] == :true
  end


  # launchd jobs are enabled by default. They are only disabled if the key
  # "Disabled" is set to true, but it can also be set to false to enable it.
  # Starting in 10.6, the Disabled key in the job plist is consulted, but only 
  # if there is no entry in the global overrides plist.
  # We need to draw a distinction between undefined, true and false for both
  # locations where the Disabled flag can be defined.
  def enabled?
    job_plist_disabled = nil
    overrides_disabled = nil

    job_path, job_plist = plist_from_label(resource[:name])
    job_plist_disabled = job_plist["Disabled"] if job_plist.has_key?("Disabled")

    if has_macosx_plist_overrides?
      if FileTest.file?(Launchd_Overrides) and overrides = self.class.read_plist(Launchd_Overrides)
        if overrides.has_key?(resource[:name])
          overrides_disabled = overrides[resource[:name]]["Disabled"] if overrides[resource[:name]].has_key?("Disabled")
        end
      end
    end

    if overrides_disabled.nil?
      if job_plist_disabled.nil? or job_plist_disabled == false
        return :true
      end
    elsif overrides_disabled == false
      return :true
    end
    :false
  end


  # enable and disable are a bit hacky. We write out the plist with the appropriate value
  # rather than dealing with launchctl as it is unable to change the Disabled flag
  # without actually loading/unloading the job.
  # Starting in 10.6 we need to write out a disabled key to the global 
  # overrides plist, in earlier versions this is stored in the job plist itself.
  def enable
    if has_macosx_plist_overrides?
      overrides = self.class.read_plist(Launchd_Overrides)
      overrides[resource[:name]] = { "Disabled" => false }
      Plist::Emit.save_plist(overrides, Launchd_Overrides)
    else
      job_path, job_plist = plist_from_label(resource[:name])
      if self.enabled? == :false
        job_plist.delete("Disabled")
        Plist::Emit.save_plist(job_plist, job_path)
      end
    end
  end


  def disable
    if has_macosx_plist_overrides?
      overrides = self.class.read_plist(Launchd_Overrides)
      overrides[resource[:name]] = { "Disabled" => true }
      Plist::Emit.save_plist(overrides, Launchd_Overrides)
    else
      job_path, job_plist = plist_from_label(resource[:name])
      job_plist["Disabled"] = true
      Plist::Emit.save_plist(job_plist, job_path)
    end
  end


end
