module Moonshine
  module Elasticsearch
    
    def elasticsearch
      recipe :elasticsearch_dependencies
      recipe :elasticsearch_package
      recipe :elasticsearch_config
      recipe :elasticsearch_service
    end

    def elasticsearch_dependencies
      package 'openjdk-6-jdk', 
        :ensure => :absent

      package 'python-software-properties',
        :ensure => :installed

      package 'curl',
        :ensure => :installed

      exec 'java add repo',
        :command => 'add-apt-repository ppa:webupd8team/java',
        :user => 'root',
        :require => package('python-software-properties'),
        :unless => 'ls /etc/apt/sources.list.d/ | grep webupd8team-java-lucid.list'

      file '/tmp/java.preseed',
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates',"java.preseed")),
        :ensure => :exists

      exec 'java apt-get update',
        :command => 'apt-get update',
        :user => 'root',
        :require => exec('java add repo'),
        :unless => oracle_java7_check

      exec 'java set selections',
        :command => 'debconf-set-selections /tmp/java.preseed',
        :user => 'root',
        :require => [file('/tmp/java.preseed')],
        :unless => oracle_java7_check

      exec 'accept java license',
        :command => "echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections",
        :user => 'root',
        :require => [exec('java apt-get update')],
        :unless => oracle_java7_check

      exec 'see java license',
        :command => "echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections",
        :user => 'root',
        :require => [exec('java apt-get update')],
        :unless => oracle_java7_check

      package 'oracle-java7-installer',
        :ensure => :installed,
        :require => [exec('java apt-get update'), exec('java set selections'), exec('accept java license'), exec('see java license')]

      package 'oracle-java7-set-default',
        :ensure => :installed,
        :require => [exec('java apt-get update'), package('oracle-java7-installer')]

    end

    def oracle_java7_check
      "sudo dpkg -l | grep 'ii  oracle-java7-installer'"
    end

    def elasticsearch_package

      version = configuration[:elasticsearch][:version] || '0.90.7'

      version.strip!

      exec "download elasticsearch",
        :command => "wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-#{version}.deb",
        :cwd => '/tmp',
        :user => 'root',
        :creates => "/tmp/elasticsearch-#{version}.deb"

      exec "install elasticsearch",
        :command => "dpkg -i --force-confdef ./elasticsearch-#{version}.deb",
        :cwd => '/tmp',
        :user => 'root',
        :creates => "/usr/share/elasticsearch/lib/elasticsearch-#{version}.jar",
        :require => [exec('download elasticsearch'), package('oracle-java7-installer'), file('/etc/init.d/elasticsearch')]

    end

    def elasticsearch_config

      file '/etc/init.d/elasticsearch',
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates','elasticsearch.initd.erb')),
        :ensure => :present,
        :owner => 'root',
        :mode => '0655',
        :notify => service('elasticsearch')

      file "/etc/elasticsearch",
        :ensure => :directory,
        :owner => 'root'

      file "/etc/elasticsearch/elasticsearch.yml",
        :ensure => :present,
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates','elasticsearch.yml.erb')),
        :owner => 'root',
        :require => [file('/etc/elasticsearch'), exec('install elasticsearch')],
        :notify => service('elasticsearch')

      file "/etc/elasticsearch/logging.yml",
        :ensure => :present,
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates',"logging.yml.erb")),
        :owner => 'root',
        :require => [file('/etc/elasticsearch'), exec('install elasticsearch')],
        :notify => service('elasticsearch')

      logrotate "/var/log/elasticsearch/*.log",
        :options => ['missingok', 'daily', 'compress', 'delaycompress', 'notifempty', 'copytruncate', 'rotate 7'],
        :postrotage => 'true'

    end

    def elasticsearch_service
      service 'elasticsearch',
        :ensure => :running,
        :require => [file("/etc/elasticsearch/elasticsearch.yml"), file("/etc/elasticsearch/logging.yml")],
        :provider => :init
    end
    
    def elasticsearch_config_boolean(key,default)
      if key.nil?
        default ? 'true' : 'false'
      else
        ((!!key) == true) ? 'true' : 'false'
      end
    end
    
  end
end