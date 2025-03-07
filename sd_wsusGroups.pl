#!/usr/bin/perl
use lib '/opt/OV/nonOV/perl/a/lib/curr';
use OvParam;
use strict;
use warnings;

# Author and company details
# package   = "Accelerator4"
# component = "WSUS Group Discovery" 
# company   = "novalytics";
# author    = "Jeroen van de Hoef";
# version   = "2020.02#35";

# Policy Parameters
my $t = new OvParam::Template();
$t->Load("sd_WsusGroups", "svcdisctmpl");
my $paramFP = $t->GetSimpleParameter("FILEPATH");
my $paramAT = $t->GetSimpleParameter("ATTRIBUTE");
my $filePath = $paramFP->GetValue();
my $cmdbAttribute = $paramAT->GetValue();

# Variables
my @csvContent = ();

# Retreive the wsusFile
sub getFile {
    my $fh;
    unless (open $fh, "<:encoding(utf8)", $filePath) {
    print STDERR "Could not open file '$filePath': $!\n";
    # we return 'undefined', we could also 'die' or 'croak'
    return undef
    }
    chomp(@csvContent = <$fh>);
    unless (close $fh) {
    # what does it mean if close yields an error and you are just reading?
    print STDERR "Don't care error while closing '$filePath': $!\n";
    } 
}

sub pushDiscovery {
    # Variables
    my @splitArray = ();
    my $csvLine = "";
    my $primaryNodename = "";
    my $nodeName = "";
    my $wsusGroup = "";

    # Populate the topology-file and write the <Service> tag
    print "<Service>\n";

    while (defined($csvLine = shift @csvContent)){
        @splitArray = split(",", $csvLine);
        $primaryNodename = $splitArray[0];
        $wsusGroup = $splitArray[1];

        if (($primaryNodename ne "") || ($wsusGroup ne ""))
        {
            if (index($primaryNodename, ".") != -1) {
                $nodeName = substr($primaryNodename, 0, index($primaryNodename, '.'));
            } else {
                $nodeName = $primaryNodename;
            }
            
            print "\t<NewInstance ref=\"HOST:$primaryNodename:$nodeName\">\n";
                print "\t\t<Key>HOST:$primaryNodename:$nodeName</Key>\n";
                print "\t\t<Std>DiscoveredElement</Std>\n";
                print "\t\t<Attributes>\n";
                    print "\t\t\t<Attribute name=\"hpom_citype\" value=\"nt\" />\n";
                    print "\t\t\t<Attribute name=\"ucmdb_name\" value=\"$nodeName\" />\n";
                    print "\t\t\t<Attribute name=\"ucmdb_primary_dns_name\" value=\"$primaryNodename\" />\n";
                    print "\t\t\t<Attribute name=\"$cmdbAttribute\" value=\"$wsusGroup\" />\n";             
                print "\t\t</Attributes>\n";
            print "\t</NewInstance>\n";
        }
    }

    # Close the file with the trailling <Service> tag
    print "</Service>\n";
}

# Run the subs
&getFile;
&pushDiscovery;