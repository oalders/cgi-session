package CGI::Session::Driver::sqlite;

# $Id$

use strict;

use MIME::Base64;
use File::Spec;
use CGI::Session::Driver::DBI;

@CGI::Session::Driver::sqlite::ISA        = qw( CGI::Session::Driver::DBI );
$CGI::Session::Driver::sqlite::VERSION    = "1.0";

sub init {
    my $self = shift;

    if ( $self->{Handle} ) {
        $self->{Handle}->{sqlite_handle_binary_nulls} = 1;
        return $self->SUPER::init();
    }

    $self->{DataSource} ||= File::Spec->catfile( File::Spec->tmpdir, 'sessions.sqlt' );
    unless ( $self->{DataSource} =~ /^dbi:sqlite/i ) {
        $self->{DataSource} = "dbi:SQLite:dbname=" . $self->{DataSource};
    }

    $self->{Handle} = DBI->connect( $self->{DataSource}, '', '', {RaiseError=>1, PrintError=>1, AutoCommit=>1});
    unless ( $self->{Handle} ) {
        return $self->set_error( "init(): couldn't create \$dbh: " . $DBI::errstr );
    }
    $self->{_disconnect} = 1;
    $self->{Handle}->{sqlite_handle_binary_nulls} = 1;
    return 1;
}


#
# Temporary hack to get SQLite and Storable get along
#
sub store {
    my $self = shift;
    return $self->SUPER::store($_[0], encode_base64($_[1], ''));
}

#
# Temporary hack to get SQLite and Storable get along
#
sub retrieve {
    my $self    = shift;
    my $datastr = $self->SUPER::retrieve(shift);
    return $datastr unless $datastr;
    return decode_base64($datastr);
}


1;

__END__;

=pod

=head1 NAME

CGI::Session::Driver::sqlite - CGI::Session driver for SQLite

=head1 SYNOPSIS

    $s = new CGI::Session("driver:sqlite", $sid);
    $s = new CGI::Session("driver:sqlite", $sid, {DataSource=>'/tmp/sessions.sqlt'});
    $s = new CGI::Session("driver:sqlite", $sid, {Handle=>$dbh});

=head1 DESCRIPTION

B<sqlite> driver stores session data in SQLite files using L<DBD::SQLite|DBD::SQLite> DBI driver. More details see L<CGI::Session::Driver::DBI|CGI::Session::Driver::DBI>, its parent class.

=head1 DRIVER ARGUMENTS

Supported driver arguments are I<DataSource> and I<Handle>. B<At most> only one of these arguments can be set while creating session object.

I<DataSource> should be in the form of C<dbi:SQLite:dbname=/path/to/db.sqlt>. If C<dbi:SQLite:> is missing it will be prepended for you. If I<Handle> is present it should be database handle (C<$dbh>) returned by L<DBI::connect()|DBI/connect()>.

It's OK to drop the third argument to L<new()|CGI::Session::Driver/new()> altogether, in which case a database named F<sessions.sqlt> will be created in your machine's TEMPDIR folder, which is F</tmp> in UNIX.

=head1 BUGS AND LIMITATIONS

To support binary serializers (L<CGI::Session::Serialize::storable>), currently, sqlite driver makes use of L<MIME::Base64|MIME::Base64> to encode and decode data string.

=head1 LICENSING

For support and licensing see L<CGI::Session|CGI::Session>

=cut

