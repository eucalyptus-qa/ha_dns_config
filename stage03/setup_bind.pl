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

setlibsleep(2);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"NC00"});
print "SUCCESS: set remote host: $masters{NC00}\n";

open(FH, ">./db.eucaqa");
print FH <<EOF;
\$TTL 604800
@ IN SOA eucaqa. root.eucaqa. (
2 ; Serial
604800 ; Refresh
86400 ; Retry
2419200 ; Expire
604800 ) ; Negative Cache TTL
;
@ IN NS ns.eucaqa.
EOF

print FH "@ IN A $masters{NC00}\n";

print FH <<EOF;
;@ IN AAAA ::1
EOF

if ($masters{CLC}) {
    print FH "eucadomain.eucaqa. IN NS clc0.eucadomain.eucaqa.\n";
} 
if ($slaves{CLC}) {
    print FH "eucadomain.eucaqa. IN NS clc1.eucadomain.eucaqa.\n";
}
print FH "ns.eucaqa. IN A $masters{NC00}\n";

if ($masters{CLC}) {
    print FH "clc0.eucadomain.eucaqa. IN A $masters{CLC}\n";
}
if ($slaves{CLC}) {
    print FH "clc1.eucadomain.eucaqa. IN A $slaves{CLC}\n";
}
    
close(FH);

open(FH, ">./named.conf");
print FH <<EOF;
zone "eucaqa" {
type master;
file "/etc/bind/db.eucaqa";
};

zone "eucadomain.eucaqa" {
type forward;
forward only;
EOF

if ($masters{CLC}) {
    print FH "forwarders { $masters{CLC};\n";
}
if ($slaves{CLC}) {
    print FH "$slaves{CLC}; };\n";
} else {
    print FH "};\n";
}
print FH <<EOF;
};
EOF

run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{NC00} mkdir -p /etc/bind");
run_command("$runat scp -o StrictHostKeyChecking=no named.conf root\@$masters{NC00}:/etc/bind/");
run_command("$runat scp -o StrictHostKeyChecking=no db.eucaqa root\@$masters{NC00}:/etc/bind/");
run_command("$runat scp -o StrictHostKeyChecking=no named.conf root\@$masters{NC00}:/etc/");
run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{NC00} killall -9 dnsmasq", "no");
sleep(2);
run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{NC00} /etc/init.d/named restart", "no");
run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{NC00} /etc/init.d/bind9 restart", "no");
run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{NC00} cp /etc/resolv.conf /etc/resolv.conf.orig");
run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{NC00} \"echo 'nameserver localhost' >/etc/resolv.conf\"");
run_command("$runat ssh -o StrictHostKeyChecking=no root\@$masters{NC00} chattr +i /etc/resolv.conf");

doexit(0, "EXITING SUCCESS\n");
