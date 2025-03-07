#!/usr/bin/perl
use lib '/opt/OV/nonOV/perl/a/lib/curr';
use OvParam;
use strict;
use warnings;

# Author and company details
# package   = "Accelerator4"
# component = "Discovery" 
# company   = "novalytics";
# author    = "Jeroen van de Hoef";
# version   = "1.0";

my $primaryNodename =`ovconfget eaagt OPC_NODENAME`;
my $osName = `ovconfget eaagt.sysdata osname`;
my $osVersion = `ovconfget eaagt.sysdata osversion`;
my $biosUUID = `ovconfget eaagt.sysdata biosuuid`;
my $osDescription = "empty";
my $nodeName = "empty";

# Remove trailing new lines
$primaryNodename =~ s/^\s+//;
$primaryNodename =~ s/\s+$//;
$primaryNodename = lc $primaryNodename;
$osName =~ s/^\s+//;
$osName =~ s/\s+$//;
$osVersion =~ s/^\s+//;
$osVersion =~ s/\s+$//;

sub getOSDescription {
    # This function is also compatible for old Perl versions, eg. agents 11.14

    $osDescription = `wmic os get Description /value`;
    my @SPLIT1 = split("\n", $osDescription);
    print FH "split: @SPLIT1[2]\n";
    my @SPLIT2 = split("=", @SPLIT1[2]);
    $osDescription = @SPLIT2[1];
    $osDescription =~ s/^\s+//;
    $osDescription =~ s/\s+$//; 
}

sub pushDiscovery {
    if (index($primaryNodename, ".") != -1) {
        $nodeName = substr($primaryNodename, 0, index($primaryNodename, '.'));
    } else {
        $nodeName = $primaryNodename;
    }

    # Write to file
	open(FH, '>', "osDescUpdate.xml") or die $!;
    print FH "<Service>\n";
        print FH "\t<NewInstance ref=\"HOST:$primaryNodename:$nodeName\">\n";
            print FH "\t\t<Key>HOST:$primaryNodename:$nodeName</Key>\n";
            print FH "\t\t<Std>DiscoveredElement</Std>\n";
            print FH "\t\t<Attributes>\n";
                print FH "\t\t\t<Attribute name=\"hpom_citype\" value=\"nt\" />\n";
                print FH "\t\t\t<Attribute name=\"ucmdb_name\" value=\"$nodeName\" />\n";
		        print FH "\t\t\t<Attribute name=\"ucmdb_primary_dns_name\" value=\"$primaryNodename\" />\n";
                print FH "\t\t\t<Attribute name=\"ucmdb_discovered_description\" value=\"$osDescription\" />\n";
		        print FH "\t\t\t<Attribute name=\"ucmdb_discovered_os_name\" value=\"$osName $osVersion\" />\n";             
            print FH "\t\t</Attributes>\n";
        print FH "\t</NewInstance>\n";
    print FH "</Service>";
	close(FH);

    # Expose to STDOUT
    print "<Service>\n";
        print "<NewInstance ref=\"HOST:$primaryNodename:$nodeName\">\n";
            print "<Key>HOST:$primaryNodename:$nodeName</Key>\n";
            print "<Std>DiscoveredElement</Std>\n";
            print "<Attributes>\n";
                print "<Attribute name=\"hpom_citype\" value=\"nt\" />\n";
                print "<Attribute name=\"ucmdb_name\" value=\"$nodeName\" />\n";
		        print "<Attribute name=\"ucmdb_primary_dns_name\" value=\"$primaryNodename\" />\n";
                print "<Attribute name=\"ucmdb_discovered_description\" value=\"$osDescription\" />\n";
		        print "<Attribute name=\"ucmdb_discovered_os_name\" value=\"$osName $osVersion\" />\n";             
            print "</Attributes>\n";
        print "</NewInstance>\n";
    print "</Service>";
}

&getOSDescription;
&pushDiscovery;