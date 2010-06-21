package MyConstants;

# various lookup tables, architecture specific paths,, etc etc.


# The URL to fetch the list of submissions from
use constant SUBMISSION_KEY_URL => "http://submit.modencode.org/submit/public/list.txt";

# The base directory for uploaded/extracted data files
use constant WHERE      => "/srv/www/data/pipeline";

# Subdirectory under WHERE that contains actual uploaded data
use constant UPLOAD_DIR      => "";

# Path to append to end of project directory to see actual data 
# (e.g. "extracted" in uploaded/123/extracted)
use constant DATA_DIR_SUFFIX      => "extracted";

# Browser root dir
use constant BROWSER_ROOT  => "/srv/www/data/pipeline";

# Set this to 1 to generate a path like browser_root/123/browser, 
# set this to 0 to generate a path like browser_root/browser/123
use constant BROWSER_DIR_BEFORE_PROJECT_ID  => 1;

# Set this to 1 to generate a config like browser_root[/123]/fly/123.conf, 
# set this to 0 to generate a path like browser_root[/123]/123.conf
use constant BROWSER_CONF_USES_SPECIES  => 0;

# Path to append to end of project directory for storing browser data
# (e.g. "browser" in uploaded/123/browser)
use constant BROWSER_DIR_SUFFIX      => "browser";

# If the final location of wib files is somewhere else, 
# set the base directory for ./browser here
use constant DESTINATION_DIR      => "/srv/www/data/pipeline";

# verbose reporting
use constant DEBUG      => 1;

# BAM FASTA sources
use constant FASTA_PATH => "/srv/www/pipeline/gbrowse/bam_support_fasta";

use constant SAMTOOLS_PATH => "/srv/www/pipeline/submit/script/validators/modencode/samtools";

# Which types will trigger a peak (wiggle box) summary
use constant WIG        => qw/transcript_region
                              protein_binding_site
                              histone_binding_site
                              binding_site
                              TF_binding_site
                              computed_peaks
                              computed_peak
                              peak
                              peaks/;

# for the config reasoner
# adjust as required
use constant TYPES =>  (
                         WIG                  => 'wiggle',
                         microarray_oligo     => 'wiggle',
                         gene                 => 'gene',
                         mRNA                 => 'gene',
                         ncRNA                => 'gene',
                         miRNA                => 'gene',
                         tRNA                 => 'gene',
                         transcript           => 'gene',
                         EST                  => 'est',
                         EST_match            => 'est',
                         expressed_sequence_match=>'est',
                         match                => 'quantitative',
                         match_part           => 'quantitative',
                         Signal_Graph_File    => 'wiggle',
                         transcript_region    => 'peak',
                         protein_binding_site => 'peak',
			 TF_binding_site      => 'peak',
                         histone_binding_site => 'peak',
                         binding_site         => 'peak',
                         computed_peaks       => 'peak',
                         peaks                => 'peak',
			 peak                 => 'peak',
                         rnaseq_wiggle        => 'hybrid_wiggle',
                         SNP                  => 'basic',
                         unknown              => 'basic'
			);

# lab -> organism chart
use constant ORG => (
                     Celniker   => 'fly',
                     Henikoff   => undef,
                     Karpen     => 'fly',
                     Lai        => 'fly',
                     Lieb       => 'worm',
                     MacAlpine  => 'fly',
                     Piano      => 'worm',
                     Snyder     => 'worm',
                     Stein      => undef,
                     Waterston  => 'worm',
                     White      => 'fly',
                     );


# Lab color chart 
use constant LABCOLOR => (
			  Celniker   => 'red',
			  Henikoff   => 'green',
			  Karpen     => 'lightsteelblue',
			  Lai        => 'peachpuff',
			  Lieb       => 'cyan',
			  MacAlpine  => 'blue',
			  Piano      => 'steelblue',
			  Snyder     => 'magenta',
			  Stein      => 'yellow',
			  Waterston  => 'purple',
			  White      => 'black',
			  );

# Allowed chromosome names to get rid of bogus junk target lines in the GFF
use constant REFSEQ  => (
			 qw/
			 2L 2LHet 2R 2RHet 4 M MtDNA U UExtra X XHet Y YHetI
			 2Lhet 2Rhet Xhet YhetI
			 I II III IV V X
			 /		 
			 );


1;
