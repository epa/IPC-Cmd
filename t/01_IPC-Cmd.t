## IPC::Cmd test suite ###

use strict;
use lib qw[../lib lib to_load t/to_load];
use File::Spec ();

use Test::More tests => 8;

use_ok( 'IPC::Cmd' ) or diag "Cmd.pm not found.  Dying", die;

*run        = *IPC::Cmd::run;
*can_run    = *IPC::Cmd::can_run;

{
    ok( can_run('perl'),                q[Found 'perl' in your path] );
    ok( !can_run('10283lkjfdalskfjaf'), q[Not found non-existant binary] );
}

{
    my $cmd = "$^X -v";

    my @list = run( command => $cmd, verbose => 0 );

    ok($list[0],    q[Succesful run of command] );
    ok(!$list[1],   q[Zero exit code] );

    SKIP: {
        skip "No buffers returned", 3 unless $list[2];

        ok( (grep /larry\s+wall/i, @{$list[2]}),    q[Out buffer filled] );
        ok( (grep /larry\s+wall/i, @{$list[3]}),    q[Stdout buffer filled] );
        ok( @{$list[4]} == 0,                       q[Stderr buffer empty] );
    }
}
