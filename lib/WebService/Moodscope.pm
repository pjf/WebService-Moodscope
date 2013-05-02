package WebService::Moodscope;
use v5.010;
use strict;
use warnings;
use autodie;
use Moo;
use Method::Signatures;
use WWW::Mechanize;
use Carp qw(croak);

# ABSTRACT: Extract mood information from Moodscope

# VERSION: Generated by DZP::OurPkg:Version

=for Pod::Coverage BUILD DEMOLISH

=cut

has url       => ( is => 'ro'                       );
has agent     => ( is => 'rw'                       );
has _fetched  => ( is => 'rw', default => sub { 0 } );
has _as_array => ( is => 'rw'                       );
has _as_hash  => ( is => 'rw'                       );

method BUILD($args) {
    my $keep_alive = $args->{keep_alive} // 1;

    if (not $self->agent) {
        my $agent = WWW::Mechanize->new(
            agent      => "Perl/$], WebService::MoodScope/" . $self->VERSION,
            keep_alive => $keep_alive,
        );
        $self->agent($agent);
    }

    return;
}

method _fetch() {

    # Do nothing if we've already fetched our data.
    return if $self->_fetched;

    my $agent = $self->agent;

    $agent->get( $self->url);

    my $content = $agent->content;

    # Find the data section.

    my ($data) = $content =~ m{^data:\s+\[\s*([^]]*?)\s+\]}msx;

    if (not $data) {
        croak "No recogniseable moodscope data at " . $self->url . "\n\n" . $content;
    }

    # Extract data from each row

    my %as_hash;
    my @as_array;

    foreach (split /\n/, $data) {
        m{
            x:\s*Date\.UTC\((?<year>\d+),\s(?<month>\d+),\s(?<day>\d+)\),\s
            y:\s(?<mood>\d+)
        }msx or die "Bad moodscope line: $_";

        my ($month) = $+{month} + 1;    # Month zero? Thanks moodscope! :)

        my $entry = {
            date => sprintf("%4d-%02d-%02d",$+{year}, $+{month}+1, $+{day}),
            mood => $+{mood},
        };

        push @as_array, $entry;
        $as_hash{$entry->{date}} = $entry->{mood};
    }

    $self->_as_hash(\%as_hash);
    $self->_as_array(\@as_array);

    $self->_fetched(1);

    return;
}

method as_hash() {
    $self->_fetch;
    return $self->_as_hash;
}

method as_array() {
    $self->_fetch;
    return $self->_as_array;
}

1;
