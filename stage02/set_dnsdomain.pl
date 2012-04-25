#!/usr/bin/perl

require "ec2ops.pl";

my $account = shift @ARGV || "eucalyptus";
my $user = shift @ARGV || "admin";

# need to add randomness, for now, until account/user group/keypair
# conflicts are resolved

$rando = int(rand(10)) . int(rand(10)) . int(rand(10));
if ($account ne "eucalyptus") {
    $account .= "$rando";
}
if ($user ne "admin") {
    $user .= "$rando";
}
$newgroup = "ec2opsgroup$rando";
$newkeyp = "ec2opskey$rando";

parse_input();
print "SUCCESS: parsed input\n";

if ($cc_has_broker{"CC00"}) {
    doexit(0, "SUCCESS: VMWare detected, skipping test\n");
}

setlibsleep(1);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote host: $masters{CLC}\n";

setproperties("system.dns.dnsdomain", "eucadomain.eucaqa");
print "SUCCESS: set system.dns.dnsdomain for eucadomain.eucaqa\n";

setproperties("bootstrap.webservices.use_dns_delegation", "true");
print "SUCCESS: set bootstrap.webservices.use_dns_delegation for true\n";

run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{CLC} killall -9 dnsmasq", "no");
print "SUCCESS: killed dnsmasq on CLC ($masters{CLC})\n";

run_command("$runat ssh -o StrictHostKeyChecking=no root\@$slaves{CLC} killall -9 dnsmasq", "no");
print "SUCCESS: killed dnsmasq on CLC ($slaves{CLC})\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote host: $masters{CLC}\n";

doexit(0, "EXITING SUCCESS\n");
