#
# BioPerl module for Bio::DB::Taxonomy::greengenes
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Florent Angly <florent.angly@gmail.com>
#
# Copyright Florent Angly
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Taxonomy::greengenes - Use the Greengenes taxonomy

=head1 SYNOPSIS

  use Bio::DB::Taxonomy;

  my $db = Bio::DB::Taxonomy->new(
     -source   => 'greengenes',
     -taxofile => 'taxonomy_16S_candiv_gg_2011_1.txt'
  );

=head1 DESCRIPTION

This is an implementation of Bio::DB::Taxonomy which stores and accesses the
Greengenes taxonomy. Internally, Bio::DB::Taxonomy::greengenes keeps the taxonomy
into memory by using Bio::DB::Taxonomy::list.

The required taxonomy file, taxonomy_16S_candiv_gg_2011_1.txt, can be obtained
from L<http://secondgenome1.s3.amazonaws.com/greengenes_reference_files/taxonomy_16S_candiv_gg_2011_1.txt.gz?AWSAccessKeyId=AKIAICKIGPBXNLBSJV7Q&Expires=1334123836&Signature=Hay3Trr76Xlp390UyH4ZpZuvODU%3D>.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  https://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Florent Angly

florent.angly@gmail.com

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::DB::Taxonomy::greengenes;

use strict;
use Bio::DB::Taxonomy::list;

use base qw(Bio::DB::Taxonomy Bio::DB::Taxonomy::list);


$Bio::DB::Taxonomy::list::prefix = 'gg';


=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::Taxonomy::greengenes->new();
 Function: Builds a new Bio::DB::Taxonomy::greengenes object 
 Returns : an instance of Bio::DB::Taxonomy::greengenes
 Args    : -taxofile  => name of the file containing the taxonomic information,
                         typically 'taxonomy_16S_candiv_gg_2011_1.txt' (mandatory)

=cut

sub new {
   # Override Bio::DB::Taxonomy
   my($class, @args) = @_;
   my $self = $class->SUPER::new(@args);
   my ($taxofile) = $self->_rearrange([qw(TAXOFILE)], @args);
  
   if ( $taxofile ) {
      $self = $self->_build_taxonomy($taxofile);
   }

   return $self;
}


sub _build_taxonomy {
   my ($self, $taxofile) = @_;

   my $all_ranks = ['kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species'];

   my $taxonomy = Bio::DB::Taxonomy::list->new();

   open my $fh, '<', $taxofile or $self->throw("Could not read file $taxofile: $!");

   # Skip the first line. It contains the headers: prokMSA_id	taxonomy
   my $line = <$fh>;
 
   # Parse taxonomy lines. Example:
   # 348902	k__Bacteria; p__Bacteroidetes; c__Bacteroidia; o__Bacteroidales; f__Bacteroidaceae; g__Bacteroides; s__Bacteroides plebeius
   while ($line = <$fh>) {
      chomp $line;
      my ($prokmsa_id, $taxo_string) = split "\t", $line;
      my $names = [split /;\s*/, $taxo_string];

      # Remove ambiguous taxons, i.e. go from:
      #    k__Archaea; p__pMC2A384; c__; o__; f__; g__; s__
      # to:
      #    k__Archaea; p__pMC2A384
      while ($names->[-1] =~ m/^.__$/) {
         pop @$names;
      }

      my $nof_ranks = scalar @$names;
      next if $nof_ranks < 1;

      $taxonomy->add_lineage(
         -ranks => [ @{$all_ranks}[0..$nof_ranks-1] ],
         -names => $names,
      );
   }

   close $fh;

   return $taxonomy;
}


1;
