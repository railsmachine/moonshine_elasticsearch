## Description

This plugin is consider **beta**, though it works for us. We've done a lot of testing on vagrant instances, but aren't currently managing any production clusters with it.

This plugin sets up an [elasticsearch](http://elasticsearch.org) cluster using unicast (since we've found multicast to be iffy).

## Installation

### Rails 2 

<pre><code>script/plugin install git://github.com/railsmachine/moonshine_elasticsearch.git --force</code></pre>

### Rails 3

<pre><code>script/rails plugin install git://github.com/railsmachine/moonshine_elasticsearch.git --force</code></pre>

### Rails 4

Make sure you have the plugger gem in your Gemfile and then run:

<pre><code>plugger install git://github.com/railsmachine/moonshine_mariadb.git --force</code></pre>

## Configuration

In your config/moonshine.yml:

<pre><code>:elasticsearch:
  :version: 0.90.12
  :cluster_name: mycluster</code></pre>
  
And then in your manifest:

<pre><code>recipe :elasticsearch</code></pre>

If you're using moonshine_multiserver, or have other servers that will need to access it (or use iptables), you'll need to set up the following rules:

* open 9200 for any server that needs access to the HTTP interface.
* open 9300 for any server that needs access to the TCP Transport interface (this include any elasticsearch servers in the cluster).

If you have multiple servers in your cluster, you'll also need to set <code>configuration[:elasticsearch][:unicast_hosts]</code> to an array that looks something like: <code>['10.0.1.2:9300', '10.0.1.3:9300']</code>.  That array should contain *all* the servers in the cluster.  You should probably also set <code>:listen_address</code> to the internal IP address for the server.

## Plugins

We now support installing plugins via manifests!  You just need to add the following to your manifest:

<pre><code>recipe :elasticsearch_plugins
  
def elasticsearch_plugins
  
  elasticsearch_plugin path: "elasticsearch/elasticsearch-analysis-phonetic/2.0.0.RC1", 
    provides: "analysis-phonetic"
    
end</code></pre>

The <code>provides</code> option should be the directory it creates in /usr/share/elasticsearch/plugins.

The <code>elasticsearch_plugin</code> method also supports an <code>url</code> option if you need to download the plugin from somewhere else (usually for third-party plugins).
