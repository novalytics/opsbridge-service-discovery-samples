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
<h2 id="service-auto-discovery-template">Service Auto-Discovery Template</h2>
<p>The SADT has a default contents except for the script to start:<br>
First the only sections to edit:</p>
<pre><code>&lt;PROPERTY.ARRAY NAME="ConfigPairs"&gt;
	&lt;VALUE.ARRAY&gt;
    &lt;VALUE&gt;CommandLine=perl "$ACTION_DIR/sd_wsusGroups.pl" "%%FILEPATH%%" "%%ATTRIBUTE%%"&lt;/VALUE&gt;
    &lt;VALUE&gt;User=&lt;/VALUE&gt;
    &lt;VALUE&gt;Password=&lt;/VALUE&gt;
    &lt;/VALUE.ARRAY&gt;
&lt;/PROPERTY.ARRAY&gt;
</code></pre>
<p>This section contains twice in the default contents of the SADT. 1 Time for Unix based OSses and 1 for the Windows OS.</p>
<p>The complete contents of the template looks like this:</p>
<pre><code>&lt;AutoDiscPolicy progVERSION="X.05.00"&gt;
  &lt;Version&gt;1.0&lt;/Version&gt;
  &lt;Discover&gt;
    &lt;ManagedModules&gt;
      &lt;ManagementModule name="customdiscovery"&gt;
        &lt;Caption&gt;Custom-Discovery&lt;/Caption&gt;
        &lt;Description&gt;Module supporting custom discovery scripts&lt;/Description&gt;
        &lt;RootStd&gt;DiscoveredElement&lt;/RootStd&gt;
      &lt;/ManagementModule&gt;
    &lt;/ManagedModules&gt;
  &lt;/Discover&gt;
  &lt;Schedule&gt;
    &lt;Options&gt;
      &lt;Task&gt;EveryHour&lt;/Task&gt;
    &lt;/Options&gt;
    &lt;Time&gt;
      &lt;Minute&gt;%%MINUTE%%&lt;/Minute&gt;
    &lt;/Time&gt;
  &lt;/Schedule&gt;
  &lt;ManagementModuleElements NAME="customdiscovery"&gt;
    &lt;INSTANCE CLASSNAME="OV_ManagementModule"&gt;
      &lt;PROPERTY NAME="Name"&gt;
        &lt;VALUE&gt;customdiscovery&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="Caption"&gt;
        &lt;VALUE&gt;Custom-Discovery&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="Description"&gt;
        &lt;VALUE&gt;Module supporting custom discovery scripts&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="RootServiceTypeId"&gt;
        &lt;VALUE&gt;DiscoveredElement&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
    &lt;/INSTANCE&gt;
    &lt;INSTANCE CLASSNAME="OV_ServiceTypeDefinition"&gt;
      &lt;PROPERTY NAME="GUID"&gt;
        &lt;VALUE&gt;DiscoveredElement&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="Caption"&gt;
        &lt;VALUE&gt;Discovered Element&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="Description"&gt;
        &lt;VALUE&gt;service type used by custom discovery scripts&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="Name"&gt;
        &lt;VALUE&gt;DiscoveredElement&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="CaptionFormat"&gt;
        &lt;VALUE&gt;$caption$&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="DescriptionFormat"&gt;
        &lt;VALUE&gt;$description$&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="KeyFormat"&gt;
        &lt;VALUE&gt;$key$@@&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="CalcRuleId"&gt;
        &lt;VALUE&gt;DDK_DefaultCalculationRule&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="MsgPropRuleId"&gt;
        &lt;VALUE&gt;DDK_DefaultPropagationRule&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
      &lt;PROPERTY NAME="ManagementModuleId"&gt;
        &lt;VALUE&gt;customdiscovery&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
    &lt;/INSTANCE&gt;
    &lt;INSTANCE CLASSNAME="OV_ServiceTypeComponent"&gt;
      &lt;PROPERTY.REFERENCE NAME="GroupComponent"&gt;
        &lt;VALUE&gt;OV_ServiceTypeDefinition.GUID=\"DiscoveredElement\"&lt;/VALUE&gt;
      &lt;/PROPERTY.REFERENCE&gt;
      &lt;PROPERTY.REFERENCE NAME="PartComponent"&gt;
        &lt;VALUE&gt;OV_ServiceTypeDefinition.GUID=\"DiscoveredElement\"&lt;/VALUE&gt;
      &lt;/PROPERTY.REFERENCE&gt;
      &lt;PROPERTY NAME="PropRuleId"&gt;
        &lt;VALUE&gt;DDK_DefaultPropagationRule&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
    &lt;/INSTANCE&gt;
    &lt;INSTANCE CLASSNAME="OV_ServiceTypeDependency"&gt;
      &lt;PROPERTY.REFERENCE NAME="Dependent"&gt;
        &lt;VALUE&gt;OV_ServiceTypeDefinition.GUID=\"DiscoveredElement\"&lt;/VALUE&gt;
      &lt;/PROPERTY.REFERENCE&gt;
      &lt;PROPERTY.REFERENCE NAME="Antecedent"&gt;
        &lt;VALUE&gt;OV_ServiceTypeDefinition.GUID=\"DiscoveredElement\"&lt;/VALUE&gt;
      &lt;/PROPERTY.REFERENCE&gt;
      &lt;PROPERTY NAME="PropRuleId"&gt;
        &lt;VALUE&gt;DDK_DefaultPropagationRule&lt;/VALUE&gt;
      &lt;/PROPERTY&gt;
    &lt;/INSTANCE&gt;
  &lt;/ManagementModuleElements&gt;
  &lt;PolicyElements&gt;
    &lt;PolicyRules&gt;
      &lt;INSTANCE CLASSNAME="OV_PolicyRule"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;(:If:ExecuteOnUnix#)&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="Condition"&gt;
          &lt;VALUE&gt;NULL&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="NextCase"&gt;
          &lt;VALUE&gt;NULL&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_PolicyRule"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;RunDiscovery@DiscoveredElement&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="Condition"&gt;
          &lt;VALUE&gt;OV_PolicyCondition.Name=\"WinOS#\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="NextCase"&gt;
          &lt;VALUE&gt;OV_PolicyRule.Name=\"(:If:ExecuteOnUnix#)\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_ServiceDiscoveryPolicy"&gt;
        &lt;PROPERTY.REFERENCE NAME="GroupComponent"&gt;
          &lt;VALUE&gt;OV_ServiceTypeDefinition.GUID=\"DiscoveredElement\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="PartComponent"&gt;
          &lt;VALUE&gt;OV_PolicyRule.Name=\"RunDiscovery@DiscoveredElement\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
    &lt;/PolicyRules&gt;
    &lt;ActionParts&gt;
      &lt;INSTANCE CLASSNAME="OV_ActionPart"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;ExecuteOnUnix#&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="Part"&gt;
          &lt;VALUE&gt;OV_PartInstance.Name=\"ExecuteOnUnix\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_ActionPart"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;ExecuteOnWindows#&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="Part"&gt;
          &lt;VALUE&gt;OV_PartInstance.Name=\"ExecuteOnWindows\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_ContainedActions"&gt;
        &lt;PROPERTY.REFERENCE NAME="GroupComponent"&gt;
          &lt;VALUE&gt;OV_PolicyRule.Name=\"(:If:ExecuteOnUnix#)\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="PartComponent"&gt;
          &lt;VALUE&gt;OV_ActionPart.Name=\"ExecuteOnUnix#\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_ContainedActions"&gt;
        &lt;PROPERTY.REFERENCE NAME="GroupComponent"&gt;
          &lt;VALUE&gt;OV_PolicyRule.Name=\"RunDiscovery@DiscoveredElement\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="PartComponent"&gt;
          &lt;VALUE&gt;OV_ActionPart.Name=\"ExecuteOnWindows#\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
    &lt;/ActionParts&gt;
    &lt;ConditionParts&gt;
      &lt;INSTANCE CLASSNAME="OV_PolicyCondition"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;WinOS#&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="__CLASS"&gt;
          &lt;VALUE&gt;OV_ConditionPart&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="Part"&gt;
          &lt;VALUE&gt;OV_PartInstance.Name=\"WinOS\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
      &lt;/INSTANCE&gt;
    &lt;/ConditionParts&gt;
    &lt;ConditionExpressions/&gt;
    &lt;PartInstances&gt;
      &lt;INSTANCE CLASSNAME="OV_PartInstance"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;ExecuteOnUnix&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="Caption"&gt;
          &lt;VALUE&gt;ExecuteOnUnix&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="Description"&gt;
          &lt;VALUE&gt;ExecuteOnUnix&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="PartTemplate"&gt;
          &lt;VALUE&gt;OV_PartTemplate.Name=\"ActionTemplate\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="ParameterBlock"&gt;
          &lt;VALUE&gt;OV_ParameterBlock.Name=\"ParameterBlock_ExecuteOnUnix\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;INSTANCE CLASSNAME="OV_ParameterBlock"&gt;
          &lt;PROPERTY NAME="Name"&gt;
            &lt;VALUE&gt;ParameterBlock_ExecuteOnUnix&lt;/VALUE&gt;
          &lt;/PROPERTY&gt;
          &lt;PROPERTY.ARRAY NAME="ConfigPairs"&gt;
            &lt;VALUE.ARRAY&gt;
              &lt;VALUE&gt;CommandLine=perl "$ACTION_DIR/sd_wsusGroups.pl" "%%FILEPATH%%" "%%ATTRIBUTE%%"&lt;/VALUE&gt;
              &lt;VALUE&gt;User=&lt;/VALUE&gt;
              &lt;VALUE&gt;Password=&lt;/VALUE&gt;
            &lt;/VALUE.ARRAY&gt;
          &lt;/PROPERTY.ARRAY&gt;
        &lt;/INSTANCE&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_PartInstance"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;ExecuteOnWindows&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="Caption"&gt;
          &lt;VALUE&gt;ExecuteOnWindows&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="Description"&gt;
          &lt;VALUE&gt;ExecuteOnWindows&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="PartTemplate"&gt;
          &lt;VALUE&gt;OV_PartTemplate.Name=\"ActionTemplate\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="ParameterBlock"&gt;
          &lt;VALUE&gt;OV_ParameterBlock.Name=\"ParameterBlock_ExecuteOnWindows\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;INSTANCE CLASSNAME="OV_ParameterBlock"&gt;
          &lt;PROPERTY NAME="Name"&gt;
            &lt;VALUE&gt;ParameterBlock_ExecuteOnWindows&lt;/VALUE&gt;
          &lt;/PROPERTY&gt;
          &lt;PROPERTY.ARRAY NAME="ConfigPairs"&gt;
            &lt;VALUE.ARRAY&gt;
              &lt;VALUE&gt;CommandLine=perl "$ACTION_DIR/sd_wsusGroups.pl" "%%FILEPATH%%" "%%ATTRIBUTE%%"&lt;/VALUE&gt;
              &lt;VALUE&gt;User=&lt;/VALUE&gt;
              &lt;VALUE&gt;Password=&lt;/VALUE&gt;
            &lt;/VALUE.ARRAY&gt;
          &lt;/PROPERTY.ARRAY&gt;
        &lt;/INSTANCE&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_PartInstance"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;WinOS&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="Caption"&gt;
          &lt;VALUE&gt;WinOS&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="Description"&gt;
          &lt;VALUE&gt;WinOS&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY.REFERENCE NAME="PartTemplate"&gt;
          &lt;VALUE&gt;OV_PartTemplate.Name=\"BasicDiscTemplate\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;PROPERTY.REFERENCE NAME="ParameterBlock"&gt;
          &lt;VALUE&gt;OV_ParameterBlock.Name=\"ParameterBlock_WinOS\"&lt;/VALUE&gt;
        &lt;/PROPERTY.REFERENCE&gt;
        &lt;INSTANCE CLASSNAME="OV_ParameterBlock"&gt;
          &lt;PROPERTY NAME="Name"&gt;
            &lt;VALUE&gt;ParameterBlock_WinOS&lt;/VALUE&gt;
          &lt;/PROPERTY&gt;
          &lt;PROPERTY.ARRAY NAME="ConfigPairs"&gt;
            &lt;VALUE.ARRAY&gt;
              &lt;VALUE&gt;DiscoveryType=OSQuery&lt;/VALUE&gt;
              &lt;VALUE&gt;Name=Windows&lt;/VALUE&gt;
            &lt;/VALUE.ARRAY&gt;
          &lt;/PROPERTY.ARRAY&gt;
        &lt;/INSTANCE&gt;
      &lt;/INSTANCE&gt;
    &lt;/PartInstances&gt;
    &lt;PartTemplates&gt;
      &lt;INSTANCE CLASSNAME="OV_PartTemplate"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;ActionTemplate&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="ExecutionModule"&gt;
          &lt;VALUE&gt;com.hp.openview.OvDiscoveryParts.OvActionPart&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="ParameterTemplate"&gt;
          &lt;VALUE&gt;&amp;lt;PartParams&amp;gt;&amp;lt;Param name="CommandLine"&amp;gt;&amp;lt;Caption&amp;gt;Command Line&amp;lt;/Caption&amp;gt;&amp;lt;UserEditable/&amp;gt;&amp;lt;UserEdit/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;Param name="User"&amp;gt;&amp;lt;Caption&amp;gt;User Name&amp;lt;/Caption&amp;gt;&amp;lt;Optional/&amp;gt;&amp;lt;UserEditable/&amp;gt;&amp;lt;UserEdit/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;Param name="Password"&amp;gt;&amp;lt;Caption&amp;gt;Password&amp;lt;/Caption&amp;gt;&amp;lt;Optional/&amp;gt;&amp;lt;UserEditable/&amp;gt;&amp;lt;UserEdit/&amp;gt;&amp;lt;Securable/&amp;gt;&amp;lt;Secure/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;/PartParams&amp;gt;&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
      &lt;/INSTANCE&gt;
      &lt;INSTANCE CLASSNAME="OV_PartTemplate"&gt;
        &lt;PROPERTY NAME="Name"&gt;
          &lt;VALUE&gt;BasicDiscTemplate&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="ExecutionModule"&gt;
          &lt;VALUE&gt;com.hp.openview.OvDiscoveryParts.OvBasicDiscoveryPart&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
        &lt;PROPERTY NAME="ParameterTemplate"&gt;
          &lt;VALUE&gt;&amp;lt;PartParams&amp;gt;&amp;lt;Param name="DiscoveryType"&amp;gt;&amp;lt;Caption&amp;gt;Discovery Type&amp;lt;/Caption&amp;gt;&amp;lt;Values default="File"&amp;gt;&amp;lt;Value name="File"&amp;gt;&amp;lt;Params&amp;gt;&amp;lt;Param name="FileName"&amp;gt;&amp;lt;Caption&amp;gt;Filename&amp;lt;/Caption&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;/Params&amp;gt;&amp;lt;/Value&amp;gt;&amp;lt;Value name="Process"&amp;gt;&amp;lt;Params&amp;gt;&amp;lt;Param name="ProcessName"&amp;gt;&amp;lt;Caption&amp;gt;Process Name&amp;lt;/Caption&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;/Params&amp;gt;&amp;lt;/Value&amp;gt;&amp;lt;Value name="Registry"&amp;gt;&amp;lt;Params&amp;gt;&amp;lt;Param name="Key"&amp;gt;&amp;lt;Caption&amp;gt;Key&amp;lt;/Caption&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;Param name="Value"&amp;gt;&amp;lt;Caption&amp;gt;Value&amp;lt;/Caption&amp;gt;&amp;lt;Optional/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;Param name="TestValue"&amp;gt;&amp;lt;Caption&amp;gt;Test Value&amp;lt;/Caption&amp;gt;&amp;lt;Optional/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;/Params&amp;gt;&amp;lt;/Value&amp;gt;&amp;lt;Value name="WMIQuery"&amp;gt;&amp;lt;Params&amp;gt;&amp;lt;Param name="Namespace"&amp;gt;&amp;lt;Caption&amp;gt;Namespace&amp;lt;/Caption&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue default="root\cimV2"/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;Param name="Query"&amp;gt;&amp;lt;Caption&amp;gt;Query&amp;lt;/Caption&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;/Params&amp;gt;&amp;lt;/Value&amp;gt;&amp;lt;Value name="OSQuery"&amp;gt;&amp;lt;Params&amp;gt;&amp;lt;Param name="Architecture"&amp;gt;&amp;lt;Caption&amp;gt;Architecture&amp;lt;/Caption&amp;gt;&amp;lt;Optional/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;Param name="Name"&amp;gt;&amp;lt;Caption&amp;gt;Name&amp;lt;/Caption&amp;gt;&amp;lt;Optional/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;Param name="Version"&amp;gt;&amp;lt;Caption&amp;gt;Version&amp;lt;/Caption&amp;gt;&amp;lt;Optional/&amp;gt;&amp;lt;Values&amp;gt;&amp;lt;UserValue/&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;/Params&amp;gt;&amp;lt;/Value&amp;gt;&amp;lt;/Values&amp;gt;&amp;lt;/Param&amp;gt;&amp;lt;/PartParams&amp;gt;&lt;/VALUE&gt;
        &lt;/PROPERTY&gt;
      &lt;/INSTANCE&gt;
    &lt;/PartTemplates&gt;
  &lt;/PolicyElements&gt;
&lt;/AutoDiscPolicy&gt;
</code></pre>

