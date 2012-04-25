#!/usr/bin/perl

require "ec2ops.pl";

$component_to_switch = shift @ARGV || "CLC";

parse_input();
print "SUCCESS: parsed input\n";

exit_if_not_ha("$component_to_switch");
print "SUCCESS: detected HA configuration for component '$component_to_switch'\n";

doexit(0, "EXITING SUCCESS\n");

