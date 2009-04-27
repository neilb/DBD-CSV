#!/usr/bin/perl

# This is a test for statement attributes being present appropriately.

use DBI;
use vars qw($verbose);

do "t/lib.pl";

@table_def = (
    [ "id",   "INTEGER",  4, &COL_KEY		],
    [ "name", "CHAR",    64, &COL_NULLABLE	],
    );

#
#   Main loop; leave this untouched, put tests after creating
#   the new table.
#
while (Testing()) {
    #
    #   Connect to the database
    Test($state or $dbh = Connect (), "connect") or
	ServerError();

    #
    #   Find a possible new table name
    #
    Test($state or $table = FindNewTable($dbh))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Create a new table
    #
    Test($state or ($def = TableDefinition($table, @table_def),
		    $dbh->do($def)))
	   or DbiError($dbh->err, $dbh->errstr);


    Test($state or $cursor = $dbh->prepare("SELECT * FROM $table"))
	   or DbiError($dbh->err, $dbh->errstr);

    Test($state or $cursor->execute)
	   or DbiError($cursor->err, $cursor->errstr);

    my $res;
    Test($state or (($res = $cursor->{'NUM_OF_FIELDS'}) == @table_def))
	   or DbiError($cursor->err, $cursor->errstr);
    if (!$state && $verbose) {
	printf("Number of fields: %s\n", defined($res) ? $res : "undef");
    }
    Test($state or ($ref = $cursor->{'NAME'})  &&  @$ref == @table_def
	            &&  (lc $$ref[0]) eq $table_def[0][0]
		    &&  (lc $$ref[1]) eq $table_def[1][0])
	   or DbiError($cursor->err, $cursor->errstr);
    if (!$state && $verbose) {
	print "Names:\n";
	for ($i = 0;  $i < @$ref;  $i++) {
	    print "    ", $$ref[$i], "\n";
	}
    }

    if (!$state && $verbose) {
	print "Nullable:\n";
	for ($i = 0;  $i < @$ref;  $i++) {
	    print "    ", ($$ref[$i] & &COL_NULLABLE) ? "yes" : "no", "\n";
	    }
	}

    Test($state or undef $cursor  ||  1);


    #
    #  Drop the test table
    #
    Test($state or ($cursor = $dbh->prepare("DROP TABLE $table")))
	or DbiError($dbh->err, $dbh->errstr);
    Test($state or $cursor->execute)
	or DbiError($cursor->err, $cursor->errstr);

    #  NUM_OF_FIELDS should be zero (Non-Select)
    Test($state or ($cursor->{'NUM_OF_FIELDS'} == 0))
	or !$verbose or printf("NUM_OF_FIELDS is %s, not zero.\n",
			       $cursor->{'NUM_OF_FIELDS'});
    Test($state or (undef $cursor) or 1);
}