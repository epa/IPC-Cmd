## IPC::Cmd test suite ###

BEGIN { chdir 't' if -d 't' };

use strict;
use lib qw[../lib];
use File::Spec ();

use Test::More 'no_plan';

use_ok( 'IPC::Cmd' ) or diag "Cmd.pm not found.  Dying", die;

IPC::Cmd->import( qw[can_run run] );

### silence it ###
local $IPC::Cmd::VERBOSE = $ARGV[0] ? 1 : 0;

{
    ok( can_run('perl'),                q[Found 'perl' in your path] );
    ok( !can_run('10283lkjfdalskfjaf'), q[Not found non-existant binary] );
}


{   ### list of commands and regexes matching output ###
    my $map = [
        ["$^X -v",                           qr/larry\s+wall/i, ], 
        [[$^X, '-v'],                        qr/larry\s+wall/i, ],
        ["echo 1 | $^X -neprint",            qr/1/,             ],
        [[qw[echo 1 |], $^X, qw|-neprint|],  qr/1/,             ],
    ];       
  
    for my $pref ( [1,1], [0,1], [0,0] ) {
        local $IPC::Cmd::USE_IPC_RUN    = $pref->[0];
        local $IPC::Cmd::USE_IPC_OPEN3  = $pref->[1];

        for my $aref ( @$map ) {
            my $cmd     = $aref->[0];
            my $regex   = $aref->[1];

            my $Can_Buffer;
            my $captured;
            my $ok = run( command => $cmd, 
                          buffer  => \$captured,
                    );
    
            ok($ok,     q[Succesful run of command] );
        
            SKIP: {
                skip "No buffers returned", 1 unless $captured;
                like( $captured, $regex,      q[  Buffer filled] );
        
                ### if we get here, we have buffers ###
                $Can_Buffer++;
            }
        
        

            my @list = run( command => $cmd );
            ok( $list[0],       "Command ran succesfully" );
            ok( !$list[1],      "   No error code set" );

            SKIP: {
                skip "No buffers, can not do buffer tests", 3 
                        unless $Can_Buffer;

                ok( (grep /$regex/, @{$list[2]}),
                                    "   Out buffer filled" );
                SKIP: {                    
                    skip "IPC::Run bug prevents seperated " .
                            "stdout/stderr buffers", 2 if $pref->[0];                
                    
                    ok( (grep /$regex/, @{$list[3]}),
                                        "   Stdout buffer filled" );
                    ok( @{$list[4]} == 0,                   
                                        "   Stderr buffer empty" );
                }
            }
        }
    }
}

           
