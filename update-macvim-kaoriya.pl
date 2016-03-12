#!/usr/bin/env perl
use v5.20;
use utf8;
use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Digest::SHA 'sha256_hex';
use LWP::UserAgent::ProgressBar;
use Path::Class;
use YAML;

sub fetch_url ($url, %opt) : prototype($;@) {
    say "download $url";
    my $response = LWP::UserAgent::ProgressBar->new->get_with_progress($url);
    $response->is_success or die "can't get url: $url";
    if ($opt{is_calc_hash}) {
        sha256_hex $response->content;
    } else {
        $response->content;
    }
}

sub release_version ($url) : prototype($) {
    if (fetch_url($url) =~ /Vim (\d\.\d)/) {
        $1;
    } else {
        die "can't detect vim version: $url";
    }
}

sub formula ($formula_path, $release_version, $release_date, $dmg_hash, $appcast_hash) : prototype($$$$$) {
    my $formula = file($formula_path)->slurp;
    $formula =~ s/else
    version '\d+\.\d+:\d+'
    sha256 '[\da-f]+'/else
    version '$release_version:$release_date'
    sha256 '$dmg_hash'/;
    $formula =~ s/(?<=checkpoint: ')[\da-f]+/$appcast_hash/;
    $formula;
}

sub main () {
    my $release_date = shift @ARGV;
    die "please specify reelase_date\n" unless $release_date;

    (my $conf_yaml = do { local $/; <DATA> }) =~ s/\$release_date/$release_date/g;
    my $conf = Load $conf_yaml;

    my $release_version = release_version $conf->{release_url};
    my $dmg_hash        = fetch_url $conf->{dmg_url},     is_calc_hash => 1;
    my $appcast_hash    = fetch_url $conf->{appcast_url}, is_calc_hash => 1;
    my $formula = formula $conf->{formula_path}, $release_version, $release_date, $dmg_hash, $appcast_hash;
    file($conf->{formula_path})->openw->print($formula);
}

main if __FILE__ eq $0;

__DATA__
---
formula_path: /usr/local/Library/Taps/caskroom/homebrew-versions/Casks/macvim-kaoriya.rb
dmg_url:      https://github.com/splhack/macvim-kaoriya/releases/download/$release_date/MacVim-KaoriYa-$release_date.dmg
release_url:  https://github.com/splhack/macvim-kaoriya/releases/tag/$release_date
appcast_url:  https://raw.githubusercontent.com/splhack/macvim-kaoriya/master/latest.xml
