---


---

<h1 id="opentext-opsbridge-service-discovery-sample-scripts">OpenText OpsBridge Service Discovery (Sample scripts)</h1>
<p>Sample scripts of Service Discovery Templates. With these we discover Running Software with the OA!</p>
<p>This repo contains sample scripts to be used freely and let the Operations Agent from OpsBridge discover new CIs for the RTSM. This readme will explain one example named “sd_wsusGroups”, to get you up-to-speed!</p>
<h2 id="basis-principles">Basis Principles</h2>
<p>The Service Discovery done by the OA must meet certain criteria. By keeping that in mind the disovery can run smoothly.</p>
<ul>
<li>Service Auto-Discovery Template (default input, with(out) parameters and custom script)</li>
<li>Script that can be run by the OA. So rights and libraries exist on the agent the script will be run on.</li>
<li>The new CI-data must be in the standard output (console/stdout). The “agtrep”-subagent of the OA will pickup the data and sends it to the RTSM.</li>
</ul>
<blockquote>
<p>The sample scripts are all Perl-based, but any script that the OA can start on an OS can be used.</p>
</blockquote>
<h2 id="a-script-explained">A script explained</h2>
<p>In this section, we refer and explain the script named “sd_wsusGroups.pl” with the complementairy “sd_wsusGroups” Service Auto-Discovery template. These are combined in the Content Pack, also available in this repo.</p>
<h3 id="libraries">Libraries</h3>
<pre><code>#!/usr/bin/perl
use lib '/opt/OV/nonOV/perl/a/lib/curr';
use OvParam;
use strict;
use warnings;
</code></pre>
<p>These libraries are default for Perl. The first-two are OA specific and activate special commands/parameters of the OA.</p>
<h3 id="parameters">Parameters</h3>
<pre><code>my  $t = new OvParam::Template();
$t-&gt;Load("sd_WsusGroups", "svcdisctmpl");
my  $paramFP = $t-&gt;GetSimpleParameter("FILEPATH");
my  $paramAT = $t-&gt;GetSimpleParameter("ATTRIBUTE");
my  $filePath = $paramFP-&gt;GetValue();
my  $cmdbAttribute = $paramAT-&gt;GetValue();
</code></pre>
<p>This set of code enable us to use parameters within the script. The Service Auto-Discovery template has two (or more) parameters, in this case we use “FILEPATH” and “ATTRIBUTE” from it.  This is how they look like within the policy:<br>
<img src="https://github.com/novalytics/opsbridge-service-discovery-samples/blob/main/images/Screenshot-06.png?raw=true" alt="enter image description here"></p>
<h3 id="global-variables">Global Variables</h3>
<pre><code>my  @csvContent = ();
</code></pre>
<p>This section describes the global variables used in the script. This variable for instance, is used in the next function/sub.</p>
<h3 id="getfile">GetFile</h3>
<pre><code>sub getFile {
    my  $fh;
    unless (open  $fh, "&lt;:encoding(utf8)", $filePath) {
        print  STDERR  "Could not open file '$filePath': $!\n";
        # we return 'undefined', we could also 'die' or 'croak'
        return  undef
    }

    chomp(@csvContent = &lt;$fh&gt;);
    unless (close  $fh) {
        # what does it mean if close yields an error and you are just reading?
        print  STDERR  "Don't care error while closing '$filePath': $!\n";
    }
}
</code></pre>
<p>This function grabs the file (from the PARAMETERS) and opens it, and puts the contents in the csvContent variable.</p>
<h3 id="push-discovery">Push Discovery</h3>
<p>This function sets the output for the new CI.</p>
<pre><code>sub  pushDiscovery {
	# Variables
    my  @splitArray = ();
    my  $csvLine = "";
    my  $primaryNodename = "";
    my  $nodeName = "";
    my  $wsusGroup = "";
</code></pre>
<p>The variables for this function.</p>
<pre><code># Populate the topology-file and write the &lt;Service&gt; tag
print  "&lt;Service&gt;\n";
</code></pre>
<p>The start of the new CI.</p>
<pre><code>while (defined($csvLine = shift  @csvContent)){
    @splitArray = split(",", $csvLine);
    $primaryNodename = $splitArray[0];
    $wsusGroup = $splitArray[1];
</code></pre>
<p>The ‘while’ function is used to loop through the data in the file. It is than splitted on the comma and put in the new Array ‘splitArray’. The line exists of 2 sets of data: 1: Nodename and 2: WSUS Group (Windows update group).</p>
<pre><code>if (($primaryNodename  ne  "") || ($wsusGroup  ne  ""))
{
    if (index($primaryNodename, ".") != -1) {
    $nodeName = substr($primaryNodename, 0, index($primaryNodename, '.'));
    } else {
    $nodeName = $primaryNodename;
    }
</code></pre>
<p>This if statement ensures that the used PrimaryNodeName and WSUS Group variables are not empty. Thereafter the PrimaryNodeName is checked if it is a FQDN or a hostname. If it is a FQDN, the content is splitted and only the hostname is put in the new nodeName variable.</p>
<pre><code>print  "\t&lt;NewInstance ref=\"HOST:$primaryNodename:$nodeName\"&gt;\n";
print  "\t\t&lt;Key&gt;HOST:$primaryNodename:$nodeName&lt;/Key&gt;\n";
print  "\t\t&lt;Std&gt;DiscoveredElement&lt;/Std&gt;\n";
print  "\t\t&lt;Attributes&gt;\n";
print  "\t\t\t&lt;Attribute name=\"hpom_citype\" value=\"nt\" /&gt;\n";
print  "\t\t\t&lt;Attribute name=\"ucmdb_name\" value=\"$nodeName\" /&gt;\n";
print  "\t\t\t&lt;Attribute name=\"ucmdb_primary_dns_name\" value=\"$primaryNodename\" /&gt;\n";
print  "\t\t\t&lt;Attribute name=\"$cmdbAttribute\" value=\"$wsusGroup\" /&gt;\n";
print  "\t\t&lt;/Attributes&gt;\n";
print  "\t&lt;/NewInstance&gt;\n";
</code></pre>
<p>This is the new CI. The attributes of the new CI and the KEY (connection to the topCI) are all here. This is the “nt” CI-type and the required attributes. The WSUS Group addition is added to the cmdbAttribute contents from the PARAMETERS.</p>
<pre><code># Close the file with the trailling &lt;Service&gt; tag
print  "&lt;/Service&gt;\n";
}
</code></pre>
<p>This is the closure of the new or updated CI.</p>

