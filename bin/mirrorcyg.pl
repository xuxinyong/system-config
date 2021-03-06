#!/usr/bin/env perl
use File::Path;
use File::Basename;
use URI::Escape;

$site = "http://mirrors.kernel.org/sourceware/cygwin/";
$site = "http://mirrors.163.com/cygwin/";
$site =~ s,/*$,,g;

$dl_dir = lc(uri_escape($site));
my $site_prefix = substr($site, length("http://"));
system("mkdir -p `dirname $site_prefix`") == 0 or die "mkdir failed";

if (system("mkdir -p $dl_dir") == 0) {
    system("ln -sf `pwd`/$dl_dir $site_prefix") == 0 or die "ln -s failed";
}

$site = $site . "/";
$site_prefix = $site_prefix . "/";

$ini = "setup.ini";

system "wget -N $site/$ini";

open($ini_fh, $ini);
my @ini_content;
while (<$ini_fh>) {
    chomp;
    push @ini_content, $_;
}

@ini_content = grep /^install:|^source:/, @ini_content;

sub md5sum($)
{
    open(my $fh, $_[0]) or return;
    use Digest::MD5;
    my $md5 = Digest::MD5->new;
    $md5->addfile($fh);
    return $md5->hexdigest;
}

my @paths;
my %paths;
my $bytes_to_download = 0;
foreach (@ini_content) {
    (undef, $path, $size, $md5) = split;
    next if $paths{$path};
    $full_path = $site_prefix . $path;
    if (-s $full_path == $size) {
        if (1 or md5sum($full_path) eq $md5) {
            print STDERR "$full_path is up to date!\n";
            next;
        } else {
            $bytes_to_download += $size;
        }
    } else {
        $bytes_to_download += $size - -s $path;
    }

    unlink $path;
    $cygfiles{$path} = [$size, $md5];
    $paths{$path} = 1;
}

@paths = sort keys %paths;

foreach $path (@paths) {
    print "$site/$path\n";
}
